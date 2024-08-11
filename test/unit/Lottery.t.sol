// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";
import {LotteryScript} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    HelperConfig public helperConfig;

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
        // link = config.link;
        // account = config.account;
    }

    function testLotteryInitializedOpenState() public {
        require(lottery.getLotteryState() == Lottery.LotteryState.OPEN, LotteryTest__NotOpenLottery());
    }
}
