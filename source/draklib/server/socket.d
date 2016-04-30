module draklib.server.socket;
import draklib.logging;

import std.conv;
import std.socket;

class ServerSocket {
	private const Logger logger;
	private InternetAddress bindAddress;
	private Socket socket;

	this(in Logger logger, string bindInterface = "0.0.0.0", ushort bindPort = 19132) {
		this.logger = logger;
		socket = new UdpSocket(AddressFamily.INET);
		bindAddress = new InternetAddress(bindInterface, bindPort);
	}

	void bind(uint sendBufferSize = 1024 * 1024, uint recvBufferSize = 1024 * 1024) {
		socket.bind(bindAddress);

		socket.setOption(SocketOptionLevel.SOCKET, SocketOption.BROADCAST, true);
		//socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDBUF, sendBufferSize);
		//socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVBUF, recvBufferSize);
		socket.blocking = false;
	}

	bool recv(ref Address address, ref byte[] buffer) {
		auto length = socket.receiveFrom(buffer, SocketFlags.NONE, address);
		if(length > 0) {
			buffer.length = length;
			debug logger.logDebug(to!string(length) ~ " Packet IN: " ~ to!string(cast(ubyte[]) buffer));
			return true;
		}
		buffer = null;
		return false;
	}

	void send(Address address, in byte[] buffer) {
		socket.sendTo(buffer, SocketFlags.NONE, address);
		debug logger.logDebug("Packet OUT: " ~ to!string(cast(ubyte[]) buffer));
	}

	void close() {
		socket.close();
	}

	InternetAddress getBindAddress() {
		return bindAddress;
	}
}