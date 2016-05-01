module draklib.server.session;
import draklib.core;
import draklib.util;
import draklib.bytestream;
import draklib.server.raknetserver;
import draklib.protocol.offline;
import draklib.protocol.reliability;
import draklib.protocol.online;
import draklib.protocol.connected;

import std.conv;

enum SessionState {
	DISCONNECTED = 0,
	OFFLINE_1 = 1,
	OFFLINE_2 = 2,
	ONLINE_HANDSHAKE = 3,
	ONLINE_CONNECTED = 4
}

class Session {
	static immutable uint MAX_SPLIT_SIZE = 128;
	static immutable uint MAX_SPLIT_COUNT = 4;

	private uint state;
	private ushort mtu;
	private long clientGUID;
	private long timeLastPacketReceived;
	
	private shared int lastPing = -99;
	
	private int lastSeqNum = -1;
	private uint sendSeqNum = 0;
	
	private uint messageIndex = 0;
	private ushort splitID = 0;
	
	private ContainerPacket sendQueue;
	private ContainerPacket[uint] recoveryQueue;
	private bool[uint] ACKQueue;
	private bool[uint] NACKQueue;
	private EncapsulatedPacket[int][int] splitQueue;
	
	private RakNetServer server;
	private const string ip;
	private const ushort port;

	this(RakNetServer server, in string ip, in ushort port) {
		this.server = server;
		this.ip = ip;
		this.port = port;

		state = SessionState.OFFLINE_1;

		sendQueue = new ContainerPacket();
		sendQueue.header = 0x84; //Default
	}

