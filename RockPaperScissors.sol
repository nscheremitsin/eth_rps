// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";


contract RockPaperScissors {
    enum Choice {
        DEFAULT,
        ROCK,
        PAPER,
        SCISSORS
    }

    struct Game {
        bool isPending;
        address playingWith;
        bytes32 committedChoice;
        Choice revealedChoice;
        string result;
    }

    event Log(address indexed sender, string message);

    mapping(address => Game) games;
    mapping(Choice => string) choiceNames;

    constructor() {
        choiceNames[Choice.ROCK] = "rock";
        choiceNames[Choice.PAPER] = "paper";
        choiceNames[Choice.SCISSORS] = "scissors";
    }

    function emitLog(string memory message) private {
        emit Log(msg.sender, message);
    }

    function isPlayerHasPendingGame(address player) private view returns(bool) {
        return games[player].isPending;
    }
    
    function isPlayerPlaying(address player) private view returns(bool) {
        return games[player].playingWith != address(0);
    }

    function isPlayerCommitted(address player) private view returns(bool) {
        return games[player].committedChoice != bytes32(0);
    }

    function isPlayerRevealed(address player) private view returns(bool) {
        return games[player].revealedChoice != Choice.DEFAULT;
    }

    function calcHash(Choice choice, uint num) private pure returns(bytes32) {
        return sha256(abi.encodePacked(Strings.toString(uint(choice)), Strings.toString(num)));
    }

    function calcResult() private {
        Game storage senderGame = games[msg.sender];
        Game storage opponentGame = games[senderGame.playingWith];

        Choice senderChoice = senderGame.revealedChoice;
        Choice opponentChoice = opponentGame.revealedChoice;

        require(senderChoice != Choice.DEFAULT, "You have not revealed yet");
        require(opponentChoice != Choice.DEFAULT, "Your opponent has not revealed yet");

        string memory senderChoiceName = choiceNames[senderChoice];
        string memory opponentChoiceName = choiceNames[opponentChoice];

        string memory senderResult;
        string memory opponentResult;

        if (senderChoice == opponentChoice) {
            string memory res = string.concat(
                "You have draw between ", senderChoiceName, " and ", opponentChoiceName
            );
            senderResult = res;
            opponentResult = res;
        }
        else {
            bool isSenderWon = 
                senderChoice == Choice.PAPER && opponentChoice == Choice.ROCK 
                || senderChoice == Choice.ROCK && opponentChoice == Choice.SCISSORS 
                || senderChoice == Choice.SCISSORS && opponentChoice == Choice.PAPER;
            senderResult = string.concat(
                "You have ", isSenderWon ? "won" : "lost", " with ", senderChoiceName, " against ", opponentChoiceName
            );
            opponentResult = string.concat(
                "You have ", isSenderWon ? "lost" : "won", " with ", opponentChoiceName, " against ", senderChoiceName
            );
        }

        senderGame.result = senderResult;
        opponentGame.result = opponentResult;
    }

    modifier CanPlayNewGame {
        require(!isPlayerHasPendingGame(msg.sender), "You have a pending game");
        require(!isPlayerPlaying(msg.sender), "You are currently playing a game");
        _;
    }

    modifier CurrentlyPlaying {
        require(
            isPlayerPlaying(msg.sender),
             "You are not playing at the moment (maybe because your opponent has left the game)"
        );
        _;
    }

    function start() public CanPlayNewGame {
        games[msg.sender].isPending = true;
        emitLog("Started a new game and waiting for the opponent");
    }

    function cancel() public {
        require(
            isPlayerHasPendingGame(msg.sender), 
            "You do not have a pending game (maybe because someone has joined or left the game)"
        );
        delete games[msg.sender];
        emitLog("Canceled a new game");
    }

    function join(address initiator) public CanPlayNewGame {
        require(isPlayerHasPendingGame(initiator), "No pending game inited by this initiator");
        games[initiator].isPending = false;
        games[initiator].playingWith = msg.sender;
        games[msg.sender].playingWith = initiator;
        emitLog("Joined the game");
    }

    function exit() public CurrentlyPlaying {
        delete games[games[msg.sender].playingWith];
        delete games[msg.sender];
        emitLog("Exited the game");
    }

    function commit(bytes32 hash) public CurrentlyPlaying {
        require(!isPlayerCommitted(msg.sender), "You have committed already");
        games[msg.sender].committedChoice = hash;
        emitLog("Committed the choice");
    }

    function reveal(Choice choice, uint num) public CurrentlyPlaying {
        require(!isPlayerRevealed(msg.sender), "You have revealed already");
        require(choice != Choice.DEFAULT, "You can not use default choice");
        require(isPlayerCommitted(msg.sender), "You have not committed yet");
        Game storage senderGame = games[msg.sender];
        require(isPlayerCommitted(senderGame.playingWith), "Your opponent has not committed yet");
        require(
            calcHash(choice, num) == senderGame.committedChoice, 
            "Your revealed data does not correspond to the committed data"
        );
        senderGame.revealedChoice = choice;
        emitLog("Revealed the choice");
    }

    function result() public CurrentlyPlaying returns(string memory) {
        Game storage senderGame = games[msg.sender];
        // If result was not calculated
        if (bytes(senderGame.result).length == 0) {
            // Result is calculated once for both players
            calcResult();
        }
        string memory res = senderGame.result;
        // Game data for sender is deleted (opponent can still view the result if he hasn't yet)
        delete games[msg.sender];
        emitLog("Got the result and finished the game");
        return res;
    }
}
