#!/bin/bash

# Script di avvio MCP-GSC HTTP Server con credenziali Service Account
# Configurato per l'account di servizio ga4-mcp-runner@augmented-humanuty.iam.gserviceaccount.com

echo "=== MCP-GSC HTTP Server con Service Account ==="
echo ""

# Controlla se il virtual environment esiste
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment non trovato!"
    echo "Crea prima il virtual environment con: python -m venv .venv"
    exit 1
fi

# Attiva il virtual environment
echo "🔄 Attivazione virtual environment..."
source .venv/bin/activate

# Controlla se le dipendenze sono installate
if ! python -c "import mcp" 2>/dev/null; then
    echo "⚠️  Dipendenze non installate. Installazione in corso..."
    pip install -r requirements.txt
fi

# Configurazione credenziali Google Service Account
export GSC_CREDENTIALS_PATH="/Users/alessandrobisi/Progetti/kf-seshat-crewai/ga4_analyst/keys/gcp_service_account.json"
export GSC_SKIP_OAUTH="true"

# Configurazione server HTTP
export GSC_PORT="${GSC_PORT:-8000}"
export GSC_HOST="${GSC_HOST:-0.0.0.0}"

echo ""
echo "🔑 Configurazione Google Service Account:"
echo "   Credentials: $GSC_CREDENTIALS_PATH"
echo "   Skip OAuth: $GSC_SKIP_OAUTH"
echo ""
echo "📡 Configurazione server:"
echo "   Host: $GSC_HOST"
echo "   Porta: $GSC_PORT"
echo "   URL: http://$GSC_HOST:$GSC_PORT/mcp"
echo ""
echo "🚀 Avvio del server..."
echo ""

# Avvia il server
python gsc_server.py

