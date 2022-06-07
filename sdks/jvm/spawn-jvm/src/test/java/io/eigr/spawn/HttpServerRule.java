package io.eigr.spawn;

import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import org.junit.rules.ExternalResource;

import java.net.InetSocketAddress;

public class HttpServerRule  extends ExternalResource {

    private static final int PORT = 8090;

    private HttpServer server;

    @Override
    protected void before() throws Throwable {
        server = HttpServer.create(new InetSocketAddress("0.0.0.0", PORT), 0);
        server.setExecutor(null);
        server.start();
        System.out.println("Server started on port 8080");
    }

    @Override
    protected void after() {
        if (server != null) {
            server.stop(0); // doesn't wait all current exchange handlers complete
        }
    }

    public String getUriFor(String path) {
        if (!path.startsWith("/")) {
            path = "/" + path;
        }
        String host = "http://localhost:" + PORT;
        return host + path;
    }

    public void registerHandler(String uriToHandle, HttpHandler httpHandler) {
        server.createContext(uriToHandle, httpHandler);
    }
}
