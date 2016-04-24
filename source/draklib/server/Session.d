module draklib.server.Session;
import std.conv;

import draklib.DRakLib;
import draklib.server.RakNetServer;
import draklib.protocol.raknet.OfflineConnectionRequest;
import draklib.protocol.raknet.OfflineConnectionResponse;
import draklib.protocol.raknet.AcknowledgePacket;
import draklib.protocol.raknet.ReliabilityLayer;
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

	private shared uint state;
	private shared ushort mtu;
	private shared long clientGUID;
	private shared long clientID;
	private long timeLastPacketReceived;

	private shared int lastPing = -99;
	
	private int lastSeqNum = -1;
	private uint sendSeqNum = 0;
	
	private uint messageIndex = 0;
	private uint splitID = 0;

	private immutable CustomPacket sendQueue = new CustomPacket4();
	private CustomPacket[int] recoveryQueue;
	private int[] ACKQueue = [];
	private int[] NACKQueue = [];
	private int[EncapsulatedPacket][int] splitQueue;

	private RakNetServer server;
	private SystemAddress address;

	this(RakNetServer server, shared SystemAddress address) {
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
				ACKPacket ack = new ACKPacket();
				ack.decode(packet);

				foreach(uint num; ack.packets) {
					if(num in recoveryQueue) {
						recoveryQueue.remove(num);
					}
				}
				break;
			case DRakLib.NACK:
				NACKPacket nack = new NACKPacket();
				nack.decode(packet);

				foreach(uint num; nack.packets) {
					if(num in recoveryQueue) {
						CustomPacket cp = recoveryQueue[num];
						cp.sequenceNumber = sendSeqNum++;
						sendRaw(cp.encode());
						recoveryQueue.remove(num);
					} else debug server.getLogger().logWarn("NACK " ~ to!string(num) ~ " not found in recovery queue");
				}
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

