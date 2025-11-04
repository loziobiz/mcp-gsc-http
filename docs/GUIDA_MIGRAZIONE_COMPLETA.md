# Guida Completa alla Migrazione di un Server MCP da STDIO a HTTP-Streamable con Deployment su Cloudflare

> **Destinatario**: Agente AI Claude Sonnet 4.5  
> **Scopo**: Migrare un server MCP basato su fastMCP con trasporto stdio verso HTTP-streamable e deployarlo su Cloudflare Containers  
> **Progetto di Riferimento**: mcp-gsc-http (Google Search Console MCP Server)

---

## 📋 Indice

1. [Panoramica della Migrazione](#panoramica)
2. [Prerequisiti](#prerequisiti)
3. [Architettura di Destinazione](#architettura)
4. [Fase 1: Conversione del Server Python](#fase-1)
5. [Fase 2: Gestione delle Credenziali Google](#fase-2)
6. [Fase 3: Containerizzazione Docker](#fase-3)
7. [Fase 4: Configurazione Cloudflare Worker](#fase-4)
8. [Fase 5: Deployment su Cloudflare](#fase-5)
9. [Fase 6: Test e Verifica](#fase-6)
10. [Troubleshooting Comune](#troubleshooting)
11. [Appendice: Esempi Completi](#appendice)

---

## 1. Panoramica della Migrazione {#panoramica}

### 1.1 Punto di Partenza

Il server MCP da migrare ha queste caratteristiche:
- **Framework**: fastMCP (basato su MCP SDK)
- **Trasporto**: stdio (comunicazione locale tramite stdin/stdout)
- **Esecuzione**: Locale, avviato da Claude Desktop
- **Autenticazione Google**: Service account (stesso del progetto di riferimento)
- **Deployment**: Solo locale

### 1.2 Punto di Arrivo

Il server migrato avrà:
- **Framework**: fastMCP (invariato)
- **Trasporto**: HTTP-streamable (accesso remoto via HTTP)
- **Esecuzione**: Container Docker su Cloudflare
- **Autenticazione Google**: Service account (ereditato dal progetto GSC)
- **Deployment**: Globale su edge network Cloudflare

### 1.3 Vantaggi della Migrazione

✅ **Accesso Remoto**: Il server è accessibile da qualsiasi client via HTTP  
✅ **Scalabilità**: Cloudflare gestisce automaticamente il carico  
✅ **Affidabilità**: Deploy su edge network distribuito globalmente  
✅ **Manutenzione**: Update senza riavviare client locali  
✅ **Condivisione**: Stesso server utilizzabile da più utenti/client  

### 1.4 Compatibilità

- Il codice delle funzioni MCP tools **non cambia**
- Le credenziali Google service account sono **condivise**
- La logica di business rimane **identica**
- Cambia solo il **layer di trasporto** e il **layer di deployment**

---

## 2. Prerequisiti {#prerequisiti}

### 2.1 Software Necessario

```bash
# Docker Desktop (richiesto per build container)
# Verifica installazione:
docker --version
# Output atteso: Docker version 24.0.0 o superiore

# Node.js e npm (per Wrangler CLI)
node --version
# Output atteso: v18.0.0 o superiore

npm --version
# Output atteso: 9.0.0 o superiore

# Python 3.11+
python3 --version
# Output atteso: Python 3.11.0 o superiore
```

### 2.2 Account e Accessi

1. **Account Cloudflare**
   - Piano: Workers Paid (necessario per Containers Beta)
   - Accesso: Dashboard Cloudflare + API Token

2. **Credenziali Google Service Account**
   - File `credentials.json` dal progetto mcp-gsc-http
   - Email service account: `*****@*****.iam.gserviceaccount.com`
   - Scope: `https://www.googleapis.com/auth/webmasters`

### 2.3 File dal Progetto di Riferimento

Avrai bisogno di questi file dal progetto mcp-gsc-http:

```
/Users/alessandrobisi/Progetti/__mcps__/mcp-gsc-http/
├── credentials.json          # Credenziali Google (DA COPIARE)
├── Dockerfile               # Template Dockerfile (DA ADATTARE)
├── worker.js                # Worker Cloudflare (DA ADATTARE)
├── wrangler.jsonc           # Config Cloudflare (DA ADATTARE)
├── package.json             # Dipendenze npm (DA ADATTARE)
└── gsc_server.py            # Server Python (RIFERIMENTO)
```

---

## 3. Architettura di Destinazione {#architettura}

### 3.1 Stack Tecnologico

```
┌─────────────────────────────────────────────────────┐
│ Client MCP (Claude Desktop, Cursor, ecc.)           │
│ Configurazione: { "url": "https://..." }            │
└─────────────────────┬───────────────────────────────┘
                      │ HTTP/HTTPS
                      ▼
┌─────────────────────────────────────────────────────┐
│ Cloudflare Worker (worker.js)                       │
│ - Routing richieste                                 │
│ - Gestione CORS                                     │
│ - Health checks                                     │
│ - Path mapping: /mcp → /                           │
└─────────────────────┬───────────────────────────────┘
                      │ Proxy interno
                      ▼
┌─────────────────────────────────────────────────────┐
│ Cloudflare Container (Docker)                       │
│ - Python 3.11                                       │
│ - uvicorn ASGI server                               │
│ - MCP server con transport HTTP-streamable          │
│ - Credenziali Google in /app/credentials.json      │
└─────────────────────┬───────────────────────────────┘
                      │ Google API
                      ▼
┌─────────────────────────────────────────────────────┐
│ Google APIs (Search Console, ecc.)                  │
└─────────────────────────────────────────────────────┘
```

### 3.2 Flusso di una Richiesta

```
1. Client → HTTP POST → https://your-worker.workers.dev/mcp
2. Worker riceve richiesta
3. Worker rimuove prefisso /mcp dal path
4. Worker fa proxy → Container interno
5. Container → Python server HTTP-streamable su porta 8000
6. Python server → Chiama Google API se necessario
7. Python server → Risponde con JSON MCP
8. Container → Passa risposta al Worker
9. Worker → Aggiunge headers CORS
10. Worker → Risponde al Client
```

### 3.3 Gestione delle Sessioni

Il transport HTTP-streamable di MCP utilizza:
- **Session ID**: Header `Mcp-Session-Id` per identificare le sessioni
- **Stateful**: Il server mantiene lo stato della sessione
- **Durable Objects**: Cloudflare usa Durable Objects per garantire che le richieste della stessa sessione vadano allo stesso container

---

## 4. Fase 1: Conversione del Server Python {#fase-1}

### 4.1 Struttura Base del Server con STDIO

Supponiamo che il tuo server attuale abbia questa struttura:

```python
# server_originale.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("nome-server")

@mcp.tool()
async def esempio_tool(parametro: str) -> str:
    """Descrizione del tool."""
    # Logica del tool
    return "risultato"

# Altri tools...

if __name__ == "__main__":
    # Transport stdio per uso locale
    mcp.run(transport="stdio")
```

### 4.2 Conversione a HTTP-Streamable

**MODIFICA PRINCIPALE**: Cambia solo il blocco `if __name__ == "__main__":` alla fine del file.

```python
# server_migrato.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("nome-server")

@mcp.tool()
async def esempio_tool(parametro: str) -> str:
    """Descrizione del tool."""
    # Logica del tool (INVARIATA)
    return "risultato"

# Altri tools... (INVARIATI)

if __name__ == "__main__":
    # ===== INIZIO MODIFICHE =====
    import os
    import uvicorn
    
    # Configurazione porta e host da variabili d'ambiente
    port = int(os.environ.get("SERVER_PORT", "8000"))
    host = os.environ.get("SERVER_HOST", "0.0.0.0")
    
    print(f"Starting MCP server on {host}:{port}")
    print(f"Access the server at: http://{host}:{port}/mcp")
    
    # Configura il path per l'endpoint MCP
    # Questo fa sì che l'app MCP risponda a / invece di un path specifico
    mcp.settings.streamable_http_path = "/"
    
    # Crea l'app ASGI per HTTP-streamable
    app = mcp.streamable_http_app()
    
    # Avvia con uvicorn
    uvicorn.run(app, host=host, port=port, log_level="info")
    # ===== FINE MODIFICHE =====
```

### 4.3 Esempio Completo dal Progetto GSC

Ecco l'implementazione completa dal file `gsc_server.py`:

```python
if __name__ == "__main__":
    # Start the MCP server on HTTP streamable transport
    # Default port: 8000, può essere modificato tramite variabile d'ambiente GSC_PORT
    import os
    import contextlib
    
    # Configurazione porta e host per deployment personalizzato
    port = int(os.environ.get("GSC_PORT", "8000"))
    host = os.environ.get("GSC_HOST", "0.0.0.0")
    
    print(f"Starting MCP-GSC server on {host}:{port}")
    print(f"Access the server at: http://{host}:{port}/mcp")
    
    # Per deployment personalizzato con uvicorn
    import uvicorn
    from starlette.applications import Starlette
    from starlette.routing import Mount
    
    # Context manager per gestire il lifespan del session manager
    # L'app MCP streamable http è già un'app ASGI completa
    # Configura il path per montare l'app alla root /
    # Questo fa sì che l'app MCP risponda a / invece di /mcp
    mcp.settings.streamable_http_path = "/"
    
    # Usa direttamente l'app MCP senza wrapping in Starlette
    # Il session manager viene avviato automaticamente
    app = mcp.streamable_http_app()
    
    # Avvia con uvicorn
    uvicorn.run(app, host=host, port=port, log_level="info")
```

### 4.4 Dipendenze Necessarie

Aggiungi al `requirements.txt`:

```txt
# MCP SDK con supporto HTTP-streamable
mcp[cli]>=1.3.0

# Server ASGI
uvicorn>=0.30.0
starlette>=0.37.0

# Se usi Google APIs (ereditate dal progetto GSC)
google-api-python-client>=2.163.0
google-auth-httplib2>=0.2.0
google-auth-oauthlib>=1.2.1
```

### 4.5 Test Locale Prima del Deploy

```bash
# Attiva virtual environment
python3 -m venv .venv
source .venv/bin/activate  # Mac/Linux
# oppure .venv\Scripts\activate su Windows

# Installa dipendenze
pip install -r requirements.txt

# Avvia il server
python server_migrato.py

# Output atteso:
# Starting MCP server on 0.0.0.0:8000
# Access the server at: http://0.0.0.0:8000/mcp
# INFO:     Started server process [12345]
# INFO:     Waiting for application startup.
# INFO:     Application startup complete.
# INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)

# In un altro terminale, testa l'endpoint:
curl http://localhost:8000/

# Dovresti ricevere una risposta (anche un errore MCP è OK, 
# significa che il server risponde correttamente)
```

---

## 5. Fase 2: Gestione delle Credenziali Google {#fase-2}

### 5.1 Utilizzo dello Stesso Service Account

Il progetto mcp-gsc-http usa un service account Google che ha accesso a Google Search Console. Se il tuo nuovo server deve accedere a Google APIs (Search Console o altre), **usa lo stesso service account**.

### 5.2 Copia delle Credenziali

```bash
# Copia il file credentials.json dal progetto GSC
cp /Users/alessandrobisi/Progetti/__mcps__/mcp-gsc-http/credentials.json \
   /percorso/tuo/nuovo/progetto/credentials.json
```

### 5.3 Caricamento Credenziali nel Server Python

Usa lo stesso pattern del progetto GSC per caricare le credenziali:

```python
import os
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Path alle credenziali
# Il server cerca in più posizioni possibili
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
POSSIBLE_CREDENTIAL_PATHS = [
    os.environ.get("GSC_CREDENTIALS_PATH"),  # Variabile d'ambiente
    "/app/credentials.json",                 # Path nel container Cloudflare
    os.path.join(SCRIPT_DIR, "credentials.json"),  # Path locale
]

def get_google_service(api_name: str, api_version: str, scopes: list):
    """
    Restituisce un servizio Google API autenticato con service account.
    
    Args:
        api_name: Nome dell'API (es. "searchconsole")
        api_version: Versione dell'API (es. "v1")
        scopes: Lista di scope necessari
    
    Returns:
        Oggetto servizio Google API
    """
    # Cerca il file delle credenziali
    for cred_path in POSSIBLE_CREDENTIAL_PATHS:
        if cred_path and os.path.exists(cred_path):
            try:
                creds = service_account.Credentials.from_service_account_file(
                    cred_path, scopes=scopes
                )
                return build(api_name, api_version, credentials=creds)
            except Exception as e:
                print(f"Error loading credentials from {cred_path}: {e}")
                continue
    
    # Se arriviamo qui, nessuna credenziale è stata trovata
    raise FileNotFoundError(
        f"Credentials not found. Please set GSC_CREDENTIALS_PATH or place "
        f"credentials.json in one of: {POSSIBLE_CREDENTIAL_PATHS}"
    )

# Esempio di utilizzo nei tools
@mcp.tool()
async def esempio_google_api() -> str:
    """Tool che usa Google API."""
    try:
        # Definisci gli scope necessari per la tua API
        SCOPES = ["https://www.googleapis.com/auth/webmasters"]
        
        # Ottieni il servizio Google
        service = get_google_service("searchconsole", "v1", SCOPES)
        
        # Usa il servizio
        result = service.sites().list().execute()
        
        return f"Success: {result}"
    except Exception as e:
        return f"Error: {str(e)}"
```

### 5.4 Variabili d'Ambiente per le Credenziali

Nel container Cloudflare (vedremo dopo), configurerai:

```bash
# Variabili d'ambiente nel container
GSC_CREDENTIALS_PATH=/app/credentials.json
GSC_SKIP_OAUTH=true  # Forza l'uso del service account, non OAuth
```

---

## 6. Fase 3: Containerizzazione Docker {#fase-3}

### 6.1 Creazione del Dockerfile

Crea un file `Dockerfile` nella root del tuo progetto:

```dockerfile
# Usa Python 3.11 come base
FROM python:3.11-slim

# Metadata
LABEL maintainer="tuo-email@esempio.com"
LABEL description="MCP Server HTTP-Streamable per Cloudflare Containers"

# Installa dipendenze di sistema necessarie
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crea directory di lavoro
WORKDIR /app

# Copia il file dei requisiti
COPY requirements.txt /app/requirements.txt

# Installa le dipendenze Python
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copia il codice del server
COPY server_migrato.py /app/server.py

# Copia le credenziali Google
# IMPORTANTE: Questo file deve esistere nella directory di build
COPY credentials.json /app/credentials.json

# Imposta variabili d'ambiente
ENV SERVER_PORT=8000
ENV SERVER_HOST=0.0.0.0
ENV GSC_CREDENTIALS_PATH=/app/credentials.json
ENV GSC_SKIP_OAUTH=true
ENV PYTHONUNBUFFERED=1

# Esponi la porta del server
EXPOSE 8000

# Health check (opzionale ma consigliato)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Comando di avvio
CMD ["python", "server.py"]
```

### 6.2 File .dockerignore

Crea un file `.dockerignore` per escludere file non necessari dal container:

```
# .dockerignore

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.venv/
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Git
.git/
.gitignore

# Documentation
*.md
docs/

# Test
tests/
test_*.py
*_test.py

# Logs
*.log

# Secrets (escludi se li gestisci diversamente)
# credentials.json  # ATTENZIONE: non escludere se lo usi nel container!
token.json
client_secrets.json
```

### 6.3 Build Locale del Container

Prima di deployare su Cloudflare, testa il build del container localmente:

```bash
# Build dell'immagine
docker build -t mcp-server-test:latest .

# Output atteso:
# [+] Building 45.2s (14/14) FINISHED
# => [internal] load build definition from Dockerfile
# => [internal] load .dockerignore
# => [internal] load metadata for docker.io/library/python:3.11-slim
# => ...
# => exporting to image
# => => naming to docker.io/library/mcp-server-test:latest

# Verifica che l'immagine sia stata creata
docker images | grep mcp-server-test

# Output atteso:
# mcp-server-test    latest    abc123def456    2 minutes ago    XXX MB
```

### 6.4 Test del Container Localmente

```bash
# Avvia il container localmente
docker run -p 8000:8000 mcp-server-test:latest

# Output atteso:
# Starting MCP server on 0.0.0.0:8000
# Access the server at: http://0.0.0.0:8000/mcp
# INFO:     Started server process [1]
# INFO:     Waiting for application startup.
# INFO:     Application startup complete.
# INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)

# In un altro terminale, testa l'endpoint
curl http://localhost:8000/

# Se ricevi una risposta (anche un errore JSON MCP), il container funziona!
```

### 6.5 Risoluzione Problemi Docker

**Problema**: "Cannot connect to the Docker daemon"  
**Soluzione**: Avvia Docker Desktop

**Problema**: "credentials.json not found"  
**Soluzione**: Verifica che il file esista e sia copiato correttamente

**Problema**: Build lento  
**Soluzione**: Normale al primo build, i successivi saranno più veloci grazie alla cache

---

## 7. Fase 4: Configurazione Cloudflare Worker {#fase-4}

### 7.1 Creazione del Worker JavaScript

Crea un file `worker.js` nella root del progetto:

```javascript
/**
 * Cloudflare Worker per MCP Server
 * 
 * Questo Worker gestisce le richieste e le passa al container MCP
 * Espone l'endpoint /mcp per i client MCP
 */

import { Container } from "@cloudflare/containers";

/**
 * Classe Container per il tuo MCP Server
 * Estende la classe base Container di Cloudflare
 */
export class McpServerContainer extends Container {
  // Porta su cui il container ascolta (deve corrispondere a SERVER_PORT nel Dockerfile)
  defaultPort = 8000;
  
  // Tempo di inattività prima che il container venga messo in sleep
  // 30 minuti di inattività
  sleepAfter = "30m";
  
  // Variabili d'ambiente da passare al container
  envVars = {
    SERVER_PORT: "8000",
    SERVER_HOST: "0.0.0.0",
    GSC_CREDENTIALS_PATH: "/app/credentials.json",
    GSC_SKIP_OAUTH: "true"
  };
}

/**
 * Handler principale del Worker
 * Gestisce tutte le richieste in ingresso
 */
export default {
  /**
   * Fetch handler - punto di ingresso per tutte le richieste HTTP
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Log della richiesta (utile per debugging)
    console.log(`Request to: ${url.pathname}`);
    
    // Gestisci health check
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: 'mcp-server',
        timestamp: new Date().toISOString()
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Gestisci richieste /mcp rimuovendo il prefisso per il container
    // Il container ascolta su / (root)
    try {
      // Ottieni un'istanza del container
      // Usa un ID fisso per avere un singolo container condiviso
      const containerInstance = env.MCP_CONTAINER.getByName("main");
      
      // Rimuovi il prefisso /mcp dal path prima di passare al container
      let containerPath = url.pathname;
      if (containerPath.startsWith('/mcp')) {
        containerPath = containerPath.substring(4) || '/';
      }
      
      console.log(`Original path: ${url.pathname}, Container path: ${containerPath}`);
      
      // Crea una nuova URL con il path modificato
      const containerUrl = new URL(request.url);
      containerUrl.pathname = containerPath;
      
      // Crea una nuova richiesta con la URL modificata
      const containerRequest = new Request(containerUrl, request);
      
      console.log(`Fetching container at: ${containerUrl.toString()}`);
      
      // Passa la richiesta al container
      const response = await containerInstance.fetch(containerRequest);
      
      console.log(`Container response status: ${response.status}`);
      
      // Aggiungi headers CORS se necessario
      const newResponse = new Response(response.body, response);
      newResponse.headers.set('Access-Control-Allow-Origin', '*');
      newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
      newResponse.headers.set('Access-Control-Allow-Headers', 'Content-Type, Accept, Mcp-Session-Id');
      newResponse.headers.set('Access-Control-Expose-Headers', 'Mcp-Session-Id, Content-Type');
      
      // Gestisci preflight OPTIONS requests
      if (request.method === 'OPTIONS') {
        return new Response(null, {
          headers: newResponse.headers
        });
      }
      
      return newResponse;
    } catch (error) {
      console.error('Error communicating with container:', error);
      
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message,
        timestamp: new Date().toISOString()
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
};
```

### 7.2 Note sul Worker

**Punti chiave del Worker:**

1. **Path Mapping**: Il Worker rimuove il prefisso `/mcp` prima di passare la richiesta al container (che ascolta su `/`)

2. **CORS**: Aggiunge automaticamente gli headers CORS necessari per permettere ai client MCP di connettersi da qualsiasi origine

3. **Health Check**: Fornisce un endpoint `/health` per verificare che il Worker sia attivo

4. **Session Routing**: Usa `getByName("main")` per garantire che tutte le richieste vadano allo stesso container (importante per sessioni stateful)

5. **Error Handling**: Cattura errori e restituisce risposte JSON strutturate

---

## 8. Fase 5: Deployment su Cloudflare {#fase-5}

### 8.1 Configurazione Wrangler

Crea un file `wrangler.jsonc` nella root del progetto:

```jsonc
{
  "name": "mcp-server-tuonome",
  "main": "worker.js",
  "compatibility_date": "2025-01-01",
  
  // IMPORTANTE: Sostituisci con il tuo account ID Cloudflare
  // Lo trovi in: Dashboard Cloudflare > Workers & Pages > Overview
  "account_id": "TUO_ACCOUNT_ID_QUI",
  
  // Configurazione container
  "containers": [
    {
      "class_name": "McpServerContainer",
      "image": "./Dockerfile",
      "max_instances": 1  // Inizia con 1, aumenta se necessario
    }
  ],
  
  // Durable Objects per gestione stato
  "durable_objects": {
    "bindings": [
      {
        "class_name": "McpServerContainer",
        "name": "MCP_CONTAINER"
      }
    ]
  },
  
  // Migrations per Durable Objects
  "migrations": [
    {
      "tag": "v1",
      "new_sqlite_classes": ["McpServerContainer"]
    }
  ],
  
  // Variabili globali (opzionali)
  "vars": {
    "ENVIRONMENT": "production"
  }
}
```

**Come trovare il tuo Account ID:**

1. Vai su [dash.cloudflare.com](https://dash.cloudflare.com)
2. Clicca su "Workers & Pages" nel menu laterale
3. L'Account ID è visibile nell'URL: `dash.cloudflare.com/<ACCOUNT_ID>/...`
4. Oppure: Workers & Pages > Overview > nella sidebar destra

### 8.2 Configurazione package.json

Crea un file `package.json`:

```json
{
  "name": "mcp-server",
  "version": "1.0.0",
  "description": "MCP Server deployato su Cloudflare Containers",
  "main": "worker.js",
  "scripts": {
    "deploy": "wrangler deploy",
    "dev": "wrangler dev",
    "tail": "wrangler tail",
    "list": "wrangler containers list",
    "images": "wrangler containers images list"
  },
  "keywords": ["mcp", "cloudflare", "containers"],
  "author": "tuo-nome",
  "license": "MIT",
  "devDependencies": {
    "wrangler": "^3.90.0"
  },
  "dependencies": {
    "@cloudflare/workers-types": "^4.20241127.0"
  }
}
```

### 8.3 Installazione Dipendenze npm

```bash
# Installa Wrangler e dipendenze
npm install

# Output atteso:
# added XX packages, and audited YY packages in Zs
# found 0 vulnerabilities
```

### 8.4 Login a Cloudflare

```bash
# Login a Cloudflare (apre il browser)
npx wrangler login

# Output atteso:
# Attempting to login via OAuth...
# Successfully logged in.
```

### 8.5 Deploy del Server

```bash
# Deploy completo (build Docker + deploy Worker)
npm run deploy

# Output atteso (LUNGO, può richiedere 5-10 minuti):
# ⛅️ wrangler 3.90.0
# -------------------
# Building Docker image...
# [+] Building 120.5s (14/14) FINISHED
# Pushing image to Cloudflare Container Registry...
# Uploading Worker code...
# Creating Durable Objects...
# Deploying Worker...
# ✨ Deployment complete!
# https://mcp-server-tuonome.your-subdomain.workers.dev
```

**IMPORTANTE**: Il primo deploy richiede molto tempo perché:
1. Docker deve buildare l'immagine Python (1-3 minuti)
2. L'immagine viene pushata su Cloudflare (2-5 minuti)
3. Il container viene distribuito globalmente (1-3 minuti)
4. I Durable Objects vengono creati (1 minuto)

### 8.6 Verifica del Deployment

```bash
# 1. Lista i containers deployati
npm run list

# Output atteso:
# Container ID: abc123...
# Status: active
# Created: 2025-01-01T12:00:00Z

# 2. Verifica l'URL del Worker
# Trovi l'URL nell'output del deploy oppure in:
# Dashboard Cloudflare > Workers & Pages > mcp-server-tuonome

# 3. Test health check
curl https://mcp-server-tuonome.your-subdomain.workers.dev/health

# Output atteso:
# {"status":"ok","service":"mcp-server","timestamp":"2025-01-01T12:00:00.000Z"}
```

### 8.7 Attesa Prima del Primo Utilizzo

**⚠️ IMPORTANTE**: Dopo il primo deploy, attendi **5-10 minuti** prima di testare l'endpoint `/mcp`.

Durante questo periodo:
- Il container viene avviato per la prima volta
- Le dipendenze Python vengono caricate
- Il server MCP si inizializza
- La distribuzione globale viene completata

```bash
# Monitora i log in tempo reale
npm run tail

# Vedrai:
# - Richieste al Worker
# - Avvio del container
# - Log del server Python
# - Eventuali errori
```

---

## 9. Fase 6: Test e Verifica {#fase-6}

### 9.1 Test dell'Endpoint MCP

```bash
# Test base (deve rispondere, anche con un errore MCP va bene)
curl https://mcp-server-tuonome.your-subdomain.workers.dev/mcp

# Test con headers MCP
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  https://mcp-server-tuonome.your-subdomain.workers.dev/mcp

# Se ricevi un JSON (anche un errore), il server funziona!
```

### 9.2 Configurazione Client MCP

#### Per Claude Desktop

Modifica il file di configurazione:

**Mac**: `~/Library/Application Support/Claude/claude_desktop_config.json`  
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "tuo-mcp-server": {
      "url": "https://mcp-server-tuonome.your-subdomain.workers.dev/mcp",
      "transport": "streamable-http"
    }
  }
}
```

#### Per Cursor

File di configurazione Cursor (vedi progetto GSC come riferimento):

```json
{
  "mcpServers": {
    "tuo-mcp-server": {
      "url": "https://mcp-server-tuonome.your-subdomain.workers.dev/mcp",
      "transport": "streamable-http"
    }
  }
}
```

### 9.3 Test con il Client

1. **Riavvia il client** (Claude Desktop o Cursor)
2. **Verifica la connessione**: Il client dovrebbe mostrare il server nella lista dei servers connessi
3. **Lista i tools**: Chiedi al client "list available tools" o "quali tools hai?"
4. **Prova un tool**: Esegui uno dei tuoi tools MCP

### 9.4 Monitoring

```bash
# Visualizza log in tempo reale
npm run tail

# Output:
# GET https://...workers.dev/mcp - Status: 200 - Duration: 145ms
# POST https://...workers.dev/mcp - Status: 200 - Duration: 523ms
# [Container] Starting MCP server...
# [Container] Tool executed: nome_tool
```

### 9.5 Dashboard Cloudflare

Puoi monitorare il deployment anche da:

1. **Workers Dashboard**: [dash.cloudflare.com](https://dash.cloudflare.com) > Workers & Pages
2. **Analytics**: Vedi richieste, errori, latenza
3. **Logs**: Stream dei log in tempo reale
4. **Container Instances**: Stato e salute dei container

---

## 10. Troubleshooting Comune {#troubleshooting}

### 10.1 Errore: "Cannot connect to Docker daemon"

**Causa**: Docker Desktop non è in esecuzione

**Soluzione**:
```bash
# Avvia Docker Desktop, poi verifica:
docker info

# Dovrebbe mostrare info sul sistema Docker
```

### 10.2 Errore: "Container not ready" o timeout 524

**Causa**: Il container sta ancora avviandosi (specialmente al primo deploy)

**Soluzione**:
- Attendi 5-10 minuti dopo il deploy
- Monitora i log: `npm run tail`
- Verifica che il container sia attivo: `npm run list`

### 10.3 Errore: "Credentials not found" nei log

**Causa**: Il file `credentials.json` non è stato copiato correttamente nel container

**Soluzione**:
1. Verifica che `credentials.json` esista nella directory di build
2. Controlla che il Dockerfile includa: `COPY credentials.json /app/credentials.json`
3. Controlla che `.dockerignore` NON escluda `credentials.json`
4. Ri-builda e re-deploya

### 10.4 Errore 500 dal server

**Causa**: Errore nel codice Python o nelle API Google

**Soluzione**:
```bash
# Visualizza i log dettagliati
npm run tail

# Cerca la traccia dell'errore Python
# Esempio:
# [Container] Traceback (most recent call last):
# [Container]   File "/app/server.py", line 123, in tool_function
# [Container] Exception: ...

# Fix l'errore nel codice, poi re-deploya
npm run deploy
```

### 10.5 Il client non si connette

**Causa**: Configurazione client errata o server non risponde

**Soluzione**:
1. Verifica l'URL: `https://...workers.dev/mcp` (nota il suffisso `/mcp`)
2. Testa con curl: `curl https://...workers.dev/health`
3. Verifica che `transport: "streamable-http"` sia nel config del client
4. Riavvia il client dopo modifiche al config
5. Controlla i log del Worker: `npm run tail`

### 10.6 Errore: "Account ID not found"

**Causa**: `account_id` non configurato in `wrangler.jsonc`

**Soluzione**:
1. Vai su [dash.cloudflare.com](https://dash.cloudflare.com)
2. Workers & Pages > Overview
3. Copia l'Account ID dalla sidebar
4. Aggiorna `wrangler.jsonc`:
   ```jsonc
   "account_id": "IL_TUO_ACCOUNT_ID_QUI"
   ```

### 10.7 Deploy lentissimo

**Causa**: Normale al primo deploy, Docker deve buildare tutto

**Ottimizzazione**:
- Usa immagini base più leggere nel Dockerfile
- Rimuovi dipendenze non necessarie da `requirements.txt`
- I deploy successivi saranno molto più veloci (cache Docker)

### 10.8 Errore: "Plan not supported"

**Causa**: Cloudflare Containers richiede piano Workers Paid

**Soluzione**:
1. Vai su [dash.cloudflare.com](https://dash.cloudflare.com) > Workers & Pages
2. Upgrade al piano Workers Paid (circa $5/mese)
3. Riprova il deploy

---

## 11. Appendice: Esempi Completi {#appendice}

### 11.1 Esempio Completo: Server Python

File: `server.py`

```python
"""
MCP Server con HTTP-Streamable transport
Migrando da stdio a HTTP per deployment su Cloudflare
"""

import os
from typing import Any, Optional
from mcp.server.fastmcp import FastMCP

# Se usi Google APIs
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Inizializza FastMCP
mcp = FastMCP("nome-tuo-server")

# ===== GESTIONE CREDENZIALI GOOGLE =====
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
POSSIBLE_CREDENTIAL_PATHS = [
    os.environ.get("GSC_CREDENTIALS_PATH"),
    "/app/credentials.json",  # Container Cloudflare
    os.path.join(SCRIPT_DIR, "credentials.json"),  # Locale
]

def get_google_service(api_name: str, api_version: str, scopes: list):
    """Carica credenziali Google service account."""
    for cred_path in POSSIBLE_CREDENTIAL_PATHS:
        if cred_path and os.path.exists(cred_path):
            try:
                creds = service_account.Credentials.from_service_account_file(
                    cred_path, scopes=scopes
                )
                return build(api_name, api_version, credentials=creds)
            except Exception as e:
                continue
    
    raise FileNotFoundError("Google credentials not found")

# ===== TOOLS MCP =====

@mcp.tool()
async def esempio_tool(parametro: str) -> str:
    """
    Tool di esempio che fa qualcosa.
    
    Args:
        parametro: Descrizione del parametro
    """
    try:
        # Logica del tool
        result = f"Elaborato: {parametro}"
        return result
    except Exception as e:
        return f"Errore: {str(e)}"

@mcp.tool()
async def esempio_google_api() -> str:
    """
    Tool che usa Google API (es. Search Console).
    """
    try:
        SCOPES = ["https://www.googleapis.com/auth/webmasters"]
        service = get_google_service("searchconsole", "v1", SCOPES)
        
        # Esempio: lista proprietà
        sites = service.sites().list().execute()
        
        # Formatta risultato
        if not sites.get("siteEntry"):
            return "Nessuna proprietà trovata"
        
        result_lines = ["Proprietà Search Console:"]
        for site in sites.get("siteEntry", []):
            result_lines.append(f"- {site.get('siteUrl')}")
        
        return "\n".join(result_lines)
    except Exception as e:
        return f"Errore: {str(e)}"

# Aggiungi altri tools...

# ===== AVVIO SERVER =====

if __name__ == "__main__":
    import uvicorn
    
    # Config da variabili d'ambiente
    port = int(os.environ.get("SERVER_PORT", "8000"))
    host = os.environ.get("SERVER_HOST", "0.0.0.0")
    
    print(f"Starting MCP server on {host}:{port}")
    print(f"Access the server at: http://{host}:{port}/mcp")
    
    # Configura l'app HTTP-streamable
    mcp.settings.streamable_http_path = "/"
    app = mcp.streamable_http_app()
    
    # Avvia uvicorn
    uvicorn.run(app, host=host, port=port, log_level="info")
```

### 11.2 Esempio Completo: Dockerfile

File: `Dockerfile`

```dockerfile
FROM python:3.11-slim

LABEL maintainer="tuo@email.com"
LABEL description="MCP Server HTTP-Streamable"

# Dipendenze di sistema
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dipendenze Python
COPY requirements.txt /app/
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Codice server
COPY server.py /app/

# Credenziali Google
COPY credentials.json /app/

# Variabili d'ambiente
ENV SERVER_PORT=8000
ENV SERVER_HOST=0.0.0.0
ENV GSC_CREDENTIALS_PATH=/app/credentials.json
ENV GSC_SKIP_OAUTH=true
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

CMD ["python", "server.py"]
```

### 11.3 Esempio Completo: requirements.txt

File: `requirements.txt`

```txt
# MCP SDK
mcp[cli]>=1.3.0

# ASGI Server
uvicorn>=0.30.0
starlette>=0.37.0

# Google APIs (se necessario)
google-api-python-client>=2.163.0
google-auth-httplib2>=0.2.0
google-auth-oauthlib>=1.2.1

# Altre dipendenze specifiche del tuo progetto
# aggiungi qui le tue dipendenze...
```

### 11.4 Esempio Completo: worker.js

File: `worker.js`

```javascript
import { Container } from "@cloudflare/containers";

export class McpServerContainer extends Container {
  defaultPort = 8000;
  sleepAfter = "30m";
  envVars = {
    SERVER_PORT: "8000",
    SERVER_HOST: "0.0.0.0",
    GSC_CREDENTIALS_PATH: "/app/credentials.json",
    GSC_SKIP_OAUTH: "true"
  };
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    console.log(`Request to: ${url.pathname}`);
    
    // Health check
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: 'mcp-server',
        timestamp: new Date().toISOString()
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    try {
      const containerInstance = env.MCP_CONTAINER.getByName("main");
      
      // Path mapping: /mcp → /
      let containerPath = url.pathname;
      if (containerPath.startsWith('/mcp')) {
        containerPath = containerPath.substring(4) || '/';
      }
      
      const containerUrl = new URL(request.url);
      containerUrl.pathname = containerPath;
      
      const containerRequest = new Request(containerUrl, request);
      const response = await containerInstance.fetch(containerRequest);
      
      // CORS
      const newResponse = new Response(response.body, response);
      newResponse.headers.set('Access-Control-Allow-Origin', '*');
      newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
      newResponse.headers.set('Access-Control-Allow-Headers', 'Content-Type, Accept, Mcp-Session-Id');
      newResponse.headers.set('Access-Control-Expose-Headers', 'Mcp-Session-Id, Content-Type');
      
      if (request.method === 'OPTIONS') {
        return new Response(null, { headers: newResponse.headers });
      }
      
      return newResponse;
    } catch (error) {
      console.error('Error:', error);
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message,
        timestamp: new Date().toISOString()
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
};
```

### 11.5 Esempio Completo: wrangler.jsonc

File: `wrangler.jsonc`

```jsonc
{
  "name": "mcp-server-tuonome",
  "main": "worker.js",
  "compatibility_date": "2025-01-01",
  "account_id": "TUO_ACCOUNT_ID",
  
  "containers": [
    {
      "class_name": "McpServerContainer",
      "image": "./Dockerfile",
      "max_instances": 1
    }
  ],
  
  "durable_objects": {
    "bindings": [
      {
        "class_name": "McpServerContainer",
        "name": "MCP_CONTAINER"
      }
    ]
  },
  
  "migrations": [
    {
      "tag": "v1",
      "new_sqlite_classes": ["McpServerContainer"]
    }
  ],
  
  "vars": {
    "ENVIRONMENT": "production"
  }
}
```

### 11.6 Esempio Completo: package.json

File: `package.json`

```json
{
  "name": "mcp-server",
  "version": "1.0.0",
  "description": "MCP Server su Cloudflare Containers",
  "main": "worker.js",
  "scripts": {
    "deploy": "wrangler deploy",
    "dev": "wrangler dev",
    "tail": "wrangler tail",
    "list": "wrangler containers list",
    "images": "wrangler containers images list"
  },
  "devDependencies": {
    "wrangler": "^3.90.0"
  },
  "dependencies": {
    "@cloudflare/workers-types": "^4.20241127.0"
  }
}
```

### 11.7 Checklist Completa Pre-Deploy

Prima di fare il deploy, verifica:

```bash
# ✅ File necessari presenti
ls -la
# Dovresti vedere:
# - server.py (o nome del tuo server)
# - Dockerfile
# - worker.js
# - wrangler.jsonc
# - package.json
# - requirements.txt
# - credentials.json
# - .dockerignore

# ✅ Docker funzionante
docker info

# ✅ Dipendenze npm installate
npm install

# ✅ Login a Cloudflare fatto
npx wrangler whoami

# ✅ Account ID configurato
grep account_id wrangler.jsonc

# ✅ Build locale del container OK
docker build -t test:latest .

# ✅ Test locale del container
docker run -p 8000:8000 test:latest
# In altro terminale:
curl http://localhost:8000/

# Se tutti i check passano, sei pronto per:
npm run deploy
```

---

## 12. Riferimenti e Risorse

### Documentazione Ufficiale

- **MCP Protocol**: https://modelcontextprotocol.io/
- **FastMCP**: https://github.com/jlowin/fastmcp
- **Cloudflare Containers**: https://developers.cloudflare.com/containers/
- **Wrangler CLI**: https://developers.cloudflare.com/workers/wrangler/
- **Docker**: https://docs.docker.com/

### Progetto di Riferimento

- **mcp-gsc-http**: `/Users/alessandrobisi/Progetti/__mcps__/mcp-gsc-http/`
- **GitHub**: (link al repo se pubblico)

### Supporto

- **Cloudflare Community**: https://community.cloudflare.com/
- **MCP Discord**: (se esiste)
- **Docker Forum**: https://forums.docker.com/

---

## 13. Note Finali per Agente AI

### Approccio Consigliato alla Migrazione

1. **Analisi del Progetto Esistente**
   - Identifica tutti i tools MCP
   - Verifica le dipendenze Python
   - Controlla se usa Google APIs o altre API esterne

2. **Modifica Minima del Codice**
   - Cambia solo il blocco `if __name__ == "__main__"`
   - Mantieni invariata tutta la logica di business
   - Non modificare le signature dei tools

3. **Test Incrementale**
   - Prima testa localmente con HTTP
   - Poi testa il container Docker localmente
   - Infine deploya su Cloudflare

4. **Monitoring Continuo**
   - Usa `npm run tail` durante i test
   - Verifica i log per eventuali errori
   - Testa ogni tool dopo il deploy

### Pattern Comuni da Seguire

- **Gestione Credenziali**: Usa sempre la ricerca multi-path come nel progetto GSC
- **Variabili d'Ambiente**: Configura tutto tramite env vars, non hardcoding
- **Error Handling**: Cattura sempre le eccezioni nei tools e restituisci messaggi chiari
- **Logging**: Usa `print()` per log semplici, visibili con `npm run tail`

### Errori da Evitare

❌ **Non modificare** la logica dei tools esistenti  
❌ **Non rimuovere** le dipendenze dal requirements.txt  
❌ **Non cambiare** le signature dei tools (argomenti, tipi, nomi)  
❌ **Non dimenticare** di copiare credentials.json nel Dockerfile  
❌ **Non usare** path assoluti nel codice (usa variabili d'ambiente)  

### Successo della Migrazione

La migrazione è completa quando:

✅ Il server risponde su `https://...workers.dev/health`  
✅ Il server risponde su `https://...workers.dev/mcp`  
✅ Il client MCP si connette con successo  
✅ Tutti i tools sono elencati nel client  
✅ Ogni tool funziona correttamente quando chiamato  
✅ Non ci sono errori nei log (`npm run tail`)  

---

**Fine della Guida**

Questa guida è stata creata appositamente per un agente AI e contiene tutti i dettagli necessari per migrare con successo un server MCP da stdio a HTTP-streamable con deployment su Cloudflare Containers, utilizzando come riferimento il progetto mcp-gsc-http.

Per domande o problemi durante la migrazione, consulta la sezione [Troubleshooting](#troubleshooting) o i log del deployment.

Buona migrazione! 🚀

