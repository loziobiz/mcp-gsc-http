@echo off
REM Script di avvio per MCP-GSC HTTP Server (Windows)
REM Questo script attiva il virtual environment e avvia il server HTTP

echo === MCP-GSC HTTP Server ===
echo.

REM Controlla se il virtual environment esiste
if not exist ".venv" (
    echo ❌ Virtual environment non trovato!
    echo Crea prima il virtual environment con: python -m venv .venv
    pause
    exit /b 1
)

REM Attiva il virtual environment
echo 🔄 Attivazione virtual environment...
call .venv\Scripts\activate.bat

REM Controlla se le dipendenze sono installate
python -c "import mcp" 2>nul
if errorlevel 1 (
    echo ⚠️  Dipendenze non installate. Installazione in corso...
    pip install -r requirements.txt
)

REM Configurazione opzionale tramite variabili d'ambiente
REM Puoi modificare questi valori o impostarli prima di eseguire lo script
if not defined GSC_PORT set GSC_PORT=8000
if not defined GSC_HOST set GSC_HOST=0.0.0.0

echo.
echo 📡 Configurazione server:
echo    Host: %GSC_HOST%
echo    Porta: %GSC_PORT%
echo    URL: http://%GSC_HOST%:%GSC_PORT%/mcp
echo.
echo 🚀 Avvio del server...
echo.

REM Avvia il server
python gsc_server.py

pause

