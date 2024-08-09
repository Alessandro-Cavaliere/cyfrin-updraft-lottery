// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Lottery Contract from the Cyfrin-Updraft 2024 Course
/// @author Alessandro Cavaliere
/// @notice Example of a Lottery implemented in a Blockchain Environment
/// @dev The project is set-upped with Foundry Tools  
contract Lottery {
    uint256 private immutable i_entranceFee;
    /// @dev This variable stores the interval of the Lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;

    /// @notice This Event shows when a player enters the lottery
    /// @dev This event is emitted when a player enters the lottery
    /// @param player The address of the player that entered the lottery
    event LotteryEnter(address indexed player);

    error Lottery__intervalNotPassed();   
    error Lottery__NotEnoughtETHToEnterlottery();

    constructor (unit256 entranceFee, uint256 interval) public {
        i_entranceFee = entranceFee;
        s_lastTimestamp = block.timestamp;

    }

    /// @notice this function allows a player to enter the lottery
    /// @dev This function allows a player to enter the lottery by paying the entrance fee
    /// @param none
    /// @return none
    function enterLottery () external{
        require(msg.value >= i_entranceFee, Lottery__NotEnoughtETHToEnterlottery());
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    function pickWinner() external{
        require(block.timestamp - s_lastTimestamp > i_interval, Lottery__intervalNotPassed());
        

        s_lastTimestamp = block.timestamp;
    }

    function getEntranceFee() view public returns (uint256) {
        return i_entranceFee;
    }

}