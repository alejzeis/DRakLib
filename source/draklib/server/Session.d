module draklib.server.Session;
import std.conv;

import draklib.server.RakNetServer;
import draklib.util.SystemAddress;

/**
 * An implementation of a RakNet Session.
 * 
 * Authors: jython234
 */
class Session {
	public static const uint DISCONNECTED = 0;
	public static const uint CONNECTING_1 = 1;
	public static const uint CONNECTING_2 = 2;
	public static const uint HANDSHAKING = 3;
	public static const uint CONNECTED = 4;

	public static const uint MAX_SPLIT_SIZE = 128;
	public static const uint MAX_SPLIT_COUNT = 4;

	private uint state;
	private ushort mtu;
	private long clientID;
	private long timeLastPacketReceived;

	private int lastPing = -99;
	
	private int lastSeqNum = -1;
	private uint sendSeqNum = 0;
	
	private uint messageIndex = 0;
	private uint splitID = 0;

	private RakNetServer server;
	private SystemAddress address;

	this(RakNetServer server, SystemAddress address) {
		this.server = server;
		this.address = address;

		state = CONNECTING_1;
	}

	package void update() {

	}

	package void handlePacket(byte[] packet) {
		server.getLogger().logDebug("Packet: " ~ to!string(packet[0]));
	}

	public RakNetServer getServer() {
		return server;
	}

	public SystemAddress getAddress() {
		return address;
	}
}

