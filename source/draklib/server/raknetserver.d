module draklib.server.raknetserver;
import draklib.core;
import draklib.logging;
import draklib.util;
import draklib.server.socket;
import draklib.server.session;
import draklib.server.serverinterface;
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
	uint timeoutThreshold = 7000;

	bool warnOnCantKeepUp = true;

	long serverGUID = -1;
}

class RakNetServer {
	shared static uint INSTANCES = 0;
	package const Logger logger;
	package Tid controller;
	package ServerSocket socket;
	package ServerOptions options;

	package Session[string] sessions;
	package ulong[string] blacklist;

	private shared bool running = false;
	private shared bool crashed = false;
	private shared ulong currentTick;

	this(Tid controller, in Logger logger, ushort bindPort, string bindIp = "0.0.0.0", ServerOptions options = ServerOptions()) {
		this.logger = logger;
		this.controller = controller;
		this.options = options;
		socket = new ServerSocket(logger, bindIp, bindPort);

		if(options.serverGUID == -1) {
			import std.random;
			this.options.serverGUID = uniform(0L, long.max);
		}
	}

	void start() {
		enforce(!running, new InvalidOperationException("Attempted to start server while already running!"));
		running = true;
		run();
	}

	void stop() {
		enforce(running, new InvalidOperationException("Attempted to stop server that is not running!"));
		running = false;
	}

	private void run() {
		Thread.getThis().name = "RakNetServer #" ~ to!string(INSTANCES++);
		logger.logDebug("Starting DRakLib server on " ~ socket.getBindAddress().toString());

		socket.bind();

		long elapsed;
		StopWatch sw = StopWatch();
		while(running) {
			currentTick++;
			sw.reset();
			sw.start();
			try{
				doTick();
			} catch(Exception e) {
				logger.logError("FATAL! Exception in tick!");
				logger.logTrace(e.toString());

				running = false;
				crashed = true;
				break;
			}
			sw.stop();
			elapsed = sw.peek().msecs();
			if(elapsed > 50) {
				if(options.warnOnCantKeepUp) logger.logWarn("Can't keep up! (" ~ to!string(elapsed) ~ " > 50) Did the system time change or is the server overloaded?");
			} else {
				Thread.sleep(dur!("msecs")(50 - elapsed));
			}
		}

		send(controller, ServerStoppedMessage(hasCrashed));
	}

	private void doTick() {
		uint max = 500;
		Address a;
		byte[] data = new byte[1024 * 1024];
		while(max-- > 0 && socket.recv(a, data)) {
			handlePacket(a, data);
			data = new byte[1024 * 1024];
		}

		foreach(session; sessions) {
			session.update();
		}

		receiveTimeout(dur!("msecs")(1), &this.onStopServerMessage, &this.onSendPacketMessage);
	}

	private void handlePacket(ref Address address, ref byte[] data) {
		if(address.toString() in blacklist) {
			if(blacklist[address.toString()] <= currentTick) {
				blacklist.remove(address.toString());
			} else return;
		}
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

				//AdvertiseSystemPacket pong2 = new AdvertiseSystemPacket();
				UnconnectedPongPacket pong2 = new UnconnectedPongPacket();
				pong2.serverGUID = options.serverGUID;
				pong2.serverInfo = options.serverIdent;
				pong2.time = ping2.time;
				byte[] buffer;
				pong2.encode(buffer);
				sendPacket(address, buffer);
				break;

			default:
				import std.array;

				Session session = sessions.get(address.toString(), null);
				if(session is null) {
					string ip = split(address.toString(), ":")[0];
					ushort port = to!ushort(split(address.toString(), ":")[1]);
					session = new Session(this, ip, port);

					logger.logDebug("Session " ~ session.getIdentifier() ~ " created");
					sessions[session.getIdentifier()] = session;
				}
				session.handlePacket(data);
				break;
		}
	}

	package void sendPacket(Address sendTo, in byte[] data) {
		socket.send(sendTo, data);
	}

	// Message handlers

	package void onSessionOpen(Session session, long clientID) {
		send(controller, SessionOpenMessage(session.getIpAddress(), session.getPort(), session.getClientGUID()));
	}

	package void onSessionClose(Session session, in string reason = null) {
		if(!(session.getIdentifier() in sessions)) return;
		sessions.remove(session.getIdentifier());
		if(reason !is null) {
			logger.logDebug("Session " ~ session.getIdentifier() ~ " closed: " ~ reason);
			send(controller, SessionCloseMessage(session.getIpAddress(), session.getPort(), reason));
			return;
		}
		send(controller, SessionCloseMessage(session.getIpAddress(), session.getPort(), "unknown"));
	}

	package void onSessionReceivePacket(Session session, shared byte[] buffer) {
		send(controller, SessionReceivePacketMessage(session.getIpAddress(), session.getPort(), buffer));
	}

	package void onStopServerMessage(StopServerMessage m) {
		stop();
	}

	package void onSendPacketMessage(SendPacketMessage m) {
		import draklib.protocol.reliability;

		string ident = m.ip ~ ":" ~ to!string(m.port);
		if(ident in sessions) {
			EncapsulatedPacket ep = new EncapsulatedPacket();
			ep.reliability = m.reliability;
			ep.payload = cast(byte[]) m.payload;
			sessions[ident].addToQueue(ep, m.immediate);
		}
	}

	public void addToBlacklist(string identifier, ulong ticks) {
		if(identifier in blacklist) return;
		blacklist[identifier] = currentTick + ticks;
		debug logger.logDebug("Added " ~ identifier ~ " to blacklist until tick: " ~ to!string(blacklist[identifier]));
	}

	public void removeFromBlacklist(string identifier) {
		if(identifier in blacklist) {
			blacklist.remove(identifier);
		}
	}

	public bool isRunning() {
		return running;
	}

	public bool hasCrashed() {
		return crashed;
	}
}