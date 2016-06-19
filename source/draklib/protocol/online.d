module draklib.protocol.online;
import draklib.info;
import draklib.bytestream : ByteStream, OutOfBoundsException;
import draklib.protocol.packet;

import std.array;
import std.conv;

class OnlineConnectionRequest : Packet {
	long GUID;
	long time;

	override {
		override {
			protected void _encode(ref ByteStream stream) @trusted {
				stream.writeLong(GUID);
				stream.writeLong(time);
				//Extra?
			}
			
			protected void _decode(ref ByteStream stream) @trusted {
				GUID = stream.readLong();
				time = stream.readUInt24_LE();
				//Extra?
			}
			
			ubyte getID() @safe {
				return ONLINE_CONNECTION_REQUEST;
			}
			
			size_t getSize() @safe {
				return 18;
			}
		}
	}
}

class OnlineConnectionRequestAccepted : Packet {
	string clientAddress;
	ushort clientPort;
	short sysIndex = 0;
	string[int] internalIds;
	long requestTime;
	long time;
	
	override {
		override {
			protected void _encode(ref ByteStream stream) @trusted {
				internalIds = [
					0:"127.0.0.1:0",
					1:"0.0.0.0:0",
					2:"0.0.0.0:0",
					3:"0.0.0.0:0",
					4:"0.0.0.0:0",
					5:"0.0.0.0:0",
					6:"0.0.0.0:0",
					7:"0.0.0.0:0",
					8:"0.0.0.0:0",
					9:"0.0.0.0:0",
				];

				stream.writeSysAddress(clientAddress, clientPort);
				stream.writeShort(sysIndex);
				foreach(id; internalIds.values) {
					string ip = split(id, ":")[0];
					ushort port = to!ushort(split(id, ":")[1]);
					stream.writeSysAddress(ip, port);
				}
				stream.writeLong(requestTime);
				stream.writeLong(time);
			}
			
			protected void _decode(ref ByteStream stream) @trusted {
				stream.readSysAddress(clientAddress, clientPort);
				sysIndex = stream.readShort();
				for(int i = 0; i < 10; i++) {
					string ip;
					ushort port;
					stream.readSysAddress(ip, port);
					internalIds[i] = ip ~ ":" ~ to!string(port);
				}
				requestTime = stream.readLong();
				time = stream.readLong();
			}
			
			ubyte getID() @trusted {
				return ONLINE_CONNECTION_REQUEST_ACCEPTED;
			}
			
			size_t getSize() @trusted {
				return 96;
			}
		}
	}
}