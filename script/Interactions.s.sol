// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


abstract contract HelperConfigValues {
    HelperConfig internal helperConfig;
    
    constructor() {
        helperConfig = new HelperConfig();
    }
    
    function getHelperConfigValues() public returns (address, uint256) {
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subID = helperConfig.getConfig().subscriptionId;
        return (vrfCoordinator, subID);
    }
}

contract CreateSubscription is Script, HelperConfigValues {
    
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        (address vrfCoordinator,) = getHelperConfigValues();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console2.log("Interaction.s.sol: createSubscription() -> Creating Subscription on chain ID:", block.chainid);
        console2.log("Interaction.s.sol: Using vrfCoordinator: ", vrfCoordinator);
        vm.startBroadcast();
        uint256 subID = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Interaction.s.sol: createSubscription() -> SubscriptionID Created! ->", subID);
        return (subID, vrfCoordinator);
    }

    function run() external {
        createSubscriptionUsingConfig();
    }
}

/*//////////////////////////////////////////////////////////////
                       FUNDSUBSCRIPTIONS
//////////////////////////////////////////////////////////////*/
contract FundSubscription is Script, CodeConstants, HelperConfigValues {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        (address vrfCoordinator, uint256 subID) = getHelperConfigValues();
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subID, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subID, address linkToken) public {
        console2.log("Interaction.s.sol: fundSubscription() -> Funding Subscription on chain ID:", block.chainid);
        console2.log("vrCoordinator:", vrfCoordinator);

        if (block.chainid == LOCAL_CHAIN_ID) {
            console2.log("Interaction.s.sol: Funding Subscription on LOCAL CHAIN!");
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subID, FUND_AMOUNT *100);
            vm.stopBroadcast();
            console2.log("Interaction.s.sol: Subscription Funded!");
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT * 100, abi.encode(subID));
            vm.stopBroadcast();
        }
    }
    
    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script, HelperConfigValues {

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        (address vrfCoordinator, uint256 subID) = getHelperConfigValues();
        addConsumer(mostRecentlyDeployed,vrfCoordinator, subID);
    }

    function addConsumer(address contractToVrf,address vrfCoordinator,uint256 subID) public {
        console2.log("Interactions.s.sol: Adding Consumer to VRF Coordinator:");
        console2.log("Contract to VRF Coordinator:", contractToVrf);
        console2.log("SubID:", subID);
        console2.log("Chain ID:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subID,contractToVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Lottery", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
