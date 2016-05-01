module draklib.server.serverinterface;

struct SessionOpenMessage {
	shared string ip;
	shared ushort port;
	shared long clientID;

	this(shared string ip, shared ushort port, shared long clientID) {
		this.ip = ip;
		this.port = port;
		this.clientID = clientID;
	}

	SessionOpenMessage opCall(string ip, ushort port, long clientID) {
		this.ip = ip;
		this.port = port;
		this.clientID = clientID;
		return this;
	}
}

struct SessionCloseMessage {
	shared string ip;
	shared ushort port;
	shared string reason;

	this(shared string ip, shared ushort port, shared string reason) {
		this.ip = ip;
		this.port = port;
		this.reason = reason;
	}

	SessionCloseMessage opCall(string ip, ushort port, string reason) {
		this.ip = ip;
		this.port = port;
		this.reason = reason;
		return this;
	}
}

struct SessionReceivePacketMessage {
	shared string ip;
	shared ushort port;
	shared byte[] payload;

	this(shared string ip, shared ushort port, shared byte[] payload) {
		this.ip = ip;
		this.port = port;
		this.payload = payload;
	}

	SessionReceivePacketMessage opCall(string ip, ushort port, shared byte[] payload) {
		this.ip = ip;
		this.port = port;
		this.payload = payload;
		return this;
	}
}