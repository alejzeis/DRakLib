module draklib.protocol.raknet.ConnectedPingOpenConnectionsPacket;
import draklib.DRakLib;
import draklib.protocol.raknet.OpenConnectionsPacket;

class ConnectedPingOpenConnectionsPacket : OpenConnectionsPacket {
	public static const ubyte ID = DRakLib.ID_CONNECTED_PING_OPEN_CONNECTIONS;

	override {
		public ubyte getID() {
			return ID;
		}
	}
}

