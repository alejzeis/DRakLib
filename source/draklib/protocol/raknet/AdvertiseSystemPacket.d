module draklib.protocol.raknet.AdvertiseSystemPacket;
import draklib.protocol.raknet.OpenConnectionsPongPacket;
import draklib.DRakLib;
import draklib.ByteStream;

class AdvertiseSystemPacket : OpenConnectionsPongPacket {
	public static const ubyte ID = DRakLib.ID_ADVERTISE_SYSTEM;
	
	override {
		public ubyte getID() {
			return ID;
		}
	}
}

