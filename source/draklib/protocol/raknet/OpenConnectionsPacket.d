module draklib.protocol.raknet.OpenConnectionsPacket;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;

abstract class OpenConnectionsPacket : Packet {
	public long pingId;

	override {
		protected void _encode(ByteStream stream) {
			stream.writeLong(pingId);
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
		}

		protected void _decode(ByteStream stream) {
			pingId = stream.readLong();
			//MAGIC
		}

		public ulong getLength() {
			return 25;
		}
	}
}

