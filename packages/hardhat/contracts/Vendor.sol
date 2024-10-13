pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable{

  uint256 public constant tokensPerEth = 100;

  YourToken public yourToken;

  // Events
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);


  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  function buyTokens() public payable {
    require(msg.value > 0, "Send ETH to buy tokens");

    uint256 amountToBuy = msg.value * tokensPerEth;

    // Check if the Vendor contract has enough tokens
    uint256 vendorBalance = yourToken.balanceOf(address(this));
    require(vendorBalance >= amountToBuy, "Vendor does not have enough tokens");

    // Transfer tokens to the buyer
    yourToken.transfer(msg.sender, amountToBuy);

    // Emit the event for token purchase
    emit BuyTokens(msg.sender, msg.value, amountToBuy);
  }

  function withdraw() public onlyOwner {
    uint256 contractBalance = address(this).balance;
    require(contractBalance > 0, "No ETH to withdraw");

    // Transfer the balance to the contract owner
    payable(owner()).transfer(contractBalance);
  }


   function sellTokens(uint256 _amount) public {
      require(_amount > 0, "Specify an amount of tokens to sell");

      // Check the seller's token balance
      uint256 sellerBalance = yourToken.balanceOf(msg.sender);
      require(sellerBalance >= _amount, "You do not have enough tokens to sell");

      // Calculate the amount of ETH to send to the seller
      uint256 amountOfETH = _amount / tokensPerEth;
      require(address(this).balance >= amountOfETH, "Vendor does not have enough ETH");

      // Transfer tokens from the seller to the vendor contract
      yourToken.transferFrom(msg.sender, address(this), _amount);

      // Send ETH to the seller
      payable(msg.sender).transfer(amountOfETH);

      // Emit the event for token sale
      emit SellTokens(msg.sender, _amount, amountOfETH);
  }
}
