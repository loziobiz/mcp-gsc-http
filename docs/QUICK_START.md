# Quick Start - MCP-GSC HTTP Server

Guida rapida per avviare il server MCP-GSC HTTP con il tuo service account Google.

## 🚀 Avvio in 3 Passi

### 1️⃣ Installa le Dipendenze

```bash
cd /Users/alessandrobisi/Progetti/__mcps__/mcp-gsc-http

# Crea virtual environment (se non esiste)
python -m venv .venv

# Attiva virtual environment
source .venv/bin/activate

# Installa dipendenze
pip install -r requirements.txt
```

### 2️⃣ Avvia il Server con le Credenziali

Usa lo script personalizzato che include automaticamente le tue credenziali:

```bash
./start_with_credentials.sh
```

**Output atteso:**
```
=== MCP-GSC HTTP Server con Service Account ===

🔄 Attivazione virtual environment...

🔑 Configurazione Google Service Account:
   Credentials: /Users/alessandrobisi/Progetti/kf-seshat-crewai/ga4_analyst/keys/gcp_service_account.json
   Skip OAuth: true

📡 Configurazione server:
   Host: 0.0.0.0
   Porta: 8000
   URL: http://0.0.0.0:8000/mcp

🚀 Avvio del server...

Starting MCP-GSC server on 0.0.0.0:8000
Access the server at: http://0.0.0.0:8000/mcp
```

### 3️⃣ Configura Cursor

Aggiungi al tuo `/Users/alessandrobisi/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "gsc-http": {
      "url": "http://localhost:8000/mcp",
      "transport": "streamable-http",
      "description": "Google Search Console MCP Server (HTTP - con Service Account)"
    }
  }
}
```

**Esempio completo** (aggiungi dopo "chrome-devtools"):

```json
{
  "mcpServers": {
    // ... altri server ...
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "chrome-devtools-mcp@latest",
        "--channel=stable",
        "--headless=false",
        "--isolated=true"
      ],
      "disabled": true
    },
    "gsc-http": {
      "url": "http://localhost:8000/mcp",
      "transport": "streamable-http",
      "description": "Google Search Console MCP Server (HTTP - con Service Account)"
    }
  }
}
```

## ✅ Verifica Funzionamento

### Test 1: Server risponde

```bash
# In un nuovo terminale
curl http://localhost:8000/mcp
```

Dovresti ricevere una risposta dal server MCP.

### Test 2: Connessione da Cursor

1. Riavvia Cursor
2. Apri un progetto
3. Apri la chat AI
4. Verifica che il server "gsc-http" sia disponibile
5. Prova un comando: "List my Google Search Console properties"

## 🔧 Opzioni Alternative di Avvio

### Opzione A: Con variabili d'ambiente inline

```bash
GSC_CREDENTIALS_PATH="/Users/alessandrobisi/Progetti/kf-seshat-crewai/ga4_analyst/keys/gcp_service_account.json" \
GSC_SKIP_OAUTH="true" \
python gsc_server.py
```

### Opzione B: Con export

```bash
export GSC_CREDENTIALS_PATH="/Users/alessandrobisi/Progetti/kf-seshat-crewai/ga4_analyst/keys/gcp_service_account.json"
export GSC_SKIP_OAUTH="true"
python gsc_server.py
```

### Opzione C: Porta personalizzata

```bash
export GSC_PORT=3000
./start_with_credentials.sh
```

Poi in Cursor usa:
```json
"url": "http://localhost:3000/mcp"
```

## 🐛 Troubleshooting

### Errore: "No module named 'mcp'"

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

### Errore: "Credentials file not found"

Verifica che il percorso sia corretto:
```bash
ls -la /Users/alessandrobisi/Progetti/kf-seshat-crewai/ga4_analyst/keys/gcp_service_account.json
```

### Errore: "Address already in use"

La porta 8000 è occupata. Usa una porta diversa:
```bash
export GSC_PORT=8001
./start_with_credentials.sh
```

### Server si avvia ma Cursor non si connette

1. Verifica che il server sia in esecuzione
2. Controlla l'URL in mcp.json
3. Riavvia Cursor completamente
4. Controlla i log del server per errori

## 📊 Comandi Utili

### Verifica Service Account

Il tuo service account configurato:
- **Email**: `ga4-mcp-runner@augmented-humanuty.iam.gserviceaccount.com`
- **Project**: `augmented-humanuty`

**Importante**: Assicurati che questo service account abbia accesso alle proprietà GSC che vuoi interrogare:

1. Vai su [Google Search Console](https://search.google.com/search-console/)
2. Seleziona una proprietà
3. Vai su Impostazioni → Utenti e autorizzazioni
4. Aggiungi `ga4-mcp-runner@augmented-humanuty.iam.gserviceaccount.com` come utente

### Tool Disponibili

Una volta connesso, puoi usare questi tool:

```
- list_properties                # Lista tutte le tue proprietà GSC
- get_search_analytics           # Ottieni analytics di ricerca
- get_performance_overview       # Overview delle performance
- inspect_url_enhanced           # Ispeziona URL specifici
- get_sitemaps                   # Lista sitemap
- submit_sitemap                 # Invia sitemap
... e altri 13 tool!
```

## 🔄 Aggiornamenti

Per aggiornare il server in futuro:

```bash
cd /Users/alessandrobisi/Progetti/__mcps__/mcp-gsc-http
git pull  # se usi git
source .venv/bin/activate
pip install -r requirements.txt --upgrade
```

## 📚 Documentazione Completa

- **HTTP_SETUP_GUIDE.md** - Guida completa setup HTTP
- **CLIENT_EXAMPLES.md** - Esempi configurazione client
- **README.md** - Documentazione generale
- **CHANGELOG.md** - Modifiche recenti

## 💡 Tips

1. **Mantieni il server in esecuzione**: Lascia il terminale aperto con il server in esecuzione mentre usi Cursor
2. **Log utili**: Il server mostra i log delle richieste, utili per debug
3. **Riavvio veloce**: Se modifichi qualcosa, CTRL+C e poi `./start_with_credentials.sh` di nuovo
4. **Background**: Per eseguire in background: `./start_with_credentials.sh &`

## 🎯 Next Steps

Dopo aver verificato che funziona:

1. ✅ Puoi disabilitare il vecchio server stdio in mcp.json (riga 3-11)
2. ✅ Considera di deployare su un server remoto per accesso sempre disponibile
3. ✅ Esplora tutti i 19 tool disponibili!

