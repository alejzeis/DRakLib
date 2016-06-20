module draklib.server.socket;

import std.socket;
import std.conv;

interface ISocket {
	void bind(in int sendBufSize, in int recvBufSize) @trusted;
	
	bool send(in byte[] buffer, in string ip, in ushort port) @trusted;
	
	bool recv(out byte[] buffer, out string ip, out ushort port) @trusted;
	
	void close() @trusted;
	
	const string getBindIp() @safe;
	
	const ushort getBindPort() @safe;
}


class UDPSocketIP4 : ISocket {
	private const string bindIp;
	private const ushort bindPort;
	private Socket socket;
	
	this(in string bindIp, in ushort bindPort) @safe {
		socket = new UdpSocket(AddressFamily.INET);
		
		this.bindIp = bindIp;
		this.bindPort = bindPort;
	}
	
	override {
		void bind(in int sendBufSize, in int recvBufSize) @trusted {
			socket.bind(new InternetAddress(cast(string) bindIp, cast(ushort) bindPort));
			
			socket.setOption(SocketOptionLevel.SOCKET, SocketOption.BROADCAST, true);
			socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDBUF, sendBufSize);
			socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVBUF, recvBufSize);
			socket.blocking(false);
		}
		
		bool send(in byte[] buffer, in string ip, in ushort port) @trusted {
			auto sent = socket.sendTo(buffer, new InternetAddress(cast(string) bindIp, cast(ushort) bindPort));
			if(sent > 0) {
				return true;
			}
			return false;
		}
		
		bool recv(out byte[] buffer, out string ip, out ushort port) @trusted {
			byte[] buf = new byte[4096];
			Address from;
			auto len = socket.receiveFrom(buf, from);
			
			if(len < 0) {
				return false;
			}
			
			buffer = buf[0..len];
			ip = from.toAddrString();
			port = to!ushort(from.toPortString());
			return true;
		}
		
		void close() @trusted {
			socket.close();
		}
		
		const string getBindIp() @safe {
			return bindIp;
		}
		
		const ushort getBindPort() @safe {
			return bindPort;
		}
	}
}
