/**
 * Cloudflare Worker per MCP-GSC Server
 * 
 * Questo Worker gestisce le richieste e le passa al container MCP-GSC
 * Espone l'endpoint /mcp per i client MCP
 */

import { Container } from "@cloudflare/containers";

/**
 * Classe Container per MCP-GSC
 * Estende la classe base Container di Cloudflare
 */
export class McpGscContainer extends Container {
  // Porta su cui il container ascolta (deve corrispondere a GSC_PORT nel Dockerfile)
  defaultPort = 8000;
  
  // Tempo di inattività prima che il container venga messo in sleep
  // 30 minuti di inattività prima di spegnere il container
  sleepAfter = "30m";
  
  // Variabili d'ambiente da passare al container
  envVars = {
    GSC_PORT: "8000",
    GSC_HOST: "0.0.0.0",
    GSC_SKIP_OAUTH: "true",
    GSC_CREDENTIALS_PATH: "/app/credentials.json"
  };
}

/**
 * Handler principale del Worker
 * Gestisce tutte le richieste in ingresso
 */
export default {
  /**
   * Fetch handler - punto di ingresso per tutte le richieste HTTP
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Log della richiesta (utile per debugging)
    console.log(`Request to: ${url.pathname}`);
    
    // Gestisci health check
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        service: 'mcp-gsc-server',
        timestamp: new Date().toISOString()
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Gestisci richieste /mcp rimuovendo il prefisso per il container
    // Il container ascolta su / (root)
    try {
      // Ottieni un'istanza del container
      // Usa un ID fisso per avere un singolo container condiviso
      // oppure usa session-based routing per container multipli
      const containerInstance = env.MCP_GSC.getByName("main");
      
      // Rimuovi il prefisso /mcp dal path prima di passare al container
      let containerPath = url.pathname;
      if (containerPath.startsWith('/mcp')) {
        containerPath = containerPath.substring(4) || '/';
      }
      
      console.log(`Original path: ${url.pathname}, Container path: ${containerPath}`);
      
      // Crea una nuova URL con il path modificato
      const containerUrl = new URL(request.url);
      containerUrl.pathname = containerPath;
      
      // Crea una nuova richiesta con la URL modificata
      const containerRequest = new Request(containerUrl, request);
      
      console.log(`Fetching container at: ${containerUrl.toString()}`);
      
      // Passa la richiesta al container
      const response = await containerInstance.fetch(containerRequest);
      
      console.log(`Container response status: ${response.status}`);
      
      // Aggiungi headers CORS se necessario
      const newResponse = new Response(response.body, response);
      newResponse.headers.set('Access-Control-Allow-Origin', '*');
      newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
      newResponse.headers.set('Access-Control-Allow-Headers', 'Content-Type, Accept, Mcp-Session-Id');
      newResponse.headers.set('Access-Control-Expose-Headers', 'Mcp-Session-Id, Content-Type');
      
      // Gestisci preflight OPTIONS requests
      if (request.method === 'OPTIONS') {
        return new Response(null, {
          headers: newResponse.headers
        });
      }
      
      return newResponse;
    } catch (error) {
      console.error('Error communicating with container:', error);
      
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message,
        timestamp: new Date().toISOString()
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
};

