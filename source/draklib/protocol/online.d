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
			protected void _encode(ByteStream stream) {
				stream.writeLong(GUID);
				stream.writeLong(time);
				//Extra?
			}
			
			protected void _decode(ByteStream stream) {
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
			protected void _encode(ByteStream stream) {
				internalIds = [
					0:"255.255.255.255:19132",
					1:"255.255.255.255:19132",
					2:"255.255.255.255:19132",
					3:"255.255.255.255:19132",
					4:"255.255.255.255:19132",
					5:"255.255.255.255:19132",
					6:"255.255.255.255:19132",
					7:"255.255.255.255:19132",
					8:"255.255.255.255:19132",
					9:"255.255.255.255:19132"
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
			
			protected void _decode(ByteStream stream) {
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