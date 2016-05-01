module draklib.protocol.offline;
import draklib.core : RakNetInfo;
import draklib.bytestream : ByteStream;
import draklib.protocol.packet;

class OfflineConnectionRequest1 : Packet {
	ubyte protocolVersion = cast(ubyte) RakNetInfo.RAKNET_PROTOCOL;
	ushort mtuSize;

	override {
		protected void _encode(ref ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeUByte(protocolVersion);
			stream.write(new byte[mtuSize - 18]);
		}
		
		protected void _decode(ref ByteStream stream) {
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			protocolVersion = stream.readUByte();
			mtuSize = cast(ushort) (stream.getRemainingLength() + 18);
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
		protected void _encode(ref ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeLong(serverGUID);
			stream.writeByte(0); //security
			stream.writeUShort(mtu);
		}
		
		protected void _decode(ref ByteStream stream) {
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			serverGUID = stream.readLong();
			stream.readByte(); //security
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

class OfflineConnectionRequest2 : Packet {
	string serverAddress;
	ushort serverPort;
	ushort mtu;
	long clientGUID;
	
	override {
		protected void _encode(ref ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeSysAddress(serverAddress, serverPort);
			stream.writeUShort(mtu);
			stream.writeLong(clientGUID);
		}
		
		protected void _decode(ref ByteStream stream) {
			import std.stdio;
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			if(stream.getSize() != 34) { //Strange extra nullbytes
				stream.skip(5);
			}
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
	bool encryptionEnabled;
	
	override {
		protected void _encode(ref ByteStream stream) {
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeLong(serverGUID);
			stream.writeSysAddress(clientAddress, clientPort);
			stream.writeUShort(mtu);
			stream.writeByte(encryptionEnabled ? 1 : 0);
		}
		
		protected void _decode(ref ByteStream stream) {
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			serverGUID = stream.readLong();
			stream.readSysAddress(clientAddress, clientPort);
			mtu = stream.readUShort();
			encryptionEnabled = stream.readByte() > 0;
		}
		
		ubyte getID() {
			return RakNetInfo.OFFLINE_CONNECTION_RESPONSE_2;
		}
		
		uint getSize() {
			return 35;
		}
	}
}