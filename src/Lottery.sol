// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// Chainlink VRF is a decentralized oracle service that provides verifiable randomness to smart contracts. 
/// When a contract requests random numbers, Chainlink VRF generates them off-chain and then returns them to the contract
/// via a callback function like fulfillRandomWords.
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";

/// @title Lottery Contract from the Cyfrin-Updraft 2024 Course
/// @author Alessandro Cavaliere
/// @notice Example of a Lottery implemented in a Blockchain Environment
/// @dev The project is set-upped with Foundry Tools
contract Lottery is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {

    /* Type Declarations */
    enum LotteryState {
        OPEN,
        CALCULATING_WINNER
    }
    
    /* State Variables */
    /// @dev constant variables used in the contract
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 2;
    uint256 private immutable i_entranceFee;

    /// @dev This variable stores the interval of the Lottery in seconds
    uint256 private immutable i_interval;
    LotteryState private s_lotteryState;
    ///

    /// @dev These variables are used to store the specific values used by the Chainlink VRF service
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionID;
    uint32 private immutable i_callbackGasLimit;
    ///

    /// @dev s_players is an array of addresses that stores the players that entered the lottery and s_lastTimestamp stores the last time the lottery was picked.
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    ///

    /* Events */
    /// @notice This Event shows when a player enters the lottery
    /// @dev This event is emitted when a player enters the lottery
    /// @param player The address of the player that entered the lottery
    event LotteryEnter(address indexed player);

    /// @notice This Event shows when a player wins the lottery
    /// @dev This event is emitted when a player wins the lottery
    /// @param player The address of the player that won the lottery
    event WeHaveAWinner(address indexed player);

    /// @notice This event is emitted when a request for a lottery winner is made
    /// @dev This event is emitted when the contract requests random words from the Chainlink VRF service to determine the winner of the lottery
    /// @param requestId The ID of the randomness request generated when `requestRandomWords` was called
    event RequestedLotteryWinner(uint256 indexed requestId);

    /* Errors */
    error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);
    error Lottery__IntervalNotPassed();
    error Lottery__NotEnoughtETHToEnterlottery();
    error Lottery__TransferFailed();
    error Lottery__NotOpenLottery();

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
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimestamp = block.timestamp;
        s_lotteryState = LotteryState.OPEN;
    }

    /// @notice this function allows a player to enter the lottery
    /// @dev This function allows a player to enter the lottery by paying the entrance fee
    function enterLottery() public payable{
        require(msg.value >= i_entranceFee, Lottery__NotEnoughtETHToEnterlottery());
        require(s_lotteryState == LotteryState.OPEN, Lottery__NotOpenLottery());
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    /// @notice This function allows a player to pick the winner of the lottery
    /// @dev This function is called to select the winner of the lottery. 
    /// It checks if the interval has passed since the last selection and then requests random words from the Chainlink VRF (Verifiable Random Function) service.
    /// The random words are used to determine the winner.
    function pickWinner() internal {
        (bool upkeepNeeded,) = checkUpkeep("");
        require(upkeepNeeded,Lottery__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_lotteryState)));
        s_lotteryState = LotteryState.CALCULATING_WINNER;
        // Request random words from Chainlink VRF
        s_vrfCoordinator.requestRandomWords(
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
        emit RequestedLotteryWinner();
    }

    /// @notice Determines the winner of the lottery using a random number provided by Chainlink VRF.
    /// @dev This function is called by the Chainlink VRF service to determine the winner of the lottery.
    /// requestId The ID of the randomness request generated when `requestRandomWords` was called.
    /// @param randomWords An array of random numbers generated by the VRF service. The first element in this array is used to select the winner.
    /// This function does not return any value but updates the state of the contract by selecting a winner, 
    /// resetting the lottery state, and transferring the prize.
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastTimestamp = block.timestamp;
        emit WeHaveAWinner(recentWinner);
        
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        require(success, Lottery__TransferFailed());
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool timePassed = ((block.timestamp - s_lastTimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded,"");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        pickWinner();
    }

    /* Getters */

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getKeyHash() public view returns (bytes32) {
        return i_keyHash;
    }

    function getSubscriptionID() public view returns (uint256) {
        return i_subscriptionID;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return i_callbackGasLimit;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getSinglePlayer(uint256 index) public view returns (address payable) {
        return s_players[index];
    }
    function getPlayers() public view returns (address payable[] memory) {
        return s_players;
    }

    function getLastTimestamp() public view returns (uint256) {
        return s_lastTimestamp;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
