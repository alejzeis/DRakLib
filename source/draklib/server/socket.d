module draklib.server.socket;
import draklib.logging;

import std.socket;

class ServerSocket {
	private const Logger logger;
	private Address bindAddress;
	private Socket socket;

	this(in Logger logger, string bindInterface = "0.0.0.0", ushort bindPort = 19132) {
		this.logger = logger;
		socket = new UdpSocket(AddressFamily.INET);
		bindAddress = new InternetAddress(bindInterface, bindPort);
	}

	public void bind(uint sendBufferSize = 4096, uint recvBufferSize = 4096) {
		socket.setOption(SocketOptionLevel.SOCKET, SocketOption.BROADCAST, true);
		socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDBUF, sendBufferSize);
		socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVBUF, recvBufferSize);

		socket.blocking = false;

		socket.bind(bindAddress);
	}

	public void recv(out Address address, out byte[] buffer) {

	}
}