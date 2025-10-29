# 🌐 MCP-GSC Server su Cloudflare Containers

Server MCP per Google Search Console deployato su Cloudflare Containers (Beta).

## 🎯 Cosa Hai Ora

Un server MCP completamente configurato per il deployment su Cloudflare con:

✅ **Container Docker** pronto con Python 3.11  
✅ **Worker Cloudflare** che gestisce le richieste  
✅ **Configurazione Wrangler** completa  
✅ **Credenziali Google** integrate  
✅ **CORS** configurato automaticamente  
✅ **Health check** endpoint incluso  

## 📁 Struttura File

```
mcp-gsc-http/
├── Dockerfile              # Container Python con MCP server
├── worker.js               # Worker Cloudflare (routing)
├── wrangler.jsonc          # Configurazione deployment
├── package.json            # Dipendenze npm
├── gsc_server.py           # Server MCP (19 tools GSC)
├── credentials.json        # Credenziali Google (non in git)
├── requirements.txt        # Dipendenze Python
└── DEPLOY_INSTRUCTIONS.md  # Guida rapida deploy
```

## 🚀 Deploy Rapido (3 comandi)

```bash
# 1. Installa dipendenze
npm install

# 2. Login Cloudflare
npx wrangler login

# 3. Deploy!
npm run deploy
```

**Tempo stimato**: 10-15 minuti per il primo deploy

## 🔗 URL Risultante

Dopo il deploy:
```
https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev/mcp
```

Questo URL sarà accessibile globalmente da qualsiasi client MCP!

## 🎛️ Endpoint Disponibili

| Endpoint | Descrizione |
|----------|-------------|
| `/mcp` | Endpoint MCP principale (streamable HTTP) |
| `/health` | Health check del servizio |

## 🛠️ Comandi Utili

```bash
# Deploy/Re-deploy
npm run deploy

# Logs in tempo reale
npm run tail

# Lista containers attivi
npm run list

# Lista immagini nel registry
npm run images

# Sviluppo locale (richiede Docker)
npm run dev
```

## 📊 Architettura

```
Client MCP
   ↓
Cloudflare Worker (worker.js)
   ↓
Durable Object + Container
   ↓
Python MCP Server (gsc_server.py)
   ↓
Google Search Console API
```

## 🔧 Configurazione Client

### Cursor IDE

`~/.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "gsc-cloudflare": {
      "url": "https://mcp-gsc-server.YOUR_SUBDOMAIN.workers.dev/mcp",
      "transport": "streamable-http",
      "description": "GSC su Cloudflare (Production)"
    }
  }
}
```

### Claude Desktop

`~/Library/Application Support/Claude/claude_desktop_config.json`:
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

## 🎯 Tools Disponibili

Il server espone 19 tools per Google Search Console:

1. `list_properties` - Lista proprietà GSC
2. `get_search_analytics` - Analytics di ricerca
3. `get_performance_overview` - Overview performance
4. `inspect_url_enhanced` - Ispezione URL dettagliata
5. `batch_url_inspection` - Ispezione batch URLs
6. `check_indexing_issues` - Verifica problemi indicizzazione
7. `get_sitemaps` - Lista sitemap
8. `submit_sitemap` - Invia sitemap
9. `delete_sitemap` - Elimina sitemap
10. `get_sitemap_details` - Dettagli sitemap
11. `list_sitemaps_enhanced` - Lista sitemap avanzata
12. `manage_sitemaps` - Gestione sitemap
13. `get_advanced_search_analytics` - Analytics avanzate
14. `compare_search_periods` - Confronta periodi
15. `get_search_by_page_query` - Analytics per pagina
16. `add_site` - Aggiungi sito
17. `delete_site` - Rimuovi sito
18. `get_site_details` - Dettagli sito
19. `get_creator_info` - Info creatore

## 🔒 Sicurezza

### Credenziali

- Le credenziali Google sono nel container
- Service account: `ga4-mcp-runner@augmented-humanuty.iam.gserviceaccount.com`
- Il container è isolato e sicuro

### Accesso

- Il Worker è pubblico ma richiede client MCP compatibili
- CORS configurato per accesso cross-origin
- Considera Cloudflare Access per limitare accesso

## 📈 Performance e Costi

### Scalabilità

- **max_instances: 1** (configurazione attuale)
- Può essere aumentato in `wrangler.jsonc`
- Auto-scaling basato su carico

### Costi (Beta)

Durante la Beta di Containers:
- Costi potrebbero essere ridotti/gratuiti
- Verifica dashboard Cloudflare per dettagli aggiornati
- Basato su: CPU time, memoria, richieste

## 🐛 Troubleshooting

### Docker non trovato
```bash
# Installa Docker Desktop
# Verifica con:
docker info
```

### Container non risponde
```bash
# Vedi logs
npm run tail

# Attendi 10 minuti dopo primo deploy
```

### Errore 500
- Controlla logs: `npm run tail`
- Verifica credenziali Google
- Assicurati che service account abbia accesso GSC

## 🔄 Update del Server

Dopo modifiche al codice:

```bash
# Re-deploy
npm run deploy
```

Cloudflare farà un **rolling update** senza downtime.

## 📚 Documentazione

- **DEPLOY_INSTRUCTIONS.md** - Guida rapida
- **CLOUDFLARE_DEPLOYMENT.md** - Guida dettagliata
- **README.md** - Documentazione generale MCP-GSC

## 🌍 Vantaggi Cloudflare vs Locale

| Aspetto | Locale | Cloudflare |
|---------|---------|------------|
| Accesso | Solo network locale | Globale |
| Uptime | Dipende da tuo PC | 99.99%+ |
| Latenza | Bassa (locale) | Bassa (edge) |
| Scalabilità | Limitata | Automatica |
| Costi | Gratis | Pay-as-you-go |
| Manutenzione | Manuale | Automatica |

## ✨ Prossimi Passi

1. ✅ Deploy su Cloudflare
2. ✅ Testa con client MCP
3. ✅ Monitora uso e performance
4. ✅ Scala se necessario (aumenta max_instances)
5. ✅ Considera aggiungere autenticazione custom

## 🆘 Supporto

- [Cloudflare Containers Docs](https://developers.cloudflare.com/containers/)
- [Community Forum](https://community.cloudflare.com/)
- [Discord Cloudflare Developers](https://discord.gg/cloudflaredev)

---

**Pronto per il deploy!** 🚀

Esegui `npm install && npx wrangler login && npm run deploy`

