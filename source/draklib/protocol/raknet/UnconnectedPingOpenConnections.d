module draklib.protocol.raknet.UnconnectedPingOpenConnections;
import draklib.DRakLib;
import draklib.protocol.raknet.OpenConnectionsPacket;

class UnconnectedPingOpenConnections : OpenConnectionsPacket {
	public static const ubyte ID = DRakLib.ID_UNCONNECTED_PING_OPEN_CONNECTIONS;

	override {
		public ubyte getID() {
			return ID;
		}
	}
}

