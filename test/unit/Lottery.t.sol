// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Lottery} from "../../src/Lottery.sol";
import {LotteryScript} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    HelperConfig public helperConfig;

    event LotteryEnter(address indexed player);

    address public player = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 lotteryEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;
    address link;
    address account;

    error LotteryTest__NotOpenLottery();

    modifier lotteryEntered() {
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() public {
        LotteryScript deployer = new LotteryScript();
        (lottery, helperConfig) = deployer.deployLottery();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        automationUpdateInterval = config.automationUpdateInterval;
        lotteryEntranceFee = config.lotteryEntranceFee;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        link = config.link;
        vm.deal(player, STARTING_PLAYER_BALANCE);
        console2.log("DeployLottery.s.sol:  vm.deal(player, STARTING_PLAYER_BALANCE) -> Fake User Funded! Balance: ", player.balance);
    }

    /*//////////////////////////////////////////////////////////////
                             START OF TESTS
    //////////////////////////////////////////////////////////////*/

    function testLotteryInitializedOpenState() public view {
        if (lottery.getLotteryState() != Lottery.LotteryState.OPEN) {
            revert LotteryTest__NotOpenLottery();
        }
    }

    function testETHBalanceToEnterLottery() public {
        testLotteryInitializedOpenState();
        vm.prank(player);
        vm.expectRevert(Lottery.Lottery__NotEnoughtETHToEnterlottery.selector);
        lottery.enterLottery();
    }

    function testPlayerEntersLottery() public {
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();
        address testPlayerRecorded = lottery.getSinglePlayer(0);
        assert(testPlayerRecorded == player);
    }

    function testEventIsEmitted() public {
        vm.prank(player);
        vm.expectEmit(true, false, false, false, address(lottery));
        emit LotteryEnter(player);

        lottery.enterLottery{value: lotteryEntranceFee}();
    }

    function testDontAllowUserToEnterTheLotteryDuringCalculation() public lotteryEntered {
        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery__NotOpenLottery.selector);
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                             CHECK UPKEEPS
    //////////////////////////////////////////////////////////////*/

    function testCheckUpkeepIfItHasNoBalance() public {
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepIfIntervalNotPassed() public{
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();

        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepIfIsThereNoPlayers() public{
        address payable[] memory players = lottery.getPlayers();
        assertEq(players.length, 0, "Players array should be empty");
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assertFalse(upkeepNeeded, "Upkeep should not be needed when players array is empty");
    }

    function testCheckUpkeepIfLotteryIsClosed() public lotteryEntered {
        lottery.performUpkeep("");
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEPS
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public lotteryEntered {
        lottery.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;

        Lottery.LotteryState lotteryState = lottery.getLotteryState();
        vm.expectRevert(
            abi.encodeWithSelector(Lottery.Lottery__UpkeepNotNeeded.selector, currentBalance, numPlayers, lotteryState)
        );

        lottery.performUpkeep("");
    }

    function testPerformUpkeepUpdateslotteryStateAndEmitsRequestId() public lotteryEntered {
        vm.recordLogs();
        lottery.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Lottery.LotteryState lotteryState = lottery.getLotteryState();
        assert(uint256(requestId) > 0);
        assert(uint256(lotteryState) == 1); // 0 = open, 1 = calculating
    }
    
    // This test will run 100 times due to the settings in `foundry.toml` file
     function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestID) public lotteryEntered skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(randomRequestID, address(lottery));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public lotteryEntered skipFork {
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);
        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address cuurentPlayer = address(uint160(i)); //This code will convert the uint to an address
            hoax(cuurentPlayer, 1 ether); 
            lottery.enterLottery{value: lotteryEntranceFee}();
        }

        uint256 startingtimestamp = lottery.getLastTimestamp();
        uint256 expectedWinnerBalance = expectedWinner.balance;

        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console2.logBytes32(entries[1].topics[1]);
        bytes32 requestId = entries[1].topics[1]; 

        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(uint256(requestId), address(lottery));

        address recentWinner = lottery.getRecentWinner();
        Lottery.LotteryState lotteryState = lottery.getLotteryState();
        console2.log("Recent Winner Balance Post WIN: ", recentWinner.balance);
        uint256 endingTimestamp = lottery.getLastTimestamp();
        uint256 prize = lotteryEntranceFee * (additionalEntrants + 1);
    
        assert(recentWinner == expectedWinner && 
                expectedWinnerBalance + prize == recentWinner.balance && 
                uint256(lotteryState) == 0 && 
                startingtimestamp < endingTimestamp
        );

    }

}