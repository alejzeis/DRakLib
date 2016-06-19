module draklib.protocol.unconnected;
import draklib.info;
import draklib.bytestream : ByteStream;
import draklib.protocol.packet;

class UnconnectedPingPacket1 : Packet {
	long time;

	override {
		protected void _encode(ref ByteStream stream) @trusted {
			stream.writeLong(time);
			stream.writeU(RAKNET_MAGIC);
		}

		protected void _decode(ref ByteStream stream) @trusted {
			time = stream.readLong();
			// MAGIC
		}

		ubyte getID() @safe {
			return UNCONNECTED_PING_1;
		}

		size_t getSize() @safe {
			return 25;
		}
	}
}

class UnconnectedPingPacket2 : UnconnectedPingPacket1 {
	override {
		ubyte getID() @safe {
			return UNCONNECTED_PING_2;
		}
	}
}

class UnconnectedPongPacket : Packet {
	long time;
	long serverGUID;
	string serverInfo;
	
	override {
		protected void _encode(ref ByteStream stream) @trusted {
			stream.writeLong(time);
			stream.writeLong(serverGUID);
			stream.writeU(RAKNET_MAGIC);
			stream.writeStrUTF8(serverInfo);
		}
		
		protected void _decode(ref ByteStream stream) @trusted {
			time = stream.readLong();
			serverGUID = stream.readLong();
			stream.skip(RAKNET_MAGIC.length);
			serverInfo = stream.readStrUTF8();
		}

		ubyte getID() @safe {
			return UNCONNECTED_PONG;
		}
		
		size_t getSize() @trusted{
			return cast(uint) (35 + (cast(byte[]) serverInfo).length);
		}
	}
}

class AdvertiseSystemPacket : UnconnectedPongPacket {
	override {
		ubyte getID() @safe {
			return ADVERTISE_SYSTEM;
		}
	}
}