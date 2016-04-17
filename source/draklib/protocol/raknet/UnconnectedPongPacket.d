module draklib.protocol.raknet.UnconnectedPongPacket;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;

class UnconnectedPongPacket : Packet {
	public static const PID = DRakLib.ID_UNCONNECTED_PONG_OPEN_CONNECTIONS;
	public long time;
	public long serverId;
	public string ident;

	override {
		protected void _encode(ByteStream stream) {
			stream.writeLong(time);
			stream.writeLong(serverId);
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
			stream.writeStrUTF8(ident);
		}

		protected void  _decode(ByteStream stream) {
			time = stream.readLong();
			serverId = stream.readLong();
			stream.skip(16); //MAGIC
			ident = stream.readStrUTF8();
		}

		public ulong getLength() {
			return 35 + ident.length;
		}

		public ubyte getID() {
			return PID;
		}
	}
}

class AdvertiseSystemPacket : UnconnectedPongPacket {
	public static const PID = DRakLib.ID_ADVERTISE_SYSTEM;

	override {
		public ubyte getID() {
			return PID;
		}
	}
}