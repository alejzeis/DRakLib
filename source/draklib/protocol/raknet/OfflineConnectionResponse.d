module draklib.protocol.raknet.OfflineConnectionResponse;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;
import draklib.util.SystemAddress;

class OfflineConnectionResponse1 : Packet {
	public static const ubyte PID = DRakLib.ID_OPEN_CONNECTION_REPLY_1;
	public long serverID;
	public ushort mtu;

	override {
		protected void _encode(ByteStream stream) {
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
			stream.writeLong(serverID);
			stream.writeUShort(mtu);
		}

		protected void _decode(ByteStream stream) {
			stream.skip(16); //MAGIC
			serverID = stream.readLong();
			mtu = stream.readUShort();
		}

		public ulong getLength() {
			return 28;
		}

		public ubyte getID() {
			return PID;
		}
	}
}

class OfflineConnectionResponse2 : Packet {
	public static const ubyte PID = DRakLib.ID_OPEN_CONNECTION_REPLY_2;
	public long serverID;
	public SystemAddress clientAddress = SystemAddress();
	public ushort mtu;
	public byte encryptionEnabled;
	
	override {
		protected void _encode(ByteStream stream) {
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
			stream.writeLong(serverID);
			clientAddress.write(stream);
			stream.writeUShort(mtu);
			stream.writeByte(encryptionEnabled);
		}
		
		protected void _decode(ByteStream stream) {
			stream.skip(16); //MAGIC
			serverID = stream.readLong();
			clientAddress.read(stream);
			mtu = stream.readUShort();
			encryptionEnabled = stream.readByte();
		}
		
		public ulong getLength() {
			return 35;
		}
		
		public ubyte getID() {
			return PID;
		}
	}
}