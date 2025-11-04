# Guida Deployment su Cloudflare Containers

Questa guida spiega come deployare il server MCP-GSC su Cloudflare Containers.

## 📋 Prerequisiti

1. **Account Cloudflare** con piano Workers Paid (necessario per Containers Beta)
2. **Docker** installato e in esecuzione localmente
3. **Node.js e npm** installati
4. **Wrangler CLI** (verrà installato automaticamente)

## 🚀 Setup Iniziale

### 1. Installa le Dipendenze

```bash
cd /Users/alessandrobisi/Progetti/__mcps__/mcp-gsc-http

# Installa le dipendenze npm
npm install
```

### 2. Verifica Docker

Assicurati che Docker sia in esecuzione:

```bash
docker info
```

Se ricevi un errore, avvia Docker Desktop.

### 3. Login a Cloudflare

```bash
npx wrangler login
```

Questo aprirà un browser per autenticarti con il tuo account Cloudflare.

## 📦 Preparazione del Container

### File Creati

I seguenti file sono già pronti:

- **`Dockerfile`** - Definisce l'immagine del container Python
- **`worker.js`** - Worker Cloudflare che gestisce le richieste
- **`wrangler.jsonc`** - Configurazione del deployment
- **`package.json`** - Dipendenze npm
- **`.dockerignore`** - File da escludere dal build Docker
- **`credentials.json`** - Credenziali Google Service Account

### Struttura del Deployment

```
Client → Worker (worker.js)
           ↓
      Container (Dockerfile)
           ↓
     MCP Server (gsc_server.py)
           ↓
  Google Search Console API
```

## 🔧 Configurazione

### Variabili d'Ambiente nel Container

Le credenziali sono già configurate nel `Dockerfile`. Il container usa:

- `GSC_PORT=8000` - Porta interna del container
- `GSC_HOST=0.0.0.0` - Host per accettare connessioni
- `GSC_SKIP_OAUTH=true` - Usa service account
- Le credenziali sono copiate in `/app/credentials.json`

### Configurazione del Worker

Il `worker.js` è configurato per:
- Passare tutte le richieste al container
- Gestire CORS automaticamente
- Fornire un endpoint `/health` per health checks
- Esporre l'endpoint `/mcp` per i client MCP

## 🚀 Deploy

### 1. Build e Deploy

```bash
# Deploy completo (build + push + deploy)
npm run deploy
```

Questo comando:
1. Builda l'immagine Docker del container
2. La pusha al Cloudflare Container Registry
3. Deploya il Worker
4. Configura i Durable Objects

**Nota**: Il primo deploy può richiedere diversi minuti (5-10 minuti) perché:
- Docker deve buildare l'immagine Python
- L'immagine deve essere pushata su Cloudflare
- Il container deve essere distribuito globalmente

### 2. Verifica lo Status del Deployment

```bash
# Lista i containers
npm run list

# Lista le immagini nel registry
npm run images
```

### 3. Attendi che il Container sia Pronto

Dopo il deploy, **attendi circa 5-10 minuti** prima che il container sia completamente operativo.

Durante questo periodo:
- Il container viene distribuito globalmente
- Le immagini vengono pre-fetched
- Il Worker è già attivo ma le chiamate al container potrebbero fallire

## ✅ Test del Deployment

### 1. URL del Worker

Dopo il deploy, riceverai un URL simile a:
```
https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev
```

### 2. Test Health Check

```bash
curl https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev/health
```

Risposta attesa:
```json
{
  "status": "ok",
  "service": "mcp-gsc-server",
  "timestamp": "2025-10-29T..."
}
```

### 3. Test MCP Endpoint

```bash
curl https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev/mcp
```

Se ricevi una risposta (anche un errore MCP), significa che il container sta funzionando!

### 4. Configura il Client MCP

Aggiungi al tuo `mcp.json`:

```json
{
  "mcpServers": {
    "gsc-http-cloudflare": {
      "url": "https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev/mcp",
      "transport": "streamable-http",
      "description": "Google Search Console MCP Server (Cloudflare)"
    }
  }
}
```

## 📊 Monitoring e Logs

### Visualizza i Logs in Tempo Reale

```bash
npm run tail
```

Questo mostrerà i log del Worker e del container in tempo reale.

### Dashboard Cloudflare

Puoi anche monitorare il deployment da:
- [Cloudflare Containers Dashboard](https://dash.cloudflare.com/?to=/:account/workers/containers)

## 🔧 Troubleshooting

### Errore: "Cannot connect to the Docker daemon"

**Soluzione**: Avvia Docker Desktop

```bash
# Verifica che Docker sia in esecuzione
docker info
```

### Errore: "Container not ready" durante le prime richieste

**Soluzione**: Normale, attendi 5-10 minuti dopo il primo deploy.

### Il container non risponde

**Soluzione**: Verifica i log

```bash
npm run tail
```

Cerca errori come:
- Problemi di build Docker
- Errori nelle credenziali Google
- Errori di rete

### Errore 500 dal container

**Possibili cause**:
1. Credenziali Google non valide
2. Il service account non ha accesso alle proprietà GSC
3. Errore nel codice Python

**Soluzione**: Verifica i log con `npm run tail`

## 🔄 Update e Re-deploy

Dopo aver modificato il codice:

```bash
# Re-deploy
npm run deploy
```

Cloudflare farà un **rolling update**:
- Le istanze esistenti continueranno a funzionare
- Nuove istanze verranno avviate con il nuovo codice
- Le vecchie istanze verranno gradualmente sostituite

## 📈 Scalabilità

### Configurazione Attuale

- `max_instances: 1` - Un singolo container condiviso

### Per Aumentare le Istanze

Modifica `wrangler.jsonc`:

```jsonc
"containers": [
  {
    "class_name": "McpGscContainer",
    "image": "./Dockerfile",
    "max_instances": 5  // Aumenta per più istanze concorrenti
  }
]
```

Poi re-deploya:

```bash
npm run deploy
```

## 💰 Costi

Cloudflare Containers è in Beta e disponibile sul piano Workers Paid.

I costi dipendono da:
- Tempo di CPU utilizzato
- Memoria allocata
- Numero di richieste

Durante la Beta, i costi potrebbero essere ridotti o gratuiti. Controlla la dashboard Cloudflare per dettagli aggiornati.

## 🔐 Sicurezza

### Credenziali

Le credenziali Google sono attualmente nel container. Per maggiore sicurezza:

1. Usa [Cloudflare Secrets](https://developers.cloudflare.com/workers/configuration/secrets/)
2. Modifica `gsc_server.py` per leggere da env vars
3. Rimuovi `credentials.json` dal Dockerfile

### Accesso

Il Worker è pubblicamente accessibile. Per limitare l'accesso:

1. Aggiungi autenticazione custom nel `worker.js`
2. Usa [Cloudflare Access](https://www.cloudflare.com/products/zero-trust/access/)
3. Limita con IP allowlist

## 🎯 Prossimi Passi

1. ✅ Deploy il container
2. ✅ Testa l'endpoint
3. ✅ Configura i client MCP
4. ✅ Monitora l'uso e i costi
5. ✅ Scala se necessario

## 📚 Risorse

- [Cloudflare Containers Docs](https://developers.cloudflare.com/containers/)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)
- [Container Examples](https://developers.cloudflare.com/containers/examples/)

## 🆘 Supporto

Se incontri problemi:
1. Controlla i logs con `npm run tail`
2. Verifica la [documentazione Cloudflare](https://developers.cloudflare.com/containers/)
3. Consulta il [Community Forum](https://community.cloudflare.com/)

