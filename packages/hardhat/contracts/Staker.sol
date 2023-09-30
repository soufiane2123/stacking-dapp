// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	ExampleExternalContract public exampleExternalContract;

	mapping(address => uint256) public balances;

	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 30 seconds;
	uint256 startDeadline;

	bool openForWithdraw = false;

	event Stake(address, uint256);

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);

		startDeadline = block.timestamp;
	}

	modifier notCompleted() {
		exampleExternalContract.completed();

		_;
	}

	// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
	// (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

	function stake() public payable {
		require(msg.value > 0, "Amount must be greater than 0");
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	// After some `deadline` allow anyone to call an `execute()` function
	// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

	function execute() public notCompleted {
		require(startDeadline <= deadline, "Deadline not reached yet");
		uint256 balance = address(this).balance;
		if (balance >= threshold) {
			exampleExternalContract.complete{ value: address(this).balance }();
		} else {
			openForWithdraw = true;
			// withdraw();
		}
	}

	function withdraw() public payable notCompleted {
		uint256 balanceToWithdraw = balances[msg.sender];
		require(balanceToWithdraw > 0, "No balance to withdraw");
		// Reset the balance to prevent reentrancy issues.

		(bool success, ) = msg.sender.call{ value: balanceToWithdraw }("");
		require(success, "Transfer failed");

		balances[msg.sender] = 0;
	}

	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		} else {
			return deadline - block.timestamp;
		}
	}

	receive() external payable {
		stake();
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

	// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

	// Add the `receive()` special function that receives eth and calls stake()
}
