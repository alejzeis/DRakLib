module draklib.protocol.raknet.OnlineConnectionRequest;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;
import draklib.util.SystemAddress;

class OnlineConnectionRequest : Packet {
	public static const ubyte PID = DRakLib.ONLINE_CONNECTION_REQUEST;
	public long clientGUID;
	public long time;
	
	override {
		protected void _encode(ByteStream stream) {
			stream.writeLong(clientGUID);
			stream.writeLong(time);
			stream.writeByte(0); //unknown extra byte
		}
		
		protected void _decode(ByteStream stream) {
			clientGUID = stream.readLong();
			time = stream.readLong();
			//unknown extra byte
		}
		
		public ulong getLength() {
			return 18;
		}
		
		public ubyte getID() {
			return PID;
		}
	}
}

class OnlineConnectionRequestAccepted : Packet {
	public static const ubyte PID = DRakLib.ONLINE_CONNECTION_REQUEST_ACCEPTED;
	public SystemAddress clientAddress;
	public ushort systemIndex = 0; //unknown
	public SystemAddress[] internalIds = [
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
		SystemAddress("255.255.255.255", 19132),
	];
	public long requestTime;
	public long time;
	
	override {
		protected void _encode(ByteStream stream) {
			clientAddress.write(stream);
			stream.writeShort(systemIndex);
			foreach(SystemAddress a; internalIds) {
				a.write(stream);
			}
			stream.writeLong(requestTime);
			stream.writeLong(time);
		}
		
		protected void _decode(ByteStream stream) {
			clientAddress = SystemAddress();
			clientAddress.read(stream);
			for(int i = 0; i < 10; i++) { //10 addresses
				internalIds[i] = SystemAddress();
				internalIds[i].read(stream);
			}
			requestTime = stream.readLong();
			time = stream.readLong();
		}
		
		public ulong getLength() {
			return 96;
		}
		
		public ubyte getID() {
			return PID;
		}
	}
}