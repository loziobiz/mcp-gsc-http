# 🌐 Guida alla Connessione al Server MCP-GSC su Cloudflare

## ✅ Deployment Completato!

Il tuo server MCP-GSC è stato deployato con successo su Cloudflare Containers.

### 📍 Dettagli del Server

- **URL del Worker**: `https://mcp-gsc-server.kf-api.workers.dev`
- **Endpoint MCP**: `https://mcp-gsc-server.kf-api.workers.dev/mcp`
- **Version ID**: `05dc838f-f13b-4d5b-86c3-215632e4cf8a`
- **Application ID**: `a03a9e57-b6a5-4cb3-acea-a2c59d1fe585`
- **Account**: Operations@keyformat.com

---

## 🔧 Configurazione Client

### 1️⃣ **Cursor IDE**

Aggiungi questa configurazione al tuo file `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "gsc-http-cloudflare": {
      "command": "node",
      "args": [],
      "url": "https://mcp-gsc-server.kf-api.workers.dev/mcp",
      "transport": "streamable-http"
    }
  }
}
```

**Oppure** (configurazione alternativa senza `command` e `args`):

```json
{
  "mcpServers": {
    "gsc-http-cloudflare": {
      "url": "https://mcp-gsc-server.kf-api.workers.dev/mcp",
      "transport": "streamable-http"
    }
  }
}
```

### 2️⃣ **Claude Desktop**

Aggiungi al file `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "gsc-http-cloudflare": {
      "url": "https://mcp-gsc-server.kf-api.workers.dev/mcp",
      "transport": "streamable-http"
    }
  }
}
```

### 3️⃣ **Test con curl**

```bash
# Test base (riceverai un errore sui Content-Type, è normale)
curl -X GET https://mcp-gsc-server.kf-api.workers.dev/mcp

# Test con header corretti
curl -X POST https://mcp-gsc-server.kf-api.workers.dev/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": "test-1",
    "method": "tools/list",
    "params": {}
  }'
```

---

## 🛠️ Gestione del Server

### Visualizzare i Log

```bash
npx wrangler tail mcp-gsc-server
```

### Aggiornare il Server

Dopo aver modificato il codice:

```bash
npx wrangler deploy
```

### Rimuovere il Deployment

```bash
npx wrangler delete mcp-gsc-server
```

### Visualizzare le Informazioni del Container

```bash
npx wrangler containers list
```

---

## 📊 Dashboard Cloudflare

Puoi monitorare il server direttamente dal dashboard:

1. Vai su: [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Seleziona l'account **Operations@keyformat.com**
3. Vai su **Workers & Pages**
4. Clicca su **mcp-gsc-server**

---

## 🔐 Sicurezza

⚠️ **IMPORTANTE**: Il server è attualmente **pubblico** e **non ha autenticazione**.

Per aggiungere autenticazione, considera:

1. **Cloudflare Access**: Aggiungi una policy di accesso basata su email/IP
2. **API Key**: Modifica il `worker.js` per verificare un header `X-API-Key`
3. **Zero Trust**: Usa Cloudflare Tunnel per accesso privato

Esempio di autenticazione con API Key nel `worker.js`:

```javascript
export default {
  async fetch(request, env) {
    const apiKey = request.headers.get("X-API-Key");
    if (apiKey !== env.API_KEY) {
      return new Response("Unauthorized", { status: 401 });
    }
    
    // ... resto del codice
  }
}
```

---

## 🐛 Troubleshooting

### Errore: "Not Acceptable: Client must accept text/event-stream"

✅ **Normale!** Il server funziona correttamente. I client MCP invieranno automaticamente gli header corretti.

### Container non si avvia

```bash
# Verifica i log
npx wrangler tail mcp-gsc-server

# Ricostruisci il container
docker build -t test-mcp-gsc .
docker run -p 8000:8000 test-mcp-gsc
```

### Credenziali GSC non funzionanti

Verifica che:
1. Il file `credentials.json` contenga le credenziali corrette
2. Il service account abbia accesso alle proprietà GSC
3. Le API Google Search Console siano abilitate nel progetto GCP

---

## 📚 Risorse Utili

- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Cloudflare Containers Docs](https://developers.cloudflare.com/containers/)
- [MCP Protocol Docs](https://modelcontextprotocol.io/)
- [Google Search Console API](https://developers.google.com/webmaster-tools/search-console-api-original)

---

## 🎯 Prossimi Passi

1. **Testa la connessione** da Cursor o Claude Desktop
2. **Aggiungi autenticazione** per sicurezza
3. **Monitora l'utilizzo** dal dashboard Cloudflare
4. **Configura alerting** per eventuali errori

---

**✨ Fatto!** Il tuo server MCP-GSC è ora disponibile globalmente su Cloudflare Edge Network!

