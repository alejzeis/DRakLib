module draklib.protocol.raknet.UnconnectedPingPacket;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;

class UnconnectedPingPacket1 : Packet {
	public static const ubyte PID = DRakLib.ID_CONNECTED_PING_OPEN_CONNECTIONS;
	public long pingId;

	override {
		protected void _encode(ByteStream stream) {
			stream.writeLong(pingId);
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
		}

		protected void _decode(ByteStream stream) {
			pingId = stream.readLong();
			// MAGIC
		}

		public ulong getLength() {
			return 25;
		}

		public ubyte getID() {
			return PID;
		}
	}
}

class UnconnectedPingPacket2 : UnconnectedPingPacket1 {
	public static const ubyte PID = DRakLib.ID_UNCONNECTED_PING_OPEN_CONNECTIONS;

	override {
		public ubyte getID() {
			return PID;
		}
	}
}