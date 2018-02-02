pragma solidity ^0.4.18;


import "zeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";



/**
 * @title IronBankToken
 * @dev ERC827 burnable token
 */
contract IronBankToken is ERC827Token, BurnableToken, Ownable {

  event Deposit(uint256 amount);
  event Withdraw(address beneficiary, uint256 amount);

  function () external payable {
    if (msg.value > 0)
      Deposit(msg.value);
  }

  function withdraw(address beneficiary) public onlyOwner {
    require(this.balance != 0);

    uint256 balance = this.balance;
    beneficiary.transfer(balance);
    Withdraw(beneficiary, balance);
  }

}

