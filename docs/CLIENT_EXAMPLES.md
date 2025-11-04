# Esempi di Configurazione Client MCP

Questa guida mostra come configurare diversi client MCP per connettersi al server MCP-GSC via HTTP.

## 📋 Prerequisiti

Prima di configurare qualsiasi client, assicurati che:

1. Il server MCP-GSC sia in esecuzione
2. Conosci l'indirizzo IP e la porta del server
3. Il client possa raggiungere il server (verifica firewall e rete)

## 🖥️ Client Supportati

### 1. Claude Desktop

**File di configurazione:**
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

**Configurazione HTTP:**

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://localhost:8000/mcp"
    }
  }
}
```

**Per server remoto:**

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://192.168.1.100:8000/mcp"
    }
  }
}
```

**Con descrizione:**

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://localhost:8000/mcp",
      "description": "Google Search Console API access via MCP"
    }
  }
}
```

### 2. Cursor IDE

**File di configurazione:**
- `.cursor/mcp_config.json` nella directory del progetto
- Oppure nelle impostazioni globali di Cursor

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://localhost:8000/mcp",
      "name": "Google Search Console",
      "description": "Access to Google Search Console data and tools"
    }
  }
}
```

### 3. Continue (VS Code Extension)

**File di configurazione:**
- `.continue/config.json` nella directory del progetto

```json
{
  "models": [...],
  "mcpServers": [
    {
      "name": "gscServer",
      "url": "http://localhost:8000/mcp"
    }
  ]
}
```

### 4. MCP CLI Client

Usa il client MCP da riga di comando:

```bash
# Installazione
npm install -g @modelcontextprotocol/cli

# Connessione al server
mcp connect http://localhost:8000/mcp

# O con un comando specifico
mcp call http://localhost:8000/mcp list_properties
```

### 5. Custom Client (Python)

Esempio di client Python personalizzato:

```python
import httpx
import json

class MCPClient:
    def __init__(self, base_url):
        self.base_url = base_url
        self.client = httpx.Client()
    
    def call_tool(self, tool_name, **kwargs):
        """Chiama un tool MCP sul server"""
        response = self.client.post(
            f"{self.base_url}/call",
            json={
                "method": "tools/call",
                "params": {
                    "name": tool_name,
                    "arguments": kwargs
                }
            },
            headers={
                "Content-Type": "application/json"
            },
            timeout=30.0
        )
        return response.json()

# Utilizzo
client = MCPClient("http://localhost:8000/mcp")
result = client.call_tool("list_properties")
print(json.dumps(result, indent=2))
```

### 6. Custom Client (JavaScript/TypeScript)

Esempio di client Node.js:

```javascript
import { EventSource } from 'eventsource';

class MCPClient {
  constructor(baseUrl) {
    this.baseUrl = baseUrl;
  }

  async callTool(toolName, args = {}) {
    const response = await fetch(`${this.baseUrl}/call`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        method: 'tools/call',
        params: {
          name: toolName,
          arguments: args,
        },
      }),
    });

    return await response.json();
  }

  // Per streaming con HTTP streamable
  streamEvents(callback) {
    const eventSource = new EventSource(this.baseUrl);
    
    eventSource.onmessage = (event) => {
      callback(JSON.parse(event.data));
    };

    eventSource.onerror = (error) => {
      console.error('Stream Error:', error);
      eventSource.close();
    };

    return eventSource;
  }
}

// Utilizzo
const client = new MCPClient('http://localhost:8000/mcp');

// Chiamata singola
const result = await client.callTool('list_properties');
console.log(result);

// Streaming
const stream = client.streamEvents((data) => {
  console.log('Received:', data);
});
```

## 🌐 Configurazioni di Rete

### Server Locale (Stesso Computer)

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://localhost:8000/mcp"
    }
  }
}
```

o

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://127.0.0.1:8000/mcp"
    }
  }
}
```

### Server nella Rete Locale

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://192.168.1.100:8000/mcp"
    }
  }
}
```

### Server Remoto (Internet)

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://your-domain.com:8000/mcp"
    }
  }
}
```

**Nota**: Per server remoti su Internet, si raccomanda fortemente l'uso di HTTPS con reverse proxy (nginx/Apache).

### Dietro Reverse Proxy (HTTPS)

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "https://api.yourdomain.com/gsc/mcp"
    }
  }
}
```

Esempio configurazione nginx:

```nginx
server {
    listen 443 ssl;
    server_name api.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /gsc/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        # Per HTTP streamable
        proxy_set_header Connection '';
        proxy_buffering off;
        chunked_transfer_encoding off;
    }
}
```

## 🔧 Test della Connessione

### Con curl

```bash
# Test base
curl http://localhost:8000/mcp

# Test con timeout
curl --max-time 5 http://localhost:8000/mcp

# Test SSE stream
curl -N http://localhost:8000/mcp
```

### Con httpie

```bash
# Installazione
pip install httpie

# Test
http GET http://localhost:8000/mcp

# Stream
http --stream GET http://localhost:8000/mcp
```

### Con Python

```python
import requests

try:
    response = requests.get('http://localhost:8000/mcp', timeout=5)
    print(f"Status: {response.status_code}")
    print(f"Server reachable: {'Yes' if response.ok else 'No'}")
except requests.exceptions.ConnectionError:
    print("Cannot connect to server")
except requests.exceptions.Timeout:
    print("Connection timeout")
```

## 📊 Debug e Troubleshooting

### Client non si connette

1. **Verifica che il server sia in esecuzione:**
   ```bash
   curl http://localhost:8000/mcp
   ```

2. **Verifica porte e firewall:**
   ```bash
   # Linux/Mac
   netstat -tulpn | grep 8000
   
   # Windows
   netstat -ano | findstr :8000
   ```

3. **Verifica URL nel client:**
   - Assicurati che l'URL termini con `/mcp`
   - Verifica IP e porta corretti
   - Controlla protocollo (http vs https)

4. **Test con client semplice:**
   ```bash
   # Installa websocat
   npm install -g websocat
   
   # Test connessione
   websocat http://localhost:8000/mcp
   ```

### Errori comuni

| Errore | Causa | Soluzione |
|--------|-------|-----------|
| Connection refused | Server non in esecuzione | Avvia il server |
| Timeout | Firewall/rete | Verifica configurazione rete |
| 404 Not Found | URL errato | Aggiungi `/mcp` all'URL |
| SSL Error | HTTPS con server HTTP | Usa `http://` invece di `https://` |
| CORS Error | Configurazione CORS | Aggiungi headers CORS se necessario |

## 🔐 Autenticazione (Futuro)

Al momento il server non implementa autenticazione. Per aggiungere sicurezza:

1. **Basic Auth via Reverse Proxy** (nginx/Apache)
2. **API Key personalizzata** (richiede modifica del server)
3. **OAuth2** (richiede modifica del server)
4. **VPN/SSH Tunnel** (sicurezza a livello di rete)

## 📚 Risorse

- [MCP Protocol](https://modelcontextprotocol.io/)
- [HTTP Streamable Transport](https://modelcontextprotocol.io/docs/concepts/transports)
- [FastMCP Documentation](https://github.com/jlowin/fastmcp)

