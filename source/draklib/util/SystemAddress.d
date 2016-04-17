module draklib.util.SystemAddress;
import std.conv;
import draklib.ByteStream;

struct SystemAddress {
	public ubyte ipVersion;
	public string ip;
	public ushort port;

	this() {
	}

	this(string ip, ushort port, ubyte ipVersion = 4) {
		this.ipVersion = ipVersion;
		this.ip = ip;
		this.port = port;
	}

	public void write(ByteStream stream) {
		stream.writeUByte(ipVersion);
	}

	public void read(ByteStream stream) {
		ipVersion = stream.readUByte();
		if(ipVersion == 4) {
			ip = to!string(~stream.readUByte()) ~ "." to!string(~stream.readUByte()) ~ "." to!string(~stream.readUByte()) ~ "." to!string(~stream.readUByte());
			port = stream.readUShort();
		} else if(ipVersion == 6) {
			//Not supported yet
		}
	}
}