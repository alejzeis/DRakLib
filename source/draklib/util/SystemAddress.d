module draklib.util.SystemAddress;
import std.conv;
import std.array;
import draklib.ByteStream;

struct SystemAddress {
	public ubyte ipVersion;
	public string ip;
	public ushort port;

	this(string ip, ushort port, ubyte ipVersion = 4) {
		this.ipVersion = ipVersion;
		this.ip = ip;
		this.port = port;
	}

	public void write(ByteStream stream) {
		stream.writeUByte(ipVersion);
		final switch(ipVersion) {
			case 4:
				foreach(string s; split(ip, ".")) {
					stream.writeUByte(~to!ubyte(s));
				}
				stream.writeUShort(port);
				break;
			case 6:
				//Not supported yet
				break;
		}
	}

	public void read(ByteStream stream) {
		ipVersion = stream.readUByte();
		if(ipVersion == 4) {
			ip = to!string(~stream.readUByte()) ~ "." ~ to!string(~stream.readUByte()) ~ "." ~ to!string(~stream.readUByte()) ~ "." ~ to!string(~stream.readUByte());
			port = stream.readUShort();
		} else if(ipVersion == 6) {
			//Not supported yet
		}
	}
}