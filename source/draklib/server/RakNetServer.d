module draklib.server.RakNetServer;
import draklib.server.RakSocket;

struct ServerOptions {
	
}

class RakNetServer {
	private bool running = false;

	private RakSocket socket;

	this(ushort bindPort, string bindIp = "0.0.0.0", ServerOptions options = ServerOptions()) {

		socket = new RakSocket(bindIp, bindPort);
	}
}
