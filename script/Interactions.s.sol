// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
contract CreateSubscription is Script {
    
    function CreateSubscriptionUsingConfig() public returns(uint256,address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        (uint256 subID,) = createSubscription(vrfCoordinator);
        return (subID,vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint256,address) {
        console2.log("Creating Subscription on chain ID:", block.chainid);
        vm.broadcast();
        uint256 subID= VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Your subID:", subID);
        return (subID,vrfCoordinator);
    }

    function run() external {
        CreateSubscriptionUsingConfig();
    }
}

/*//////////////////////////////////////////////////////////////
                       FUNDSUBSCRIPTIONS
//////////////////////////////////////////////////////////////*/
contract FundSubscription is Script{
    
    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subID = helperConfig.getConfig().subscriptionId;

    }

    function fundSubscription(uint256 subID) public returns(uint256,address) {
        
    }

    
    function run() public{

    }


}