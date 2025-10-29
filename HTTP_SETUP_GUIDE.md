# Guida HTTP Streamable per MCP-GSC

Questa guida spiega come utilizzare il server MCP-GSC con transport HTTP streamable moderno di MCP per l'accesso remoto.

## 🚀 Avvio Rapido

### 1. Installazione Dipendenze

```bash
# Crea e attiva il virtual environment
python -m venv .venv
source .venv/bin/activate  # Mac/Linux
# oppure
.venv\Scripts\activate  # Windows

# Installa le dipendenze
pip install -r requirements.txt
```

### 2. Configurazione Credenziali Google

Segui le istruzioni nel README.md principale per configurare le credenziali Google Search Console (OAuth o Service Account).

### 3. Avvio del Server

#### Metodo 1: Script automatico

**Linux/Mac:**
```bash
./start_server.sh
```

**Windows:**
```cmd
start_server.bat
```

#### Metodo 2: Manuale

```bash
# Attiva il virtual environment
source .venv/bin/activate  # Mac/Linux
.venv\Scripts\activate  # Windows

# Avvia il server
python gsc_server.py
```

Il server sarà disponibile su: `http://0.0.0.0:8000/mcp`

## ⚙️ Configurazione Personalizzata

### Variabili d'Ambiente

Puoi personalizzare il comportamento del server tramite variabili d'ambiente:

```bash
# Porta del server (default: 8000)
export GSC_PORT=3000

# Host del server (default: 0.0.0.0)
# 0.0.0.0 = accessibile da qualsiasi interfaccia
# 127.0.0.1 = solo accesso locale
export GSC_HOST=127.0.0.1

# Credenziali Google Search Console
export GSC_CREDENTIALS_PATH=/path/to/service_account.json
export GSC_OAUTH_CLIENT_SECRETS_FILE=/path/to/client_secrets.json
export GSC_SKIP_OAUTH=false

# Avvia il server
python gsc_server.py
```

### Esempi di Configurazione

#### 1. Server Locale (Solo localhost)

```bash
export GSC_HOST=127.0.0.1
export GSC_PORT=8000
python gsc_server.py
```
**URL**: `http://127.0.0.1:8000/mcp`

#### 2. Server Remoto (Accessibile dalla rete)

```bash
export GSC_HOST=0.0.0.0
export GSC_PORT=8000
python gsc_server.py
```
**URL**: `http://YOUR_SERVER_IP:8000/mcp`

#### 3. Server su Porta Personalizzata

```bash
export GSC_HOST=0.0.0.0
export GSC_PORT=3000
python gsc_server.py
```
**URL**: `http://YOUR_SERVER_IP:3000/mcp`

## 🔌 Connessione Client

### Configurazione MCP Client

Per connettere un client MCP al server HTTP, usa questa configurazione:

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://YOUR_SERVER_IP:8000/mcp"
    }
  }
}
```

### Esempi per Client Specifici

#### Claude Desktop (con server remoto)

Modifica il file di configurazione di Claude Desktop:
- **Mac**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://your-server-ip:8000/mcp"
    }
  }
}
```

#### Cursor IDE

Aggiungi al file `.cursorrules` o alla configurazione MCP:

```json
{
  "mcpServers": {
    "gscServer": {
      "url": "http://localhost:8000/mcp"
    }
  }
}
```

## 🔒 Sicurezza

**IMPORTANTE**: La configurazione attuale **NON** include autenticazione/autorizzazione. 

### Raccomandazioni di Sicurezza

1. **Firewall**: Limita l'accesso agli IP noti
   ```bash
   # Esempio con iptables (Linux)
   sudo iptables -A INPUT -p tcp --dport 8000 -s 192.168.1.0/24 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 8000 -j DROP
   ```

2. **Reverse Proxy**: Usa nginx o Apache con autenticazione
   ```nginx
   # Esempio nginx con basic auth
   location /mcp {
       auth_basic "Restricted Access";
       auth_basic_user_file /etc/nginx/.htpasswd;
       proxy_pass http://127.0.0.1:8000/mcp;
   }
   ```

3. **VPN**: Esponi il server solo tramite VPN privata

4. **SSH Tunnel**: Accesso sicuro via tunneling SSH
   ```bash
   ssh -L 8000:localhost:8000 user@remote-server
   ```

## 🐳 Deploy con Docker (Opzionale)

Esempio di Dockerfile per containerizzare il server:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY gsc_server.py .

# Variabili d'ambiente di default
ENV GSC_HOST=0.0.0.0
ENV GSC_PORT=8000

EXPOSE 8000

CMD ["python", "gsc_server.py"]
```

Build e run:
```bash
# Build
docker build -t mcp-gsc-http .

# Run con credenziali montate
docker run -d \
  -p 8000:8000 \
  -v /path/to/credentials.json:/app/credentials.json \
  -e GSC_CREDENTIALS_PATH=/app/credentials.json \
  mcp-gsc-http
```

## 📊 Monitoring e Logging

Il server mostra informazioni di avvio sulla console:

```
Starting MCP-GSC server on 0.0.0.0:8000
Access the server at: http://0.0.0.0:8000/mcp
```

Per logging più dettagliato, considera di redirigere l'output:

```bash
python gsc_server.py 2>&1 | tee server.log
```

## 🔧 Troubleshooting

### Errore: "Address already in use"

La porta è già occupata. Cambia porta:
```bash
export GSC_PORT=8001
python gsc_server.py
```

### Errore: "Permission denied" (porta < 1024)

Le porte sotto 1024 richiedono privilegi root. Usa una porta >= 1024 o esegui come root (sconsigliato).

### Client non si connette

1. Verifica che il server sia in esecuzione
2. Controlla firewall locale e di rete
3. Verifica che l'URL nel client sia corretto
4. Controlla i log del server per errori

### Credenziali Google non funzionano

1. Verifica che il percorso alle credenziali sia corretto
2. Controlla che le variabili d'ambiente siano impostate
3. Verifica i permessi del file delle credenziali
4. Consulta i log per errori di autenticazione

## 🔄 Ritorno a STDIO Mode

Se preferisci tornare al trasporto stdio tradizionale per uso locale:

1. Modifica `gsc_server.py`, ultima riga:
   ```python
   # Da:
   mcp.run(transport="streamable-http", port=port, host=host)
   
   # A:
   mcp.run(transport="stdio")
   ```

2. Configura Claude Desktop come descritto nel README principale

## 📚 Risorse Aggiuntive

- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [FastMCP Documentation](https://github.com/jlowin/fastmcp)
- [Google Search Console API](https://developers.google.com/webmaster-tools/search-console-api-original)

## 🆘 Supporto

Per problemi o domande:
1. Consulta questa guida e il README principale
2. Controlla i log del server
3. Verifica le configurazioni di rete e firewall
4. Apri una issue su GitHub se il problema persiste

