
import EVMRevert from '../helpers/EVMRevert';
const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const IronBankTokenMock = artifacts.require('IronBankTokenMock');

contract('IronBankToken', function (accounts) {
  const amount = web3.toWei(1.0, 'ether');
  const owner = accounts[0];
  const other = accounts[1];

  beforeEach(async function () {
    this.contract = await IronBankTokenMock.new(accounts[0], 1000);
  });

  it('should be token owner', async function () {
    const owner_ = await this.contract.owner();
    owner_.should.equal(accounts[0]);
  });

  it('should accept payments', async function () {
    await web3.eth.sendTransaction({ from: owner, to: this.contract.address, value: amount });

    const balance = web3.eth.getBalance(this.contract.address);
    balance.should.be.bignumber.equal(amount);
  });

  it('should log deposit', async function () {
    const { logs } = await this.contract.sendTransaction({ from: owner, to: this.contract.address, value: amount });

    const event = logs.find(e => e.event === 'Deposit');

    should.exist(event);
    event.args.amount.should.be.bignumber.equal(amount);
  });

  it('should throw an error when withdraw not owner', async function () {
    await web3.eth.sendTransaction({ from: owner, to: this.contract.address, value: amount });
    await this.contract.withdraw(accounts[1], { from: accounts[1] }).should.be.rejectedWith(EVMRevert);
  });

  it('should withdraw funds by owner to other', async function () {
    await web3.eth.sendTransaction({ from: owner, to: this.contract.address, value: amount });
    const balance = web3.eth.getBalance(this.contract.address);
    balance.should.be.bignumber.equal(amount);

    const pre = web3.eth.getBalance(other);
    await this.contract.withdraw(other, { from: owner });
    const post = web3.eth.getBalance(other);
    post.minus(pre).should.be.bignumber.equal(amount);

    const balance2 = web3.eth.getBalance(this.contract.address);
    balance2.should.be.bignumber.equal(0);
  });

  it('should log withdraw', async function () {
    await web3.eth.sendTransaction({ from: owner, to: this.contract.address, value: amount });
    const { logs } = await this.contract.withdraw(other, { from: owner });

    const event = logs.find(e => e.event === 'Withdraw');

    should.exist(event);
    event.args.beneficiary.should.equal(other);
    event.args.amount.should.be.bignumber.equal(amount);
  });
});
