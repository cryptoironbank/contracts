pragma solidity ^0.4.18;


import "zeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";



/**
 * @title BackedToken
 * @dev ERC827 ETH-backed token with rate set
 */
contract BackedToken is ERC827Token, BurnableToken, Ownable {

  uint256 public rate;
  uint256 public rateSetTime;
  address rateOwner;

  uint256 public drawTime;
  uint256 public drawBudget;

  uint256 public constant FEE_CAP = 5 ether;
  uint256 public constant MIN_SALE = 1 ether;
  uint256 public constant MINT_TIME = 4 hours;
  uint256 public constant DRAW_PERIOD = 24 hours;

  event Mint(address indexed to, uint256 amount);
  event MintOwner(address indexed beneficiary, uint256 tokens, uint256 rate);
  event RateOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event RateSet(uint256 newRate);
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenSale(address indexed seller, address indexed beneficiary, uint256 netValue, uint256 fee, uint256 amount);

  modifier haveRate() {
    require(rate != 0);
    _;
  }

  modifier onlyRateOwner() {
    require(msg.sender == rateOwner);
    _;
  }

  function BackedToken() public {
    rateOwner = msg.sender;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable haveRate {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

  function donate() public payable {
  }

  function getBackableAmount() public view returns(uint256) {
    return getTokenAmount(this.balance);
  }

  function getMintable() public view returns(uint256) {
    uint256 backable = getBackableAmount();
    if (totalSupply_ < backable)
      return backable.sub(totalSupply_);
    
    return 0;
  }

  function mintOwner(address beneficiary, uint256 tokens) public onlyOwner returns (bool) {
    require(beneficiary != address(0));
    require(rateSetTime.add(MINT_TIME) < block.timestamp);
    require(tokens != 0);
    require(tokens <= getMintable());

    // update state
    mint(beneficiary, tokens);
    MintOwner(beneficiary, tokens, rate);
    return true;
  }

  function sellAll() public haveRate {
    sellTokens(msg.sender, balances[msg.sender]);
  }

  // low level token sale function
  function sellTokens(address beneficiary, uint256 tokens) public haveRate {
    require(beneficiary != address(0));
    require(tokens != 0);
    require(tokens <= balances[msg.sender]);

    // fee and wei amount to be returned
    uint256 grossAmount = tokens.div(rate);
    uint256 weiFee = getSaleFee(grossAmount);
    uint256 netAmount = grossAmount.sub(weiFee);

    // minimum sell size
    require(grossAmount >= MIN_SALE);

    // 25% daily reserve draw limit
    uint256 budget = drawBudget;
    uint256 balance = this.balance;
    bool doReset = doResetDraw();

    if (doReset)
      budget = balance.div(4); // 25% of total balance

    require(netAmount <= balance);
    require(netAmount <= budget);

    // update state
    if (doReset)
      drawTime = block.timestamp;
    drawBudget = budget.sub(netAmount);

    burn(tokens);

    beneficiary.transfer(netAmount);

    TokenSale(msg.sender, beneficiary, netAmount, weiFee, tokens);
  }

  function setRate(uint256 newRate) public onlyRateOwner {
    // update state
    rate = newRate;
    rateSetTime = block.timestamp;
    RateSet(newRate);
  }

  function transferRateOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));

    address oldOwner = rateOwner;
    rateOwner = newOwner;
    RateOwnershipTransferred(oldOwner, newOwner);
  }

  function getSaleFee(uint256 weiAmount) internal pure returns(uint256) {
    assert(weiAmount != 0);

    // capped 1% fee
    uint256 weiFee = weiAmount.div(100);
    if (weiFee > FEE_CAP)
            weiFee = FEE_CAP;

    return weiFee;
  }

  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  function doResetDraw() internal view returns (bool) {
    return (drawTime.add(DRAW_PERIOD) < block.timestamp);
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase;
  }

}

