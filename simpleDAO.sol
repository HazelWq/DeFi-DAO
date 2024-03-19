// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
/// @title Simple DAO smart contract.

import "./trader.sol";

contract simpleDAO {
    // address of trader contract
    address payable public traderAddress;
    
    uint public voteEndTime;
    
    // balance of ether in the smart contract
    uint public DAObalance;
    
    // allow withdrawals
    mapping(address=>uint) balances;
    
    // proposal decision of voters 
    uint public decision;

    // default set as false 
    // makes sure votes are counted before ending vote
    bool public ended;
    
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    // address of the person who set up the vote 
    address public chairperson;

    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    //error handlers

    /// The vote has already ended.
    error voteAlreadyEnded();
    /// The auction has not ended yet.
    error voteNotYetEnded();


    // Sample input string: ["buy_bitcoins", "not_buy_bitcoins"]
    // First item in string is the one that will execute the purchase 
    // traderAddress is the address where the ether will be sent
    constructor(
        address payable _traderAddress,
        uint _voteTime,
        string[] memory proposalNames
    ) {

        traderAddress = _traderAddress;
        chairperson = msg.sender;
        
        voteEndTime = block.timestamp + _voteTime;

        for (uint i = 0; i < proposalNames.length; i++) {

            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }


    // anyone can deposit ether to the DAO smart contract
    function DepositEth() public payable {
        DAObalance = address(this).balance;
        
        if (block.timestamp > voteEndTime) {
            revert voteAlreadyEnded();
        }
        // require(DAObalance <= 1 ether, "1 Ether balance has been reached");
        
        balances[msg.sender] += msg.value;
    }


    // proposals are in format 0,1,2,...
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += 1;
    }


    // winningProposal must be executed before EndVote
    function countVote() public returns (uint winningProposal_) {
        require(block.timestamp > voteEndTime, "Vote not yet ended.");
        
        uint winningVoteCount = 0;

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
                
                decision = winningProposal_;
                ended = true;
            }
        }
    }


   // Individuals can only withdraw what they deposited.
   // After EndVote function is run and if proposal "buy_bitcoin" won,
   // users will not be able to withdraw ether
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "amount > balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        DAObalance = address(this).balance;
        
    }


    // ends the vote
    // if DAO decided not to buy cupcakes members can withdraw deposited ether
    function EndVote() public {
        require(
            block.timestamp > voteEndTime,
            "Vote not yet ended.");
          
        require(
            ended == true,
            "Must count vote first");  
            
        require(
            DAObalance >= 0.01 ether,
            "Not enough balance in DAO required to buy bitcoins. Members may withdraw deposited ether.");
            
        require(
            decision == 0,
            "DAO decided to not buy bitcoins. Members may withdraw deposited ether."); 
            
        if (DAObalance < 0.01 ether) revert();
            (bool success, ) = address(traderAddress).call{value: DAObalance}(abi.encodeWithSignature("purchase(uint256)", DAObalance));
            require(success);
            
        DAObalance = address(this).balance;
    }

    function checkBTCBalance() public view returns (uint) {
        Trader traderBalance = Trader(traderAddress);
        return traderBalance.BTCposition();
    }

    function checkBTCETHprice() public view returns (uint) {
        Trader traderBalance = Trader(traderAddress);
        return traderBalance.BTCETHprice();
    }
}