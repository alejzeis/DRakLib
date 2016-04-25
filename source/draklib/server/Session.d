module draklib.server.Session;
import std.conv;
import std.stdio;

import draklib.DRakLib;
import draklib.ByteStream;
import draklib.server.RakNetServer;
import draklib.protocol.raknet.OfflineConnectionRequest;
import draklib.protocol.raknet.OfflineConnectionResponse;
import draklib.protocol.raknet.OnlineConnectionRequest;
import draklib.protocol.raknet.AcknowledgePacket;
import draklib.protocol.raknet.ReliabilityLayer;
import draklib.util.SystemAddress;
import draklib.util.misc;

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

	private CustomPacket sendQueue = new CustomPacket4();
	private CustomPacket[uint] recoveryQueue;
	private bool[uint] ACKQueue;
	private bool[uint] NACKQueue;
	private EncapsulatedPacket[int][int] splitQueue;

	private RakNetServer server;
	private SystemAddress address;

	this(RakNetServer server, SystemAddress address) {
		this.server = server;
		this.address = address;

		state = OFFLINE_1;
	}

	package void update() {
		if(state == DISCONNECTED) return;
		if((getTimeMillis() - timeLastPacketReceived) >= server.getOptions().packetTimeout) {
			debug server.getLogger().logDebug("disconnecting");
			disconnect("connection timed out");
		} else {
			if(ACKQueue.length > 0) {
				ACKPacket ack = new ACKPacket();
				ack.packets = cast(uint[]) [];
				foreach(uint num; ACKQueue.keys) {
					ack.packets ~= num;
				}
				sendRaw(ack.encode());
				version(DigitalMars) ACKQueue.clear();
				else {
					ACKQueue = [0 : true];
					ACKQueue.remove(0);
				}
			}
			if(NACKQueue.length > 0) {
				NACKPacket nack = new NACKPacket();
				nack.packets = cast(uint[]) [];
				foreach(uint num; NACKQueue.keys) {
					nack.packets ~= num;
				}
				sendRaw(nack.encode());
				version(DigitalMars) NACKQueue.clear();
				else {
					NACKQueue = [0 : true];
					NACKQueue.remove(0);
				}
			}

			sendQueuedPackets();
		}
	}

	private void sendQueuedPackets() {
		if(sendQueue.packets.length > 0) {
			sendQueue.sequenceNumber = sendSeqNum++;
			sendRaw(sendQueue.encode());
			recoveryQueue[sendQueue.sequenceNumber] = sendQueue;
			debug server.getLogger().logDebug("1Queue now has " ~ to!string(recoveryQueue[sendQueue.sequenceNumber].packets.length));
			sendQueue.packets = [];
			debug server.getLogger().logDebug("2Queue now has " ~ to!string(recoveryQueue[sendQueue.sequenceNumber].packets.length));
		}
	}

	/**
	 * Adds an EncapsulatedPacket to the queue, and sets its
	 * messageIndex, orderIndex, and any other values
	 * depending on the Reliability.
	 * 
	 * If the packet's total length is longer than the MTU (Maximum Transport Unit)
	 * then the packet will be split into smaller chunks, which each
	 * will be added to the queue.
	 * Params:
	 *     pk =         The EncapsulatedPacket to be added
	 *     immediate =  If the packet should skip the queue
	 *                  and be sent immediately.
	 */
	public void addToQueue(EncapsulatedPacket pk, in bool immediate = false) {
		switch(pk.reliability) {
			case Reliability.RELIABLE_ORDERED:
				//TODO: orderIndex
				goto case;
			case Reliability.RELIABLE:
			case Reliability.RELIABLE_SEQUENCED:
			case Reliability.RELIABLE_WITH_ACK_RECEIPT:
			case Reliability.RELIABLE_ORDERED_WITH_ACK_RECEIPT:
				pk.messageIndex = messageIndex++;
				break;
			default:
				break;
		}

		if(pk.getLength() + 4 > mtu) { //4 is overhead for CustomPacket header
			//Packet is too big, needs to be split
			byte[][] buffers = splitByteArray(pk.buffer, mtu - 34);
			ushort splitID = cast(ushort) this.splitID++;
			for(uint count = 0; count < buffers.length; count++) {
				EncapsulatedPacket ep = new EncapsulatedPacket();
				ep.splitID = splitID;
				ep.split = true;
				ep.splitCount = cast(uint) buffers.length;
				ep.reliability = pk.reliability;
				ep.splitIndex = count;
				ep.buffer = buffers[count];

				if(count > 0) {
					ep.messageIndex = messageIndex++;
				} else {
					ep.messageIndex = pk.messageIndex;
				}
				if(ep.reliability == Reliability.RELIABLE_ORDERED) {
					ep.orderChannel = pk.orderChannel;
					ep.orderIndex = pk.orderIndex;
				}

				queuePacket(ep, true);
			}
		} else {
			queuePacket(pk, immediate);
		}
	}

	private void queuePacket(EncapsulatedPacket pkt, in bool immediate) {
		if(immediate) {
			CustomPacket cp = new CustomPacket0();
			cp.packets = cast(EncapsulatedPacket[]) [];
			cp.packets ~= pkt;
			cp.sequenceNumber = sendSeqNum++;
			sendRaw(cp.encode());

			recoveryQueue[cp.sequenceNumber] = cp;
		} else {
			if((sendQueue.getLength() + pkt.getLength()) > mtu) {
				sendQueuedPackets();
			}
			sendQueue.packets ~= pkt;
		}
	}

	public void sendRaw(byte[] data) {
		server.getLogger().logDebug("OUT: " ~ to!string(data[0]));
		server.sendPacket(data, address);
	}

	package void handlePacket(byte[] packet) {
		if(state == DISCONNECTED) return;

		server.getLogger().logDebug("IN: " ~ to!string(packet[0]));
		timeLastPacketReceived = getTimeMillis();
		switch(cast(ubyte) packet[0]) {
			// Non - Reliable Packets
			case DRakLib.ID_OPEN_CONNECTION_REQUEST_1:
				if(state != OFFLINE_1) return;
				OfflineConnectionRequest1 req1 = new OfflineConnectionRequest1();
				writeln(cast(ubyte[]) packet);
				req1.decode(packet);
				mtu = req1.nullPayloadLength;

				debug server.getLogger().logDebug("MTU: " ~ to!string(mtu));

				OfflineConnectionResponse1 res1 = new OfflineConnectionResponse1();
				res1.serverID = server.getOptions().serverID;
				res1.mtu = mtu;
				sendRaw(res1.encode());

				state = OFFLINE_2;
				debug server.getLogger().logDebug("Enter state OFFLINE_2");
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
				debug server.getLogger().logDebug("Enter state ONLINE_HANDSHAKE");
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
				if(cast(ubyte) (packet[0]) >= DRakLib.CUSTOM_PACKET_0 && cast(ubyte) (packet[0]) <= DRakLib.CUSTOM_PACKET_F) {
					debug server.getLogger().logDebug("Handling custom packet");
					CustomPacket cp = new CustomPacket0();
					cp.decode(packet);
					handleCustomPacket(cp);
				}
				break;
		}
	}

	private void handleCustomPacket(CustomPacket cp) {
		int diff = cp.sequenceNumber - lastSeqNum;
		if(NACKQueue.length > 0) {
			NACKQueue.remove(cp.sequenceNumber);
			if(diff != 1) {
				for(int i = lastSeqNum + 1; i < cp.sequenceNumber; i++) {
					NACKQueue[i] = true;
				}
			}
		}

		ACKQueue[cp.sequenceNumber] = true;

		if(diff >= 1) lastSeqNum = cp.sequenceNumber;

		foreach(EncapsulatedPacket pk; cp.packets) {
			handleEncapsulatedPacket(pk);
		}
	}

	private void handleSplitPacket(EncapsulatedPacket pk) {
		if(pk.splitCount >= MAX_SPLIT_SIZE || pk.splitIndex >= MAX_SPLIT_SIZE) {
			debug server.getLogger().logWarn("Skipped split Encapsulated: size too big (splitCount: " ~ to!string(pk.splitCount) ~ ", splitIndex: " ~ to!string(pk.splitIndex) ~ ")");
			return;
		}

		if(!(pk.splitID in splitQueue)) {
			if(splitQueue.length >= MAX_SPLIT_COUNT) {
				debug server.getLogger.logWarn("Skipped split Encapsulated: too many in queue (" ~ to!string(splitQueue.length) ~ ")");
				return;
			}
			EncapsulatedPacket[int] m;
			m[pk.splitIndex] = pk;
			splitQueue[pk.splitID] = m;
		} else {
			auto m = splitQueue[pk.splitID];
			m[pk.splitIndex] = pk;
			splitQueue[pk.splitID] = m;
		}

		if(splitQueue[pk.splitID].keys.length == pk.splitCount) {
			EncapsulatedPacket ep = new EncapsulatedPacket();
			ByteStream bs = ByteStream.allocDyn();
			auto packets = splitQueue[pk.splitID];
			foreach(EncapsulatedPacket packet; packets) {
				bs.write(packet.buffer);
			}

			splitQueue.remove(pk.splitID);

			ep.buffer = bs.getBuffer();

			handleEncapsulatedPacket(ep);
		}
	}

	private void handleEncapsulatedPacket(EncapsulatedPacket pk) {
		if(!(state == ONLINE_CONNECTED || state == ONLINE_HANDSHAKE)) {
			debug server.getLogger().logWarn("Skipped Encapsulated: not in right state (" ~ to!string(state) ~ ")");
			return;
		}
		if(pk.split && state == ONLINE_CONNECTED) {
			handleSplitPacket(pk);
		} else debug server.getLogger().logWarn("Skipped split Encapsulated: not in right state (" ~ to!string(state) ~ ")");

		switch(cast(ubyte) pk.buffer[0]) {
			case DRakLib.DISCONNECT_NOTIFICATION:
				disconnect("client disconnected");
				break;
			case DRakLib.ONLINE_CONNECTION_REQUEST:
				OnlineConnectionRequest ocr = new OnlineConnectionRequest();
				ocr.decode(pk.buffer);

				OnlineConnectionRequestAccepted ocra = new OnlineConnectionRequestAccepted();
				ocra.clientAddress = address;
				ocra.requestTime = ocr.time;
				ocra.time = ocr.time + 1000L;

				EncapsulatedPacket ep = new EncapsulatedPacket();
				ep.reliability = Reliability.UNRELIABLE;
				ep.buffer = ocra.encode();
				addToQueue(ep, true);
				break;
			default:
				//TODO
				break;
		}
	}

	public void disconnect(in string reason = null) {
		EncapsulatedPacket ep = new EncapsulatedPacket();
		ep.reliability = Reliability.UNRELIABLE;
		ep.buffer = cast(byte[]) [0x15];
		addToQueue(ep, true);

		server.addToBlacklist(address, 30);

		state = DISCONNECTED;

		server.onSessionClose(this, reason);
	}

	public RakNetServer getServer() {
		return server;
	}

	public SystemAddress getAddress() {
		return address;
	}
}

