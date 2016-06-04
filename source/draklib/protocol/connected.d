module draklib.protocol.connected;
import draklib.info;
import draklib.bytestream : ByteStream;
import draklib.protocol.packet;

class ConnectedPingPacket : Packet {
	long time;
	
	override {
		protected void _encode(ref ByteStream stream) @safe {
			stream.writeLong(time);
		}
		
		protected void _decode(ref ByteStream stream) @safe {
			time = stream.readLong();
		}
		
		ubyte getID() @safe {
			return CONNECTED_PING;
		}
		
		uint getSize() @safe {
			return 9;
		}
	}
}

class ConnectedPongPacket : ConnectedPingPacket {
	override {
		ubyte getID() @safe {
			return CONNECTED_PONG;
		}
	}
}