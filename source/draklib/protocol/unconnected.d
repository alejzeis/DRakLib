module draklib.protocol.unconnected;
import draklib.core : RakNetInfo;
import draklib.bytestream : ByteStream;
import draklib.protocol.packet;

class UnconnectedPingPacket1 : Packet {
	long time;

	override {
		protected void _encode(ByteStream stream) {
			stream.writeLong(time);
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
		}

		protected void _decode(ByteStream stream) {
			time = stream.readLong();
			// MAGIC
		}

		ubyte getID() {
			return RakNetInfo.UNCONNECTED_PING_1;
		}

		uint getSize() {
			return 25;
		}
	}
}

class UnconnectedPingPacket2 : UnconnectedPingPacket1 {
	override {
		ubyte getID() {
			return RakNetInfo.UNCONNECTED_PING_2;
		}
	}
}

class UnconnectedPongPacket : Packet {
	long time;
	long serverGUID;
	string serverInfo;
	
	override {
		protected void _encode(ByteStream stream) {
			stream.writeLong(time);
			stream.writeLong(serverGUID);
			stream.writeU(RakNetInfo.RAKNET_MAGIC);
			stream.writeStrUTF8(serverInfo);
		}
		
		protected void _decode(ByteStream stream) {
			time = stream.readLong();
			serverGUID = stream.readLong();
			stream.skip(RakNetInfo.RAKNET_MAGIC.length);
			serverInfo = stream.readStrUTF8();
		}

		ubyte getID() {
			return RakNetInfo.UNCONNECTED_PONG;
		}
		
		uint getSize() {
			return cast(uint) (35 + (cast(byte[]) serverInfo).length);
		}
	}
}

class AdvertiseSystemPacket : UnconnectedPongPacket {
	override {
		ubyte getID() {
			return RakNetInfo.ADVERTISE_SYSTEM;
		}
	}
}