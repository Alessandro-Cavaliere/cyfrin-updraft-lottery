// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Lottery} from "../src/Lottery.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "./Interactions.s.sol";

contract LotteryScript is Script {
    function run()  external returns (Lottery, HelperConfig) {
        return deployLottery();
    }

    /// @notice Deploy a new Lottery Smart Contract
    /// @dev This function deploys a new Lottery Smart Contract and also create a new subscription ID and fund the subscription for local testing
    /// @return Lottery - The deployed Lottery Smart Contract and HelperConfig - The HelperConfig contract
    function deployLottery() public returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0) {
            console2.log("DeployLottery.s.sol: config.subscriptionId is = 0 -> We need to create a new subscription ID");
            CreateSubscription subscriptionContract = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) = subscriptionContract.createSubscription(config.vrfCoordinatorV2_5, config.account);
            FundSubscription fundSubscriptionContract = new FundSubscription();
            fundSubscriptionContract.fundSubscription(config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account);
           
        }
        console2.log("DeployLottery.s.sol: Deploying Lottery Smart Contract...");
        vm.startBroadcast(config.account);
        Lottery lottery = new Lottery(
            config.lotteryEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        console2.log("DeployLottery.s.sol: Lottery Smart Contract has been deployed!! -> Address: ",address(lottery));
        AddConsumer consumerContract = new AddConsumer();
        consumerContract.addConsumer(address(lottery), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);
        return (lottery, helperConfig);
    }
}
