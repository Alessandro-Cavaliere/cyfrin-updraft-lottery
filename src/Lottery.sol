// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/// @title Lottery Contract from the Cyfrin-Updraft 2024 Course
/// @author Alessandro Cavaliere
/// @notice Example of a Lottery implemented in a Blockchain Environment
/// @dev The project is set-upped with Foundry Tools

contract Lottery is VRFConsumerBaseV2Plus {

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 2;
    uint256 private immutable i_entranceFee;
    /// @dev This variable stores the interval of the Lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionID;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;

    /// @notice This Event shows when a player enters the lottery
    /// @dev This event is emitted when a player enters the lottery
    /// @param player The address of the player that entered the lottery
    event LotteryEnter(address indexed player);

    error Lottery__intervalNotPassed();
    error Lottery__NotEnoughtETHToEnterlottery();

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionID,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_interval = interval;
        i_entranceFee = entranceFee;
        i_keyHash = gasLane;
        i_subscriptionID = subscriptionID;
        s_lastTimestamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    /// @notice this function allows a player to enter the lottery
    /// @dev This function allows a player to enter the lottery by paying the entrance fee
    function enterLottery() external {
        require(msg.value >= i_entranceFee, Lottery__NotEnoughtETHToEnterlottery());
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    /// @notice This function allows a player to pick the winner of the lottery
    /// @dev This function is called to select the winner of the lottery. 
    /// It checks if the interval has passed since the last selection and then requests random words from the Chainlink VRF (Verifiable Random Function) service.
    /// The random words are used to determine the winner.
    function pickWinner() external {
        require(block.timestamp - s_lastTimestamp >= i_interval, Lottery__intervalNotPassed());

        // Request random words from Chainlink VRF
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionID,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );

        s_lastTimestamp = block.timestamp;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        
    };

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
