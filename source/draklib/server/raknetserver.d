module draklib.server.raknetserver;
import draklib.core;
import draklib.logging;
import draklib.util;
import draklib.server.socket;
import draklib.server.session;
import draklib.protocol.unconnected;

import core.thread;

import std.exception;
import std.concurrency;
import std.datetime;
import std.conv;
import std.socket : Address;

struct ServerOptions {
	string serverIdent;
	uint sendBufferSize = 4096;
	uint recvBufferSize = 4096;

	/// The Amount of time with no packets recieved needed to disconnect
	/// a client due to timeout.
	uint timeoutThreshold = 5000;

	bool warnOnCantKeepUp = true;

	long serverGUID = -1;
}

class RakNetServer {
	shared static uint INSTANCES = 0;
	package const Logger logger;
	package const Tid controller;
	package ServerSocket socket;
	package ServerOptions options;

	package Session[string] sessions;
	package ulong[string] blacklist;

	private bool running = false;
	private ulong currentTick;

	this(in Tid controller, in Logger logger, ushort bindPort, string bindIp = "0.0.0.0", ServerOptions options = ServerOptions()) {
		this.logger = logger;
		this.controller = controller;
		this.options = options;
		socket = new ServerSocket(logger, bindIp, bindPort);

		if(options.serverGUID == -1) {
			import std.random;
			options.serverGUID = uniform(long.min, long.max);
		}
	}

	void start() {
		enforce(!running, new InvalidOperationException("Attempted to start server while already running!"));
		running = true;
		run();
	}

	void stop() {
		enforce(running, new InvalidOperationException("Attempted to stop server that is not running!"));
	}

	private void run() {
		Thread.getThis().name = "RakNetServer #" ~ to!string(INSTANCES++);
		logger.logDebug("Starting DRakLib server on " ~ socket.getBindAddress().toString());

		socket.bind();

		long elapsed;
		StopWatch sw = StopWatch();
		while(running) {
			sw.reset();
			sw.start();
			try{
				doTick();
			} catch(Exception e) {
				logger.logError("FATAL! Exception in tick!");
				logger.logTrace(e.toString());
			}
			sw.stop();
			elapsed = sw.peek().msecs();
			if(elapsed > 50) {
				if(options.warnOnCantKeepUp) logger.logWarn("Can't keep up! (" ~ to!string(elapsed) ~ " > 50) Did the system time change or is the server overloaded?");
			} else {
				Thread.sleep(dur!("msecs")(50 - elapsed));
			}
		}
	}

	private void doTick() {
		uint max = 500;
		Address a;
		byte[] data = new byte[2048];
		while(max-- > 0 && socket.recv(a, data)) {
			handlePacket(a, data);
		}
	}

	private void handlePacket(ref Address address, ref byte[] data) {
		switch(data[0]) {
			case RakNetInfo.UNCONNECTED_PING_1:
				UnconnectedPingPacket1 ping1 = new UnconnectedPingPacket1();
				ping1.decode(data);

				UnconnectedPongPacket pong1 = new UnconnectedPongPacket();
				pong1.serverGUID = options.serverGUID;
				pong1.serverInfo = options.serverIdent;
				pong1.time = ping1.time;
				byte[] buffer;
				pong1.encode(buffer);
				sendPacket(address, buffer);
				break;
			
			case RakNetInfo.UNCONNECTED_PING_2:
				UnconnectedPingPacket2 ping2 = new UnconnectedPingPacket2();
				ping2.decode(data);

				AdvertiseSystemPacket pong2 = new AdvertiseSystemPacket();
				pong2.serverGUID = options.serverGUID;
				pong2.serverInfo = options.serverIdent;
				pong2.time = ping2.time;
				byte[] buffer;
				pong2.encode(buffer);
				sendPacket(address, buffer);
				break;

			default:
				break;
		}
	}

	package void sendPacket(Address sendTo, in byte[] data) {
		socket.send(sendTo, data);
	}
}