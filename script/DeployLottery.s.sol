// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Lottery} from "../src/Lottery.sol";
contract LotteryScript is Script {
    function run()  external returns (Lottery, HelperConfig) {
        return deployLottery();
    }

    function deployLottery() public returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Lottery lottery = new Lottery(
            config.lotteryEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (lottery, helperConfig);
    }
}
