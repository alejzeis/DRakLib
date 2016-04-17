module draklib.protocol.raknet.OfflineConnectionRequest;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;
import draklib.util.SystemAddress;

class OfflineConnectionRequest1 : Packet {
	public static const ubyte PID = DRakLib.ID_OPEN_CONNECTION_REQUEST_1;
	public ubyte protocolVersion;
	public uint nullPayloadLength;
	
	override {
		protected void _encode(ByteStream stream) {
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
			stream.writeUByte(protocolVersion);
			stream.write(new byte[nullPayloadLength - 18]);
		}
		
		protected void _decode(ByteStream stream) {
			stream.skip(16); //MAGIC
			protocolVersion = stream.readUByte();
			nullPayloadLength = stream.getRemainingLength() + 18;
		}
		
		public ulong getLength() {
			return nullPayloadLength; //Null payload length includes overhead of packet
		}
		
		public ubyte getID() {
			return PID;
		}
	}
}

class OfflineConnectionRequest2 : Packet {
	public static const ubyte PID = DRakLib.ID_OPEN_CONNECTION_REQUEST_2;
	public SystemAddress serverAddress;
	public ushort mtu;
	public long clientID;

	override {
		protected void _encode(ByteStream stream) {
			stream.write(cast(byte[]) DRakLib.RAKNET_MAGIC);
			serverAddress.write(stream);
			stream.writeUShort(mtu);
			stream.writeLong(clientID);
		}

		protected void _decode(ByteStream stream) {
			super._decode(stream);
		}

		public ulong getLength() {
			return 34;
		}

		public ubyte getID() {
			return PID;
		}
	}
}