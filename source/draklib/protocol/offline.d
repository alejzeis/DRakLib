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