pragma solidity ^0.4.18;


import "./IronBankToken.sol";



/**
 * @title IronBankPrime
 * @dev ERC827 Token, where all tokens are pre-assigned to the creator.
 */
contract IronBankPrime is IronBankToken {

  string public constant name = "Iron Bank prime"; // solium-disable-line uppercase
  string public constant symbol = "IRON"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function IronBankPrime() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

}
