import { useState } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState('');

  const getGreeting = async () => {
    try {
      const res = await fetch('http://localhost:8080/hello/greeting');
      const text = await res.text();
      setMessage(text);
    } catch (err) {
      console.error(err);
      setMessage('Error connecting to backend');
    }
  };

  return (
    <div style={{ padding: '2rem', fontFamily: 'Arial' }}>
      <h1>BinBuddy</h1>
      <button onClick={getGreeting} style={{ padding: '0.5rem 1rem', marginTop: '1rem' }}>
        Get Greeting
      </button>
      <p style={{ marginTop: '1rem', fontSize: '1.2rem' }}>{message}</p>
    </div>
  );
}

export default App;
