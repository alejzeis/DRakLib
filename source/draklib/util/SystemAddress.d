module draklib.util.SystemAddress;
import std.stdio;
import std.socket;
import std.array;
import std.conv;
import std.socket : Address, InternetAddress;

import draklib.ByteStream;
import draklib.util.exception;

struct SystemAddress {
	public ubyte ipVersion;
	public string ip;
	public ushort port;

	this(string ip, ushort port, ubyte ipVersion = 4) {
		this.ipVersion = ipVersion;
		this.ip = ip;
		this.port = port;
	}

	this(Address address) {
		switch(address.addressFamily) {
			case AddressFamily.INET: //IPv4
				ipVersion = 4;
				ip = split(address.toString(), ":")[0];
				port = to!ushort(split(address.toString(), ":")[1]);
				break;
			
			default:
				throw new InvalidParameterException("Address supplied is not IPv4");
		}
	}

	public void write(ByteStream stream) {
		stream.writeUByte(ipVersion);
		final switch(ipVersion) {
			case 4:
				foreach(string s; split(ip, ".")) {
					writeln("wrote: " ~ s);
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

	public string toString() {
		return ip ~ ":" ~ to!string(port);
	}

	public Address asAddress() {
		return new InternetAddress(ip, port);
	}
}