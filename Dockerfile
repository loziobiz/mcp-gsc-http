# Dockerfile per MCP-GSC Server su Cloudflare Containers

FROM python:3.11-slim

# Imposta la directory di lavoro
WORKDIR /app

# Installa le dipendenze di sistema necessarie
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copia i file di requirements
COPY requirements.txt .

# Installa le dipendenze Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia il codice del server
COPY gsc_server.py .

# Copia il file delle credenziali (verrà montato come secret in produzione)
# Nota: In produzione userai Cloudflare Secrets
COPY credentials.json /app/credentials.json

# Espone la porta 8000
EXPOSE 8000

# Variabili d'ambiente di default
ENV GSC_PORT=8000
ENV GSC_HOST=0.0.0.0
ENV GSC_SKIP_OAUTH=true
ENV GSC_CREDENTIALS_PATH=/app/credentials.json

# Comando per avviare il server
CMD ["python", "-u", "gsc_server.py"]

