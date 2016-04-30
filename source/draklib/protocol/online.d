module draklib.protocol.online;
import draklib.core : RakNetInfo;
import draklib.bytestream : ByteStream, OutOfBoundsException;
import draklib.protocol.packet;

import std.array;
import std.conv;

class OnlineConnectionRequest : Packet {
	long GUID;
	long time;

	override {
		override {
			protected void _encode(ref ByteStream stream) {
				stream.writeLong(GUID);
				stream.writeLong(time);
				//Extra?
			}
			
			protected void _decode(ref ByteStream stream) {
				GUID = stream.readLong();
				time = stream.readUInt24_LE();
				//Extra?
			}
			
			ubyte getID() {
				return RakNetInfo.ONLINE_CONNECTION_REQUEST;
			}
			
			uint getSize() {
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
			protected void _encode(ref ByteStream stream) {
				internalIds = [
					0:"127.0.0.1:19132",
					1:"0.0.0.0:19132",
					2:"0.0.0.0:19132",
					3:"0.0.0.0:19132",
					4:"0.0.0.0:19132",
					5:"0.0.0.0:19132",
					6:"0.0.0.0:19132",
					7:"0.0.0.0:19132",
					8:"0.0.0.0:19132",
					9:"0.0.0.0:19132",
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
			
			protected void _decode(ref ByteStream stream) {
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
			
			ubyte getID() {
				return RakNetInfo.ONLINE_CONNECTION_REQUEST_ACCEPTED;
			}
			
			uint getSize() {
				return 96;
			}
		}
	}
}