module draklib.protocol.raknet.ReliabilityLayer;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;

import std.math : ceil;

Reliability lookupReliability(byte reliability) {
	final switch (reliability) {
		case 0:
			return Reliability.UNRELIABLE;
		case 1:
			return Reliability.UNRELIABLE_SEQUENCED;
		case 2:
			return Reliability.RELIABLE;
		case 3:
			return Reliability.RELIABLE_ORDERED;
		case 4:
			return Reliability.RELIABLE_SEQUENCED;
		case 5:
			return Reliability.UNRELIABLE_WITH_ACK_RECEIPT;
		case 6:
			return Reliability.RELIABLE_WITH_ACK_RECEIPT;
		case 7:
			return Reliability.RELIABLE_ORDERED_WITH_ACK_RECEIPT;
	}
}


enum Reliability {
	UNRELIABLE = 0,
	UNRELIABLE_SEQUENCED = 1,
	RELIABLE = 2,
	RELIABLE_ORDERED = 3,
	RELIABLE_SEQUENCED = 4,
	UNRELIABLE_WITH_ACK_RECEIPT = 5,
	RELIABLE_WITH_ACK_RECEIPT = 6,
	RELIABLE_ORDERED_WITH_ACK_RECEIPT = 7,
}

class EncapsulatedPacket {
	public byte reliability;
	public bool split = false;
	public int messageIndex = -1;
	public int orderIndex = -1;
	public byte orderChannel = -1;
	public uint splitCount;
	public ushort splitID;
	public uint splitIndex;
	public byte[] buffer;

	public void encode(ByteStream stream) {
		stream.writeByte(cast(byte) ((reliability << 5) | (split ? 0b00010000 : 0)));
		stream.writeUShort(cast(ushort) (buffer.length * 8));
		switch(reliability) {
			case Reliability.RELIABLE:
			case Reliability.RELIABLE_SEQUENCED:
			case Reliability.RELIABLE_ORDERED:
				stream.writeUInt24_LE(messageIndex);
				goto case;
			case Reliability.UNRELIABLE_SEQUENCED:
				stream.writeUInt24_LE(orderIndex);
				stream.writeByte(orderChannel);
				break;
			default:
				break;
		}
		if(split) {
			stream.writeUInt(splitCount);
			stream.writeUShort(splitID);
			stream.writeUInt(splitIndex);
		}
		stream.write(buffer);
	}

	public void decode(ByteStream stream) {
		byte header = stream.readByte();
		reliability = (header & 0b11100000) >> 5;
		split = (header & 0b00010000) > 0;

		ushort len = cast(ushort) ceil(cast(float) stream.readUShort() / 8);
		switch(reliability) {
			case Reliability.RELIABLE:
			case Reliability.RELIABLE_SEQUENCED:
			case Reliability.RELIABLE_ORDERED:
				messageIndex = stream.readUInt24_LE();
				goto case;
			case Reliability.UNRELIABLE_SEQUENCED:
				orderIndex = stream.readUInt24_LE();
				orderChannel = stream.readByte();
				break;
			default:
				break;
		}
		if(split) {
			splitCount = stream.readUInt();
			splitID = stream.readUShort();
			splitIndex = stream.readUInt();
		}
		buffer = stream.read(len);
	}

	public ulong getLength() {
		return (3 + (messageIndex != -1 ? 3 : 0) + (orderIndex != -1 && orderChannel != -1 ? 4 :0) + (split ? 10 : 0) + buffer.length);
	}

}

abstract class CustomPacket : Packet {
	public uint sequenceNumber;
	public EncapsulatedPacket[] packets;
	
	override {
		protected void  _encode(ByteStream stream) {
			stream.writeUInt24_LE(sequenceNumber);
			foreach(EncapsulatedPacket pk; packets) {
				pk.encode(stream);
			}
		}
		
		protected void _decode(ByteStream stream) {
			sequenceNumber = stream.readUInt24_LE();
			packets = [];
			while(stream.getRemainingLength() > 0) {
				EncapsulatedPacket pk = new EncapsulatedPacket();
				pk.decode(stream);
				packets ~= pk;
			}
		}
		
		public ulong getLength() {
			ulong amount = 4;
			foreach(EncapsulatedPacket pk; packets) {
				amount += pk.getLength();
			}
			return amount;
		}
	}
}

class CustomPacket0 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_0;

	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket1 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_1;

	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket2 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_2;

	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket3 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_3;

	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket4 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_4;

	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket5 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_5;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket6 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_6;

	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket7 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_7;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket8 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_8;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacket9 : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_9;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacketA : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_A;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacketB : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_B;

	public override ubyte getID() {
		return PID;
	}
}

class CustomPacketC : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_C;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacketD : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_D;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacketE : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_E;
	
	public override ubyte getID() {
		return PID;
	}
}

class CustomPacketF : CustomPacket {
	public static const ubyte PID = DRakLib.CUSTOM_PACKET_F;
	
	public override ubyte getID() {
		return PID;
	}
}