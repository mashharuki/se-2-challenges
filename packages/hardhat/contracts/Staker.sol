// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 60 seconds;

  bool public executed;

  // Events
  event Stake(address indexed staker, uint256 amount);
  event Executed(uint256 totalAmount);
  event Withdraw(address indexed withdrawer, uint256 amount);

  // Modifier to check if the deadline has passed
  modifier onlyBeforeDeadline() {
    require(timeLeft() > 0, "Deadline has passed");
    _;
  }

  // Modifier to check if the deadline has passed
  modifier onlyAfterDeadline() {
    require(timeLeft() == 0, "Deadline has not passed yet");
    _;
  }

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    executed = false;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable onlyBeforeDeadline {
    require(msg.value > 0, "Must stake some ether");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public onlyAfterDeadline {
    require(address(this).balance >= threshold, "Threshold not met");
    require(!executed, "Already executed");

    executed = true;
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: contractBalance}();
    emit Executed(contractBalance);
  }


  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public onlyAfterDeadline {
    require(address(this).balance < threshold, "Threshold met, cannot withdraw");
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "No balance to withdraw");

    balances[msg.sender] = 0; // Reset balance before transferring to prevent re-entrancy attacks
    payable(msg.sender).transfer(userBalance);
    emit Withdraw(msg.sender, userBalance);
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}
