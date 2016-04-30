module draklib.protocol.offline;
import draklib.core : RakNetInfo;
import draklib.bytestream : ByteStream;
import draklib.protocol.packet;

class OfflineConnectionRequest1 : Packet {
	ubyte protocolVersion = cast(ubyte) RakNetInfo.RAKNET_PROTOCOL;
	ushort mtuSize;

	override {
		protected void _encode(ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeUByte(protocolVersion);
			stream.write(new byte[mtuSize + 18]);
		}
		
		protected void _decode(ByteStream stream) {
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			protocolVersion = stream.readUByte();
			mtuSize = cast(ushort) (stream.getRemainingLength() - 18);
		}
		
		ubyte getID() {
			return RakNetInfo.OFFLINE_CONNECTION_REQUEST_1;
		}
		
		uint getSize() {
			return cast(uint) 18 + mtuSize;
		}
	}
}

class OfflineConnectionResponse1 : Packet {
	long serverGUID;
	ushort mtu;
	
	override {
		protected void _encode(ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeLong(serverGUID);
			stream.writeUShort(mtu);
		}
		
		protected void _decode(ByteStream stream) {
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			serverGUID = stream.readLong();
			mtu = stream.readUShort();
		}
		
		ubyte getID() {
			return RakNetInfo.OFFLINE_CONNECTION_RESPONSE_1;
		}
		
		uint getSize() {
			return 28;
		}
	}
}

class OfflineConnectionRequeset2 : Packet {
	string serverAddress;
	ushort serverPort;
	ushort mtu;
	long clientGUID;
	
	override {
		protected void _encode(ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeSysAddress(serverAddress, serverPort);
			stream.writeUShort(mtu);
			stream.writeLong(clientGUID);
		}
		
		protected void _decode(ByteStream stream) {
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			stream.readSysAddress(serverAddress, serverPort);
			mtu = stream.readUShort();
			clientGUID = stream.readLong();
		}
		
		ubyte getID() {
			return RakNetInfo.OFFLINE_CONNECTION_REQUEST_2;
		}
		
		uint getSize() {
			return 34;
		}
	}
}

class OfflineConnectionResponse2 : Packet {
	long serverGUID;
	string clientAddress;
	ushort clientPort;
	ushort mtu;
	byte encryptionEnabled = 0; //0 Disabled, 1 Enabled
	
	override {
		protected void _encode(ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeLong(serverGUID);
			stream.writeSysAddress(clientAddress, clientPort);
			stream.writeUShort(mtu);
			stream.writeByte(encryptionEnabled);
		}
		
		protected void _decode(ByteStream stream) {
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			serverGUID = stream.readLong();
			stream.readSysAddress(clientAddress, clientPort);
			mtu = stream.readUShort();
			encryptionEnabled = stream.readByte();
		}
		
		ubyte getID() {
			return RakNetInfo.OFFLINE_CONNECTION_RESPONSE_2;
		}
		
		uint getSize() {
			return 30;
		}
	}
}