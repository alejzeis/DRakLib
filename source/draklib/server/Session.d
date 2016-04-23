module draklib.server.Session;
import std.conv;

import draklib.DRakLib;
import draklib.server.RakNetServer;
import draklib.protocol.raknet.OfflineConnectionRequest;
import draklib.protocol.raknet.OfflineConnectionResponse;
import draklib.util.SystemAddress;

/**
 * An implementation of a RakNet Session.
 * 
 * Authors: jython234
 */
class Session {
	public static const uint DISCONNECTED = 0;
	public static const uint OFFLINE_1 = 1;
	public static const uint OFFLINE_2 = 2;
	public static const uint ONLINE_HANDSHAKE = 3;
	public static const uint ONLINE_CONNECTED = 4;

	public static const uint MAX_SPLIT_SIZE = 128;
	public static const uint MAX_SPLIT_COUNT = 4;

	private uint state;
	private ushort mtu;
	private long clientGUID;
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

		state = OFFLINE_1;
	}

	package void update() {
		
	}

	public void sendRaw(byte[] data) {
		server.getLogger().logDebug("OUT: " ~ to!string(data[0]));
		server.sendPacket(data, address);
	}

	package void handlePacket(byte[] packet) {
		if(state == DISCONNECTED) return;

		server.getLogger().logDebug("IN: " ~ to!string(packet[0]));
		switch(packet[0]) {
			// Non - Reliable Packets
			case DRakLib.ID_OPEN_CONNECTION_REQUEST_1:
				if(state != OFFLINE_1) return;
				OfflineConnectionRequest1 req1 = new OfflineConnectionRequest1();
				req1.decode(packet);
				mtu = req1.nullPayloadLength;

				OfflineConnectionResponse1 res1 = new OfflineConnectionResponse1();
				res1.serverID = server.getOptions().serverID;
				res1.mtu = mtu;
				sendRaw(res1.encode());

				state = OFFLINE_2;
				break;
			case DRakLib.ID_OPEN_CONNECTION_REQUEST_2:
				if(state != OFFLINE_2) break;
				OfflineConnectionRequest2 req2 = new OfflineConnectionRequest2();
				req2.decode(packet);
				clientGUID = req2.clientID;

				OfflineConnectionResponse2 res2 = new OfflineConnectionResponse2();
				res2.serverID = server.getOptions().serverID;
				res2.clientAddress = address;
				res2.mtu = mtu;
				res2.encryptionEnabled = false; // RakNet encryption not implemented
				sendRaw(res2.encode());

				state = ONLINE_HANDSHAKE;
				break;
			// ACK/NACK
			case DRakLib.ACK:

				break;
			default:
				if(packet[0] >= DRakLib.CUSTOM_PACKET_0 && packet[0] <= DRakLib.CUSTOM_PACKET_F) {

				}
				break;
		}
	}

	public RakNetServer getServer() {
		return server;
	}

	public SystemAddress getAddress() {
		return address;
	}
}

