pragma solidity ^0.4.23;
/* 23/7/2018 being modified */
// Donation Contract is coded using Solidity, to send donation amount to reciever.
// A contract owner can raise contributions as ether from public,
// and then he can send reciver total amount for donation.
// Notes: this contract is not fixed, so you should not use this contract in Ethereum mainnet.
contract Donation {
/* grobal variable */
    address public toDonAddr;   //address to receive donation
    address owner; //contract owner(initial deploy)
    uint public collectAmount;  //total amount for donation
    uint public deadline;       //deadline for donation
    Donar[] public donars;      //donars information(array list)
    struct Donar {
        address addr;
        uint amount;
    }
/* private variable */
    uint8 private flg_sendFix = 0;  //initial value:0, finish to send amount:1
    uint8 private flg_sendCancel = 0; //initial value:0, finish to cancel:1
/* events` */
    //send
    event sendCoin(address sender,address receiver, uint amount);
    //cancel
    event cancelDonation(address sender, address receiver, uint amount, uint8 flg);
/* functions */
    //initialize
    constructor (address _toDonAddr,uint _duration) public {
        toDonAddr = _toDonAddr;
        owner = msg.sender;
        deadline = block.timestamp + _duration * 1 minutes;
    }
    //if you use this modifier, only contract owner can execute.
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    //if you use this modifier, we can send amount to this contract before deadline.
    modifier before_deadline {
        require(block.timestamp < deadline);
        _;
    }
    //if you use this modifier, we can transfer amount to receiver after deadline.
    modifier after_deadline {
        require(block.timestamp >= deadline);
        _;
    }
    //anonymous function
    //if you send amounts to this contract, the anoymous function is always called. 
    function () public payable before_deadline{
        //receiver address cannot send this contract amount.
        require(msg.sender != toDonAddr);
        //we can send amount before deadline.
        require(block.timestamp < deadline);
        uint amount = msg.value;
        //add array list for donar information
        donars[donars.length++] = Donar({addr: msg.sender, amount:amount});
        collectAmount += amount;
    }
    //function to send (valid after deadline )
    function SendCoin() public onlyOwner after_deadline returns(bool _trueorfalse, uint8 _flg_sendFix) {
        //confirm if not canceled.
        require (flg_sendCancel == 0);
        //confirm total amount is greater than zero.
        require (collectAmount > 0);
        toDonAddr.transfer(collectAmount);
        flg_sendFix = 1;
        //event ignition to send transaction
        emit sendCoin(this,toDonAddr, collectAmount);
        return (true, flg_sendFix);
    }
    //function to cancel
    function CancelDonation() public onlyOwner returns(bool _trueorfalse){
        //confirm if not sent.
        require (flg_sendFix == 0);
        //refund donars amount.
        for (uint i = 0; i < donars.length; ++i){
            donars[i].addr.transfer(donars[i].amount);
        }
        flg_sendCancel = 1;
        //event ignition to cancel transaction
        emit cancelDonation(this,toDonAddr, collectAmount,flg_sendCancel);
        return true;
    }
/* function to get information */
    //get contract owner
    function getOwner() public view returns (address) {
        return owner;
    }
    //get current total amount
    function getCollectAmount() public view returns (uint) {
        return collectAmount;
    }
    //get current block.timestamp
    function getBlockTimestamp() public view returns(uint) {
        return block.timestamp;
    }
}