	package void update() {
		if(state == SessionState.DISCONNECTED) return;
		if((getTimeMillis() - timeLastPacketReceived) >= server.options.timeoutThreshold) {
			disconnect("connection timed out");
		} else {
			if(ACKQueue.length > 0) {
				ACKPacket ack = new ACKPacket();
				ack.nums = cast(uint[]) [];
				foreach(uint num; ACKQueue.keys) {
					ack.nums ~= num;
				}
				byte[] data;
				ack.encode(data);
				sendRaw(data);
				version(DigitalMars) ACKQueue.clear();
				else {
					ACKQueue = [0 : true];
					ACKQueue.remove(0);
				}
			}
			if(NACKQueue.length > 0) {
				NACKPacket nack = new NACKPacket();
				nack.nums = cast(uint[]) [];
				foreach(uint num; NACKQueue.keys) {
					nack.nums ~= num;
				}
				byte[] data;
				nack.encode(data);
				sendRaw(data);
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
			byte[] data;
			sendQueue.encode(data);
			sendRaw(data);
			recoveryQueue[sendQueue.sequenceNumber] = sendQueue;
			debug server.logger.logDebug("1Queue now has " ~ to!string(recoveryQueue[sendQueue.sequenceNumber].packets.length));
			sendQueue.packets = [];
			debug server.logger.logDebug("2Queue now has " ~ to!string(recoveryQueue[sendQueue.sequenceNumber].packets.length));
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
				debug server.logger.logDebug("Set message index to: " ~ to!string(pk.messageIndex));
				break;
			default:
				break;
		}
		
		if(pk.getSize() + 4 > mtu) { //4 is overhead for CustomPacket header
			//Packet is too big, needs to be split
			byte[][] buffers = splitByteArray(pk.payload, mtu - 34);
			ushort splitID = this.splitID++;
			for(uint count = 0; count < buffers.length; count++) {
				EncapsulatedPacket ep = new EncapsulatedPacket();
				ep.splitID = splitID;
				ep.split = true;
				ep.splitCount = cast(uint) buffers.length;
				ep.reliability = pk.reliability;
				ep.splitIndex = count;
				ep.payload = buffers[count];
				
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
			ContainerPacket cp = new ContainerPacket();
			cp.header = 0x84;
			cp.packets = cast(EncapsulatedPacket[]) [];
			cp.packets ~= pkt;
			cp.sequenceNumber = sendSeqNum++;
			byte[] data;
			cp.encode(data);
			sendRaw(data);
			
			recoveryQueue[cp.sequenceNumber] = cp;
		} else {
			if((sendQueue.getSize() + pkt.getSize()) > mtu) {
				sendQueuedPackets();
			}
			sendQueue.packets ~= pkt;
		}
	}
	
	public void sendRaw(in byte[] data) {
		import std.socket : InternetAddress;
		server.sendPacket(new InternetAddress(ip, port), data);
	}
	
	package void handlePacket(byte[] packet) {
		if(state == SessionState.DISCONNECTED) return;

		timeLastPacketReceived = getTimeMillis();
		byte[] data;
		switch(cast(ubyte) packet[0]) {
			// Non - Reliable Packets
			case RakNetInfo.OFFLINE_CONNECTION_REQUEST_1:
				if(state != SessionState.OFFLINE_1) return;
				OfflineConnectionRequest1 req1 = new OfflineConnectionRequest1();
				req1.decode(packet);
				mtu = req1.mtuSize;
				
				debug(sessionInfo) server.logger.logDebug("MTU: " ~ to!string(mtu));
				
				OfflineConnectionResponse1 res1 = new OfflineConnectionResponse1();
				res1.serverGUID = server.options.serverGUID;
				res1.mtu = mtu;

				res1.encode(data);
				sendRaw(data);
				
				state = SessionState.OFFLINE_2;
				debug(sessionInfo) server.logger.logDebug("Enter state OFFLINE_2");
				break;
			case RakNetInfo.OFFLINE_CONNECTION_REQUEST_2:
				if(state != SessionState.OFFLINE_2) break;
				OfflineConnectionRequest2 req2 = new OfflineConnectionRequest2();
				req2.decode(packet);
				clientGUID = req2.clientGUID;
				
				OfflineConnectionResponse2 res2 = new OfflineConnectionResponse2();
				res2.serverGUID = server.options.serverGUID;
				res2.clientAddress = ip;
				res2.clientPort = port;
				res2.mtu = mtu;
				res2.encryptionEnabled = false; // RakNet encryption not implemented

				res2.encode(data);
				sendRaw(data);
				
				state = SessionState.ONLINE_HANDSHAKE;
				debug(sessionInfo) server.logger.logDebug("Enter state ONLINE_HANDSHAKE");
				break;
				// ACK/NACK
			case RakNetInfo.ACK:
				ACKPacket ack = new ACKPacket();
				ack.decode(packet);
				
				foreach(uint num; ack.nums) {
					if(num in recoveryQueue) {
						recoveryQueue.remove(num);
					}
				}
				break;
			case RakNetInfo.NACK:
				NACKPacket nack = new NACKPacket();
				nack.decode(packet);
				
				foreach(uint num; nack.nums) {
					if(num in recoveryQueue) {
						ContainerPacket cp = recoveryQueue[num];
						cp.sequenceNumber = sendSeqNum++;

						cp.encode(data);
						sendRaw(data);

						recoveryQueue.remove(num);
					} else debug(sessionInfo) server.logger.logWarn("NACK " ~ to!string(num) ~ " not found in recovery queue");
				}
				break;
			default:
				if(cast(ubyte) (packet[0]) >= 0x80 && cast(ubyte) (packet[0]) <= 0x8F) {
					ContainerPacket cp = new ContainerPacket();
					cp.decode(packet);
					handleContainerPacket(cp);
				}
				break;
		}
	}
	
	private void handleContainerPacket(ContainerPacket cp) {
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
			debug server.logger.logWarn("Skipped split Encapsulated: size too big (splitCount: " ~ to!string(pk.splitCount) ~ ", splitIndex: " ~ to!string(pk.splitIndex) ~ ")");
			return;
		}
		
		if(!(pk.splitID in splitQueue)) {
			if(splitQueue.length >= MAX_SPLIT_COUNT) {
				debug server.logger.logWarn("Skipped split Encapsulated: too many in queue (" ~ to!string(splitQueue.length) ~ ")");
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
			ByteStream bs = ByteStream.alloc(1024 * 1024);
			auto packets = splitQueue[pk.splitID];
			foreach(EncapsulatedPacket packet; packets) {
				bs.write(packet.payload);
			}
			
			splitQueue.remove(pk.splitID);
			
			ep.payload = bs.getBuffer()[0..bs.getPosition()].dup;
			bs = null;
			
			handleEncapsulatedPacket(ep);
		}
	}
	
	private void handleEncapsulatedPacket(EncapsulatedPacket pk) {
		assert(pk.payload.length > 0);
		if(!(state == SessionState.ONLINE_CONNECTED || state == SessionState.ONLINE_HANDSHAKE)) {
			debug server.logger.logWarn("Skipped Encapsulated: not in right state (" ~ to!string(state) ~ ")");
			return;
		}
		if(pk.split) {
			if(state == SessionState.ONLINE_CONNECTED)
				handleSplitPacket(pk);
			else debug server.logger.logWarn("Skipped split Encapsulated: not in right state (" ~ to!string(state) ~ ")");
		}
		
		switch(cast(ubyte) pk.payload[0]) {
			case RakNetInfo.DISCONNECT_NOTIFICATION:
				disconnect("client disconnected");
				break;
			case RakNetInfo.ONLINE_CONNECTION_REQUEST:
				OnlineConnectionRequest ocr = new OnlineConnectionRequest();
				ocr.decode(pk.payload);
				
				OnlineConnectionRequestAccepted ocra = new OnlineConnectionRequestAccepted();
				ocra.clientAddress = ip;
				ocra.clientPort = port;
				ocra.requestTime = ocr.time;
				ocra.time = ocr.time + 1000L;
				
				EncapsulatedPacket ep = new EncapsulatedPacket();
				ep.reliability = Reliability.UNRELIABLE;
				ocra.encode(ep.payload);
				addToQueue(ep, true);
				break;
			case 0x13:
				state = SessionState.ONLINE_CONNECTED;
				debug(sessionInfo) server.logger.logDebug("Enter state ONLINE_CONNECTED");
				server.onSessionOpen(this, clientGUID);
				break;
			case RakNetInfo.CONNECTED_PING:
				ConnectedPingPacket ping = new ConnectedPingPacket();
				ping.decode(pk.payload);

				ConnectedPongPacket pong = new ConnectedPongPacket();
				pong.time = ping.time;

				EncapsulatedPacket ep = new EncapsulatedPacket();
				ep.reliability = Reliability.UNRELIABLE;
				pong.encode(ep.payload);
				addToQueue(ep, true);
				break;
			default:
				server.onSessionReceivePacket(this, cast(shared) pk.payload);
				break;
		}
	}
	
	public void disconnect(in string reason = null) {
		EncapsulatedPacket ep = new EncapsulatedPacket();
		ep.reliability = Reliability.UNRELIABLE;
		ep.payload = cast(byte[]) [0x15];
		addToQueue(ep, true);
		
		server.addToBlacklist(getIdentifier(), 30);
		
		state = SessionState.DISCONNECTED;
		
		server.onSessionClose(this, reason);
	}
	
	public RakNetServer getServer() {
		return server;
	}
	
	public string getIpAddress() {
		return ip;
	}

	public ushort getPort() {
		return port;
	}

	public string getIdentifier() {
		return ip ~ ":" ~ to!string(port);
	}

	public long getClientGUID() {
		return clientGUID;
	}
}