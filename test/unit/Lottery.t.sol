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
        vm.deal(player, STARTING_PLAYER_BALANCE);
        console2.log("player", player.balance);
        // link = config.link;
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

}
