// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Lottery} from "../src/Lottery.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract LotteryScript is Script {
    function run()  external returns (Lottery, HelperConfig) {
        return deployLottery();
    }

    function deployLottery() public returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0) {
            console2.log("Creating a new subscription ID");
            CreateSubscription subscriptionContract = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) = subscriptionContract.createSubscription(config.vrfCoordinatorV2_5);
        }
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
