import React from 'react';

const GarticPhone = () => {
  const [players, setPlayers] = React.useState([]);
  const [gameStatus, setGameStatus] = React.useState('Waiting for players...');
  const [gameMode, setGameMode] = React.useState('Classic');

  const handlePlayerJoin = (player) => {
    setPlayers([...players, player]);
    setGameStatus(`Player ${player} joined!`);
  };

  const handleGameStart = () => {
    if (players.length < 2) {
      setGameStatus('Not enough players to start the game.');
    } else {
      setGameStatus('Game started!');
      // Implement game logic here...
    }
  };

  return (
    <div className="gartic-phone">
      <h1>Gartic Phone</h1>
      <div className="game-status">Status: {gameStatus}</div>
      <div className="game-mode">
        <label>
          Game Mode:
          <select value={gameMode} onChange={(e) => setGameMode(e.target.value)}>
            <option value="Classic">Classic</option>
            <option value="Fast">Fast</option>
            <option value="Custom">Custom</option>
          </select>
        </label>
      </div>
      <div className="player-list">
        <h2>Players</h2>
        <ul>
          {players.map((player, index) => (
            <li key={index}>{player}</li>
          ))}
        </ul>
      </div>
      <button onClick={handleGameStart}>Start Game</button>
      {/* Canvas and drawing area should be implemented here */}
    </div>
  );
};

export default GarticPhone;