import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

function App() {
  const [examples, setExamples] = useState([])
  const [selectedExample, setSelectedExample] = useState(null)
  const [actions, setActions] = useState([])
  const [input, setInput] = useState('')

  useEffect(() => {
    axios.get('/api/examples').then(res => setExamples(res.data.examples))
  }, [])

  const startSession = (example) => {
    axios.post('/api/session/start', { agent: example }).then(() => {
      setSelectedExample(example)
      setActions([])
    })
  }

  const runStep = () => {
    axios.post('/api/session/step', { input: input }).then(res => {
      setActions(res.data.actions)
      setInput('')
    })
  }

  return (
    <div className="App">
      <h1>Gloria Web Interface</h1>
      {!selectedExample ? (
        <ul>
          {examples.map(ex => (
            <li key={ex} onClick={() => startSession(ex)}>{ex}</li>
          ))}
        </ul>
      ) : (
        <div>
          <h2>Running: {selectedExample}</h2>
          <input value={input} onChange={e => setInput(e.target.value)} placeholder="Input (e.g., [time_day(noon)])" />
          <button onClick={runStep}>Step</button>
          <h3>Actions:</h3>
          <ul>
            {actions.map((act, i) => <li key={i}>{act}</li>)}
          </ul>
        </div>
      )}
    </div>
  )
}

export default App
