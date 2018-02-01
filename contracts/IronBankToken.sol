pragma solidity ^0.4.18;


import "zeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";



/**
 * @title IronBankToken
 * @dev ERC827 burnable token
 */
contract IronBankToken is ERC827Token, BurnableToken {

  function IronBankToken() public {
  }

}

