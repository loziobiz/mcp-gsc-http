# Documentazione MCP-GSC HTTP Server

Questa cartella contiene tutta la documentazione del progetto MCP-GSC HTTP Server.

## 📚 Indice della Documentazione

### 🚀 Guide Principali

1. **[GUIDA_MIGRAZIONE_COMPLETA.md](./GUIDA_MIGRAZIONE_COMPLETA.md)** (1.533 righe)
   - Guida completa per migrare un server MCP da stdio a HTTP-streamable
   - Include deployment su Cloudflare Containers
   - Ottimizzata per agenti AI (Claude Sonnet 4.5)
   - Esempi di codice completi dal progetto
   - **Ideale per**: Migrare un nuovo server MCP simile a questo

2. **[CLOUDFLARE_DEPLOYMENT.md](./CLOUDFLARE_DEPLOYMENT.md)** (313 righe)
   - Guida dettagliata al deployment su Cloudflare Containers
   - Setup iniziale e configurazione
   - Comandi di deploy e verifica
   - Troubleshooting specifico Cloudflare
   - **Ideale per**: Deployare questo specifico progetto

3. **[QUICK_START.md](./QUICK_START.md)** (233 righe)
   - Avvio rapido del server in locale
   - Setup con credenziali Google
   - Test e verifica funzionamento
   - **Ideale per**: Testing locale prima del deploy

### ⚙️ Configurazione e Setup

4. **[HTTP_SETUP_GUIDE.md](./HTTP_SETUP_GUIDE.md)** (289 righe)
   - Setup del trasporto HTTP-streamable
   - Configurazione variabili d'ambiente
   - Test della connessione HTTP
   - **Ideale per**: Capire il funzionamento del trasporto HTTP

5. **[CLIENT_EXAMPLES.md](./CLIENT_EXAMPLES.md)** (395 righe)
   - Esempi di configurazione per vari client MCP
   - Claude Desktop, Cursor, altri IDE
   - Configurazioni remote e locali
   - **Ideale per**: Connettere un client al server

### 📋 Riferimenti

6. **[MIGRATION_SUMMARY.md](./MIGRATION_SUMMARY.md)** (200 righe)
   - Riepilogo della migrazione da stdio a HTTP-streamable
   - Differenze tra i transport
   - Modifiche applicate al progetto
   - **Ideale per**: Capire le differenze tra stdio e HTTP

## 🎯 Percorsi Consigliati

### Per Deployare Questo Progetto
1. Leggi [QUICK_START.md](./QUICK_START.md) per testare in locale
2. Segui [CLOUDFLARE_DEPLOYMENT.md](./CLOUDFLARE_DEPLOYMENT.md) per il deploy
3. Consulta [CLIENT_EXAMPLES.md](./CLIENT_EXAMPLES.md) per connettere i client

### Per Migrare un Altro Server MCP
1. Leggi [GUIDA_MIGRAZIONE_COMPLETA.md](./GUIDA_MIGRAZIONE_COMPLETA.md) - contiene tutto!
2. Usa questo progetto come riferimento per il codice
3. Segui le fasi 1-6 descritte nella guida

### Per Capire l'Architettura
1. Leggi [MIGRATION_SUMMARY.md](./MIGRATION_SUMMARY.md) per il context
2. Leggi [HTTP_SETUP_GUIDE.md](./HTTP_SETUP_GUIDE.md) per i dettagli tecnici
3. Consulta il codice sorgente in `gsc_server.py`

## 📁 File Nella Root del Progetto

Nella cartella principale trovi:

- **[../README.md](../README.md)** - README principale del progetto
- **[../CHANGELOG.md](../CHANGELOG.md)** - Storia delle modifiche

## 🔗 Link Rapidi

- **Repository**: (aggiungi il link GitHub se pubblico)
- **Cloudflare Containers Docs**: https://developers.cloudflare.com/containers/
- **MCP Protocol**: https://modelcontextprotocol.io/
- **FastMCP**: https://github.com/jlowin/fastmcp

## 📝 Note

- Tutti i file sono in formato Markdown (.md)
- La documentazione è mantenuta aggiornata con le modifiche al codice
- Per segnalare errori o miglioramenti, apri una issue nel repository

---

**Ultima revisione**: 2025-01-01

