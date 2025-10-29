# 🚀 Istruzioni Rapide per il Deploy su Cloudflare

## Prerequisiti Veloci

1. Docker in esecuzione: `docker info`
2. Account Cloudflare con piano Workers Paid

## Deploy in 3 Step

### 1️⃣ Installa Dipendenze

```bash
cd /Users/alessandrobisi/Progetti/__mcps__/mcp-gsc-http
npm install
```

### 2️⃣ Login a Cloudflare

```bash
npx wrangler login
```

### 3️⃣ Deploy!

```bash
npm run deploy
```

⏱️ **Attendi 5-10 minuti** per il primo deploy.

## ✅ Verifica

Dopo il deploy riceverai un URL tipo:
```
https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev
```

### Test rapido:

```bash
# Health check
curl https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev/health

# Dovrebbe rispondere:
# {"status":"ok","service":"mcp-gsc-server","timestamp":"..."}
```

## 🔌 Configura il Client

Aggiungi al tuo `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "gsc-cloudflare": {
      "url": "https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev/mcp",
      "transport": "streamable-http"
    }
  }
}
```

**Sostituisci `YOUR_SUBDOMAIN` con il tuo vero subdomain!**

## 📊 Comandi Utili

```bash
# Vedi logs in tempo reale
npm run tail

# Lista containers
npm run list

# Lista immagini
npm run images

# Re-deploy dopo modifiche
npm run deploy
```

## ⚠️ Troubleshooting

### "Docker not running"
→ Avvia Docker Desktop

### "Container not ready"
→ Attendi 10 minuti dopo il primo deploy

### Errori nel log
→ Usa `npm run tail` per vedere i dettagli

## 📖 Documentazione Completa

Vedi `CLOUDFLARE_DEPLOYMENT.md` per guida dettagliata.

---

**Pronto!** Una volta deployato, il tuo server MCP-GSC sarà accessibile globalmente! 🌍

