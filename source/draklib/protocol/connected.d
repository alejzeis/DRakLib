module draklib.protocol.connected;
import draklib.core : RakNetInfo;
import draklib.bytestream : ByteStream;
import draklib.protocol.packet;

class ConnectedPingPacket : Packet {
	long time;
	
	override {
		protected void _encode(ref ByteStream stream) {
			stream.writeLong(time);
		}
		
		protected void _decode(ref ByteStream stream) {
			time = stream.readLong();
		}
		
		ubyte getID() {
			return RakNetInfo.CONNECTED_PING;
		}
		
		uint getSize() {
			return 9;
		}
	}
}

class ConnectedPongPacket : ConnectedPingPacket {
	override {
		ubyte getID() {
			return RakNetInfo.CONNECTED_PONG;
		}
	}
}