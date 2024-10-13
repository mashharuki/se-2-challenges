// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this challenge. Also return variable names need to be specified exactly may be referenced (It may be helpful to cross reference with front-end code function calls).
 */
contract DEX {
	/* ========== GLOBAL VARIABLES ========== */

	IERC20 token; //instantiates the imported contract

	uint256 public totalLiquidity; // Total liquidity in the DEX

	uint256 public ethReserve; // Reserve of ETH
	uint256 public balloonsReserve; // Reserve of $BAL

	mapping(address => uint256) public liquidity; // Liquidity per user

	/* ========== EVENTS ========== */

	/**
	 * @notice Emitted when ethToToken() swap transacted
	 */
	event EthToTokenSwap(
		address swapper,
		uint256 tokenOutput,
		uint256 ethInput
	);

	/**
	 * @notice Emitted when tokenToEth() swap transacted
	 */
	event TokenToEthSwap(
		address swapper,
		uint256 tokensInput,
		uint256 ethOutput
	);

	/**
	 * @notice Emitted when liquidity provided to DEX and mints LPTs.
	 */
	event LiquidityProvided(
		address liquidityProvider,
		uint256 liquidityMinted,
		uint256 ethInput,
		uint256 tokensInput
	);

	/**
	 * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
	 */
	event LiquidityRemoved(
		address liquidityRemover,
		uint256 liquidityWithdrawn,
		uint256 tokensOutput,
		uint256 ethOutput
	);

	/* ========== CONSTRUCTOR ========== */

	constructor(address tokenAddr) {
		token = IERC20(tokenAddr); //specifies the token address that will hook into the interface and be used through the variable 'token'
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	/**
	 * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
	 * @param tokens amount to be transferred to DEX
	 * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
	 * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
	 */
	function init(uint256 tokens) public payable returns (uint256) {
		require(msg.value > 0, "ETH amount must be greater than 0");
		require(tokens > 0, "$BAL amount must be greater than 0");
		require(token.allowance(msg.sender, address(this)) >= tokens, "Check the token allowance");

		ethReserve = msg.value;
		balloonsReserve = tokens;

		totalLiquidity = ethReserve + balloonsReserve;

		// Transfer $BAL tokens to the DEX contract
		token.transferFrom(msg.sender, address(this), tokens);

		// Update user's liquidity
		liquidity[msg.sender] += totalLiquidity;

		return totalLiquidity;
	}

	/**
	 * @notice returns yOutput, or yDelta for xInput (or xDelta)
	 * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
	 */
	function price(
		uint256 xInput,
		uint256 xReserves,
		uint256 yReserves
	) public pure returns (uint256 yOutput) {
		require(xReserves > 0, "Input reserve must be greater than zero");
    require(yReserves > 0, "Output reserve must be greater than zero");

    // Calculate the amount of output considering a 0.3% fee
    uint256 xWithFee = (xInput * 997) / 1000; // 0.3% fee
    yOutput = (xWithFee * yReserves) / (xReserves + xWithFee);
	}

	/**
	 * @notice returns liquidity for a user.
	 * NOTE: this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
	 * NOTE: if you are using a mapping liquidity, then you can use `return liquidity[lp]` to get the liquidity for a user.
	 * NOTE: if you will be submitting the challenge make sure to implement this function as it is used in the tests.
	 */
	function getLiquidity(address lp) public view returns (uint256) {
		return liquidity[lp];
	}

	/**
	 * @notice sends Ether to DEX in exchange for $BAL
	 */
	function ethToToken() public payable returns (uint256 tokenOutput) {
		require(msg.value > 0, "ETH input must be greater than 0");
    
    uint256 ethWithFee = (msg.value * 997) / 1000; // 0.3% fee
    tokenOutput = (ethWithFee * balloonsReserve) / (ethReserve + ethWithFee);
    
    // Update reserves
    ethReserve += msg.value;
    balloonsReserve -= tokenOutput;

    // Transfer tokens to the user
    token.transfer(msg.sender, tokenOutput);
    
    emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
	}

	/**
	 * @notice sends $BAL tokens to DEX in exchange for Ether
	 */
	function tokenToEth(
		uint256 tokenInput
	) public returns (uint256 ethOutput) {
		require(tokenInput > 0, "$BAL input must be greater than 0");
    
    uint256 tokenWithFee = (tokenInput * 997) / 1000; // 0.3% fee
    ethOutput = (tokenWithFee * ethReserve) / (balloonsReserve + tokenWithFee);
    
    // Update reserves
    ethReserve -= ethOutput;
    balloonsReserve += tokenInput;

    // Transfer ETH to the user
		require(address(this).balance >= ethOutput, "Not enough ETH in DEX");
    payable(msg.sender).transfer(ethOutput);
		token.transferFrom(msg.sender, address(this), tokenInput); 

    emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
	}

	/**
	 * @notice allows deposits of $BAL and $ETH to liquidity pool
	 * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
	 * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
	 * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
	 */
	function deposit(uint256 balloonsAmount) public payable returns (uint256 tokensDeposited) {
		require(msg.value > 0, "ETH amount must be greater than 0");
    require(balloonsAmount > 0, "$BAL amount must be greater than 0");
    
    uint256 ethAmount = msg.value;
    uint256 balloonAmount;

    // Check for existing reserves to avoid division by zero
    if (ethReserve == 0) {
        balloonAmount = balloonsAmount; // No liquidity exists, allow any amount
    } else {
        balloonAmount = (ethAmount * balloonsReserve) / ethReserve; // Maintain ratio
    }

    require(balloonsAmount >= balloonAmount, "Insufficient $BAL tokens provided");

    // Update reserves
    ethReserve += ethAmount;
    balloonsReserve += balloonAmount;
    totalLiquidity += (ethAmount + balloonAmount) / 2;

    // Transfer tokens from user to contract
    token.transferFrom(msg.sender, address(this), balloonAmount);
    liquidity[msg.sender] += (ethAmount + balloonAmount) / 2; // Update user's liquidity

    // Emit event with correct values
    emit LiquidityProvided(msg.sender, ethAmount, msg.value, balloonAmount);
    return balloonAmount; 
	}

	/**
	 * @notice allows withdrawal of $BAL and $ETH from liquidity pool
	 * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
	 */
	function withdraw(
		uint256 amount
	) public returns (uint256 ethAmount, uint256 tokenAmount) {
		require(amount > 0, "Amount must be greater than 0");
    require(liquidity[msg.sender] >= amount, "Insufficient liquidity");

    ethAmount = (ethReserve * amount) / totalLiquidity; // Proportional withdrawal
    tokenAmount = (balloonsReserve * amount) / totalLiquidity; // Proportional withdrawal

		require(ethAmount <= ethReserve && tokenAmount <= balloonsReserve, "Not enough liquidity");

    ethReserve -= ethAmount;
    balloonsReserve -= tokenAmount;
    totalLiquidity -= amount;

    payable(msg.sender).transfer(ethAmount);
    token.transfer(msg.sender, amount);

		emit LiquidityRemoved(msg.sender, amount, amount, amount);

		return (ethAmount, tokenAmount);
	}

	receive() external payable {}

	fallback() external payable {}
}
