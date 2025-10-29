#!/bin/bash

# Script di avvio per MCP-GSC HTTP Server
# Questo script attiva il virtual environment e avvia il server HTTP

echo "=== MCP-GSC HTTP Server ==="
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

# Configurazione opzionale tramite variabili d'ambiente
# Puoi modificare questi valori o impostarli prima di eseguire lo script
export GSC_PORT="${GSC_PORT:-8000}"
export GSC_HOST="${GSC_HOST:-0.0.0.0}"

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

