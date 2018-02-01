pragma solidity ^0.4.13;


import "./IronBankToken.sol";


// mock class using Iron Bank Token
contract IronBankTokenMock is IronBankToken {

  function IronBankTokenMock(address initialAccount, uint256 initialBalance) public {
    balances[initialAccount] = initialBalance;
    totalSupply_ = initialBalance;
  }

}
