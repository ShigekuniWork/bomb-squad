import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './style.css'

function App() {
  return (
    <main>
      <h1>BombSquad</h1>
      <p>SBOM と脆弱性を継続的に追跡・管理します。</p>
    </main>
  )
}

const rootElement = document.getElementById('root')

if (rootElement === null) {
  throw new Error('Root element not found')
}

createRoot(rootElement).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
