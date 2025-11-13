// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GarticPhoneGame {
    enum GameStatus { WaitingForPlayers, Playing, Finished }
    enum GameMode { Quick, Standard, Extended }

    struct Game {
        uint256 gameId;
        GameMode mode;
        GameStatus status;
        address[] players;
        uint256 totalPool;
        uint256 platformFee;
        uint256 prizePool;
        address[] winners;
        uint256[] prizes;
        uint256 createdAt;
        uint256 startedAt;
        uint256 finishedAt;
    }

    struct PlayerStats {
        uint256 gamesPlayed;
        uint256 gamesWon;
        uint256 totalEarned;
        uint256 totalSpent;
    }

    struct GameRound {
        uint256 roundId;
        uint256 gameId;
        address drawer;
        address guesser;
        string drawingHash;
        string guess;
        uint256 score;
    }

    uint256 public gameCounter;
    uint256 public platformBalance;
    uint256 public platformFeePercentage = 10;

    address public owner;

    mapping(uint256 => Game) public games;
    mapping(address => PlayerStats) public playerStats;
    mapping(uint256 => GameRound[]) public gameRounds;
    mapping(GameMode => uint256) public entryFees;
    mapping(GameMode => uint256) public minPlayers;
    mapping(GameMode => uint256) public maxPlayers;

    event GameCreated(uint256 indexed gameId, GameMode mode, uint256 createdAt);
    event PlayerJoined(uint256 indexed gameId, address indexed player, uint256 amount);
    event GameStarted(uint256 indexed gameId, uint256 startedAt);
    event GameFinished(uint256 indexed gameId, address[] winners, uint256[] prizes);
    event RoundCompleted(uint256 indexed gameId, uint256 roundId, address drawer, address guesser, uint256 score);
    event PlatformFeeWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier gameExists(uint256 gameId) {
        require(gameId < gameCounter, "Game does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
        gameCounter = 0;

        entryFees[GameMode.Quick] = 0.00001 ether;
        entryFees[GameMode.Standard] = 0.00002 ether;
        entryFees[GameMode.Extended] = 0.00005 ether;

        minPlayers[GameMode.Quick] = 3;
        minPlayers[GameMode.Standard] = 5;
        minPlayers[GameMode.Extended] = 8;

        maxPlayers[GameMode.Quick] = 5;
        maxPlayers[GameMode.Standard] = 8;
        maxPlayers[GameMode.Extended] = 10;
    }

    function createGame(GameMode mode) external returns (uint256) {
        uint256 newGameId = gameCounter;
        gameCounter++;

        Game storage newGame = games[newGameId];
        newGame.gameId = newGameId;
        newGame.mode = mode;
        newGame.status = GameStatus.WaitingForPlayers;
        newGame.createdAt = block.timestamp;

        emit GameCreated(newGameId, mode, block.timestamp);
        return newGameId;
    }

    function joinGame(uint256 gameId) external payable gameExists(gameId) {
        Game storage game = games[gameId];
        
        require(game.status == GameStatus.WaitingForPlayers, "Game is not accepting players");
        require(msg.value == entryFees[game.mode], "Incorrect entry fee");
        require(game.players.length < maxPlayers[game.mode], "Game is full");

        for (uint256 i = 0; i < game.players.length; i++) {
            require(game.players[i] != msg.sender, "Player already joined this game");
        }

        game.players.push(msg.sender);
        game.totalPool += msg.value;
        game.platformFee = (game.totalPool * platformFeePercentage) / 100;
        game.prizePool = game.totalPool - game.platformFee;

        playerStats[msg.sender].gamesPlayed++;
        playerStats[msg.sender].totalSpent += msg.value;

        emit PlayerJoined(gameId, msg.sender, msg.value);

        if (game.players.length >= minPlayers[game.mode]) {
            startGame(gameId);
        }
    }

    function startGame(uint256 gameId) public gameExists(gameId) {
        Game storage game = games[gameId];
        
        require(game.status == GameStatus.WaitingForPlayers, "Game already started or finished");
        require(game.players.length >= minPlayers[game.mode], "Not enough players");

        game.status = GameStatus.Playing;
        game.startedAt = block.timestamp;

        emit GameStarted(gameId, block.timestamp);
    }

    function recordRoundResult(
        uint256 gameId,
        address drawer,
        address guesser,
        string memory drawingHash,
        string memory guess,
        uint256 score
    ) external onlyOwner gameExists(gameId) {
        GameRound memory newRound = GameRound({
            roundId: gameRounds[gameId].length,
            gameId: gameId,
            drawer: drawer,
            guesser: guesser,
            drawingHash: drawingHash,
            guess: guess,
            score: score
        });

        gameRounds[gameId].push(newRound);

        emit RoundCompleted(gameId, newRound.roundId, drawer, guesser, score);
    }

    function finishGame(uint256 gameId, address[] calldata winners, uint256[] calldata prizes) 
        external 
        onlyOwner 
        gameExists(gameId) 
    {
        Game storage game = games[gameId];
        
        require(game.status == GameStatus.Playing, "Game is not in playing status");
        require(winners.length == prizes.length, "Winners and prizes length mismatch");
        require(winners.length > 0, "Must have at least one winner");

        game.status = GameStatus.Finished;
        game.finishedAt = block.timestamp;
        game.winners = winners;
        game.prizes = prizes;

        for (uint256 i = 0; i < winners.length; i++) {
            require(prizes[i] <= game.prizePool, "Prize exceeds pool");
            payable(winners[i]).transfer(prizes[i]);
            playerStats[winners[i]].gamesWon++;
            playerStats[winners[i]].totalEarned += prizes[i];
        }

        platformBalance += game.platformFee;

        emit GameFinished(gameId, winners, prizes);
    }

    function getGameDetails(uint256 gameId) 
        external 
        view 
        gameExists(gameId) 
        returns (Game memory) 
    {
        return games[gameId];
    }

    function getGamePlayers(uint256 gameId) 
        external 
        view 
        gameExists(gameId) 
        returns (address[] memory) 
    {
        return games[gameId].players;
    }

    function getGameRounds(uint256 gameId) 
        external 
        view 
        gameExists(gameId) 
        returns (GameRound[] memory) 
    {
        return gameRounds[gameId];
    }

    function getPlayerStats(address player) 
        external 
        view 
        returns (PlayerStats memory) 
    {
        return playerStats[player];
    }

    function withdrawPlatformFees() external onlyOwner {
        require(platformBalance > 0, "No fees to withdraw");
        uint256 amount = platformBalance;
        platformBalance = 0;
        payable(owner).transfer(amount);
        emit PlatformFeeWithdrawn(owner, amount);
    }

    function setEntryFee(GameMode mode, uint256 fee) external onlyOwner {
        entryFees[mode] = fee;
    }

    function setPlatformFeePercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 50, "Fee percentage too high");
        platformFeePercentage = percentage;
    }

    receive() external payable {}
}