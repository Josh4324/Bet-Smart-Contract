// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedBetting {


    // Set a bet question with deadline
    // Set options to question
    // Set a answer to the bet
    // Place a bet
    // Withdraw winnings


    enum QuestionStatus {
        Ongoing,
        Done
    }

    struct BetQuestion {
       string question;
       uint256 questionId;
       uint256 deadline;
    }


    mapping(uint256 => BetQuestion) IdToQuestion;
    mapping(uint256 => QuestionStatus) IdToQuestionStatus;
    mapping(uint256 => string[]) IdToOptions;
    mapping (uint256 id => uint256 answer) IdToAnswer;
    mapping (uint256 => bool) IdToAnswerStatus;
    mapping (uint256 => uint256)  idToTotalBet;
    mapping(address => mapping(uint256 id => uint256 optionId)) public UserToId;
    mapping(address => mapping(uint256 id => bool)) public UserToWinning;
    mapping(uint256 => address[]) IdToPlayers;
    mapping(uint256 => uint256) IdToWinners;
    mapping(address => mapping(uint256 id => bool)) public UserToPlayed;
  

    uint256 private questionId = 1;
    uint256 public betAmount = 0.1 ether;

    // Owner of the contract
    address public owner;

    // Event for Creating a Question
    event QuestionCreated(uint256 indexed questionId, string question);

    // Event for Adding Options
    event OptionCreated(uint256 indexed questionId, string[] options);

    // Event for Setting Answer
    event Answer(uint256 indexed questionId, uint256 optionId);

    // Event for placing a bet
    event BetPlaced(address indexed user, uint questionId, uint optionId);
    

    constructor() {
        owner = msg.sender; // Set the contract deployer as the owner
    }


    // Function to set a Bet question
    function setQuestion(string calldata question, uint256 deadline) external {
        if (msg.sender != owner){
            revert("Not Owner");
        }

        if (block.timestamp > deadline){
            revert();
        }

        IdToQuestion[questionId] = BetQuestion(question,questionId, deadline);
        IdToQuestionStatus[questionId] = QuestionStatus.Ongoing;

        emit QuestionCreated(questionId, question);

        questionId++;
    }

    // Function to set Options for Bet question
    function setOptions (uint256 id, string[] memory options) external {
         if (msg.sender != owner){
            revert("Not Owner");
        }

        if (options.length > 2){
            revert();
        }

        string[] memory arr = new string[](2);

        for (uint256 i; i < options.length; i++){
            arr[i] = options[i];
        }

        IdToOptions[id] = arr;

        emit OptionCreated(questionId, options);

    }

    function setAnswer (uint256 id, uint256 optionId) external {
         if (msg.sender != owner){
            revert("Not Owner");
        }

        IdToAnswer[id] = optionId;
        IdToAnswerStatus[id] = true;


        emit Answer(questionId, optionId);

    }

    function runBet (uint256 id) external {
         if (msg.sender != owner){
            revert("Not Owner");
        }

        if (block.timestamp < IdToQuestion[id].deadline){
            revert("Bet is still Ongoing");
        }

        for (uint256 i; i < IdToPlayers[id].length; i++){
            if (IdToAnswer[id] == UserToId[IdToPlayers[id][i]][id]){
                 UserToWinning[IdToPlayers[id][i]][id] = true;
                 IdToWinners[id] += 1;
            }    
        }

        IdToQuestionStatus[questionId] = QuestionStatus.Done;
    }

    // Function to place a bet
    function placeBet(uint256 id, uint256 optionId) external payable {
        require(msg.value == betAmount, "You must bet 0.1 ETH");

        if (block.timestamp > IdToQuestion[id].deadline){
            revert("Bet deadline has passed");
        }

        if (UserToPlayed[msg.sender][id]){
            revert("You have already placed this bet");
        }

        UserToId[msg.sender][id] = optionId;
        IdToPlayers[id].push(msg.sender);
        idToTotalBet[id] += msg.value; 
        UserToPlayed[msg.sender][id] = true;

        emit BetPlaced(msg.sender, id, optionId);
    }

    // Function to withdraw winnings
    function withdrawWin (uint256 id) external {
       uint256 winnings = idToTotalBet[id] / IdToWinners[id];

        if (UserToWinning[msg.sender][id] == true){

            (bool sent,) = payable(msg.sender).call{value: winnings}("");
            require(sent, "Failed to send Ether");
        }
    }

    // Fallback function to accept deposits to the contract
    receive() external payable {}


    // Only the owner can withdraw funds from the contract
    function withdrawFunds() external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function getQuestions() public view returns (BetQuestion[] memory) {
        BetQuestion[] memory items = new BetQuestion[](questionId - 1);
        for (uint256 i = 0; i < questionId - 1; i++) {
            items[i] = IdToQuestion[i+1];
        }
        return items;
    }

    function getOptions(uint256 id) public view returns (string[] memory) {
        return IdToOptions[id];
    }

    function getBalance(address user) public view returns(uint256) {
        return user.balance;
    }

}
