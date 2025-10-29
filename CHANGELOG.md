# Changelog

Tutte le modifiche notevoli a questo progetto saranno documentate in questo file.

## [HTTP Transport Update] - 2025-10-29

### 🚀 Aggiunto
- **Transport HTTP Streamable** come modalità predefinita
  - Il server ora utilizza il transport HTTP streamable moderno di MCP
  - Endpoint disponibile su `/mcp` (non più SSE deprecato)
  - Supporto per accesso remoto tramite HTTP
  - Configurabile tramite variabili d'ambiente `GSC_PORT` e `GSC_HOST`
  
- **Script di avvio automatico**
  - `start_server.sh` per Linux/Mac
  - `start_server.bat` per Windows
  - Gestione automatica del virtual environment e installazione dipendenze

- **Documentazione HTTP**
  - Nuova sezione "Transport Options" nel README.md
  - `HTTP_SETUP_GUIDE.md` con guida completa all'uso del server HTTP
  - Esempi di configurazione per vari scenari
  - Raccomandazioni di sicurezza

- **Dipendenze aggiornate**
  - `uvicorn>=0.30.0` per il server HTTP
  - `starlette>=0.37.0` per il framework ASGI

### 🔄 Modificato
- `gsc_server.py`: Transport modificato da stdio a `streamable-http`
  - Endpoint: `http://host:port/mcp` (moderno MCP streamable HTTP)
- `requirements.txt`: Aggiunte dipendenze per HTTP server (`uvicorn`, `starlette`)
- `pyproject.toml`: Aggiornate le dipendenze del progetto
- `README.md`: Aggiunta sezione dettagliata sulle opzioni di transport

### 📝 Note
- **Retrocompatibilità**: È possibile tornare a stdio modificando una singola riga nel codice
- **Sicurezza**: La configurazione attuale non include autenticazione. Si raccomanda l'uso dietro firewall o con reverse proxy
- **Tutte le funzionalità esistenti rimangono inalterate**: Tutti i 19 tool MCP continuano a funzionare esattamente come prima

### 🎯 Vantaggi della nuova configurazione
- Accesso remoto da client multipli
- Facilità di deploy su server dedicati
- Integrazione semplificata con sistemi distribuiti
- Utilizzo dietro firewall/proxy per maggiore sicurezza
- Scalabilità migliorata per ambienti enterprise

