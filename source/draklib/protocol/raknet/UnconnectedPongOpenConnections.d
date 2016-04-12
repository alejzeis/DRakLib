module draklib.protocol.raknet.UnconnectedPongOpenConnections;
import draklib.protocol.raknet.OpenConnectionsPongPacket;
import draklib.DRakLib;
import draklib.ByteStream;

class UnconnectedPongOpenConnections : OpenConnectionsPongPacket {
	public static const ubyte ID = DRakLib.ID_UNCONNECTED_PONG_OPEN_CONNECTIONS;

	override {
		public ubyte getID() {
			return ID;
		}
	}
}

