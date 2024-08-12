# Cyfrin Updraft Lottery
This is the Cyfrin Updraft Lottery project for practice in the course updated to 2024! This repository contains the code and documentation for a lottery system using Solidity and the Sepolia Test Network of the Ethereum Blockchain.

## Table of Contents

- [Cyfrin Updraft Lottery](#cyfrin-updraft-lottery)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Features](#features)
  - [Usage](#usage)
  - [Project Initialization and Contract Deployment](#project-initialization-and-contract-deployment)
  - [Contract Deployment](#contract-deployment)
  - [Conclusion](#conclusion)

## Introduction

The Cyfrin Updraft Lottery is a project that focuses on writing a Solidity smart contract for a lottery system. It is designed to provide practice in developing smart contracts using Solidity and the Sepolia Test Network of the Ethereum Blockchain. The project aims to enhance participants' understanding of smart contract development and lottery systems.

## Features

- User registration and authentication with "ticket" purchasing and management;
- Random number generation for lottery draws using Chainlink Automation and VRF Chainlink Coordinator;
- Prize distribution and winner announcement.

## Usage

To use the Cyfrin Updraft Lottery contract, you have two options:

1. Remix: You can use Remix, an online Solidity IDE, to deploy and interact with the contract. Simply copy the contract code into Remix, compile it, and deploy it on the Sepolia Test Network. From there, you can use Remix's interface to interact with the contract and perform actions such as purchasing tickets and announcing winners.

2. Foundry Testing: Another option is to use Foundry, a testing framework for Solidity contracts. With Foundry, you can write test cases to simulate different scenarios and ensure the contract functions as expected. By running the tests, you can verify the functionality of the contract and identify any potential issues.

## Project Initialization and Contract Deployment

To initialize the project and deploy the contract, follow these steps:

1. Clone the repository using the command `git clone https://github.com/Alessandro-Cavaliere/cyfrin-updraft-lottery.git`.
2. Install the necessary dependencies by running `make install`.
3. If you want to deploy locally, launch Anvil by running the command `anvil`. Make sure you have already installed everything with `foundryup` and run `make deploy` using the provided Makefile.
4. If you want to deploy on Sepolia or other chains, run `make deploy ARGS="--network sepolia"`.

This is the Cyfrin Updraft Lottery project for practice in the **Cyfrin Updraft Course** updated to 2024! This repository contains the code and documentation for a lottery system using Solidity on the Ethereum Blockchain.

## Contract Deployment

The Cyfrin Updraft Lottery contract has been deployed on the Sepolia Test Network of the Ethereum Blockchain. You can find the deployed contract at the following link: [Lottery Contract](https://sepolia.etherscan.io/address/0xb8588c6067f9a83872b7d76a1e7596cf5b60fbe4#code).

## Conclusion

Please note that the Cyfrin Updraft Lottery contract is not fully automated. In order to make it work properly and enable random number generation for lottery draws, you need to follow a few additional steps on the Chainlink website. Specifically, you will need to configure and set up the **Chainlink Automation service** by visiting [ChainLink Website](https://automation.chain.link/). Once you have completed the necessary setup (creation of the Upkeep and the relative fund of it), you will be able to fully utilize the contract's functionality on Etherscan after the deploy with your **Etherscan API Key**.

If you need further details or have any questions, please feel free to contact me. I'll be happy to provide you with additional information or clarification.

