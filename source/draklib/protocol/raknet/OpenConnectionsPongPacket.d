module draklib.protocol.raknet.OpenConnectionsPongPacket;
import draklib.protocol.Packet;
import draklib.DRakLib;
import draklib.ByteStream;

class OpenConnectionsPongPacket : Packet {
	public long pingId;
	public long serverId;
	public string ident;

	override {
		protected void _encode(ByteStream stream) {
			stream.writeLong(pingId);
			stream.writeLong(serverId);
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
			stream.writeStrUTF8(ident);
		}

		protected void _decode(ByteStream stream) {
			pingId = stream.readLong();
			serverId = stream.readLong();
			stream.skip(16); //MAGIC
			ident = stream.readStrUTF8();
		}

		public ulong getLength() {
			return 35 + ident.length;
		}
	}
}

