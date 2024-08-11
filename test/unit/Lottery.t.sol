// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";
import {LotteryScript} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

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
        console2.log("DeployLottery.s.sol:  vm.deal(player, STARTING_PLAYER_BALANCE) -> Fake User Funded! Balance: ",player.balance);
        // account = config.account;
    }

    /*//////////////////////////////////////////////////////////////
                             START OF TESTS
    //////////////////////////////////////////////////////////////*/

                            //----------------//

    /*//////////////////////////////////////////////////////////////
                             ENTER LOTTERY TESTS
    //////////////////////////////////////////////////////////////*/
    function testLotteryInitializedOpenState() public {
        require(lottery.getLotteryState() == Lottery.LotteryState.OPEN, LotteryTest__NotOpenLottery());
    }
    function testETHBalanceToEnterLottery () public{
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
        vm.expectEmit(true,false,false,false,address(lottery));
        emit LotteryEnter(player);

        lottery.enterLottery{value: lotteryEntranceFee}();
    }

    function testDontAllowUserToEnterTheLotteryDuringCalculation() public {
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();

        vm.warp(block.timestamp + automationUpdateInterval +1);
        vm.roll(block.number + 1);

        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery__NotOpenLottery.selector);
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                             CHECK UPKEEPS
    //////////////////////////////////////////////////////////////*/
    function testCheckUpkeepIfItHasNoBalance() public {
        vm.warp(block.timestamp + automationUpdateInterval +1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepIfIntervalNotPassed() public {
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();

        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepIfIsThereNoPlayers() public {
        address payable[] memory players = lottery.getPlayers();
        assertEq(players.length, 0, "Players array should be empty");
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assertFalse(upkeepNeeded, "Upkeep should not be needed when players array is empty");
    }

    function testCheckUpkeepIfLotteryIsClosed() public {
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();

        vm.warp(block.timestamp + automationUpdateInterval +1);
        vm.roll(block.number + 1);

        lottery.performUpkeep("");
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEPS
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(player);
        lottery.enterLottery{value: lotteryEntranceFee}();

        vm.warp(block.timestamp + automationUpdateInterval +1);
        vm.roll(block.number + 1);

        lottery.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;

        Lottery.LotteryState lotteryState = lottery.getLotteryState();
        vm.expectRevert(
            abi.encodeWithSelector(Lottery.Lottery__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );

        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        vm.prank(player);
        lottery.enterLottery{value: LotteryEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // requestId = raffle.getLastRequestId();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1); // 0 = open, 1 = calculating
    }

}
