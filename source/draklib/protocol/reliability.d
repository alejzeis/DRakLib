module draklib.protocol.reliability;
import draklib.info;
import draklib.bytestream : ByteStream, OutOfBoundsException;
import draklib.protocol.packet;
import draklib.util;

/// Header for the Container Packet's PID.
/// Information taken from 
/// https://github.com/OculusVR/RakNet/blob/master/Source/ReliabilityLayer.cpp#L110

deprecated("Implementation seems to be incorrect") struct ContainerHeader {
	bool isACK;
	bool isNACK;
	bool isPacketPair;
	bool hasBAndAS;
	bool isContinuousSend;
	bool needsBAndAs;
	bool isValid;

	ubyte encode() {
		bool[] bits = new bool[8];
		bits[0] = isValid; //IsValid
		if(isACK) {
			bits[1] = true;
			bits[2] = hasBAndAS;
		} else if(isNACK) {
			bits[1] = false;
			bits[2] = true;
		} else {
			bits[1] = false;
			bits[2] = false;
			bits[3] = isPacketPair;
			bits[4] = isContinuousSend;
			bits[5] = needsBAndAs;
		}

		return writeBits(bits);
	}

	void decode(in ubyte header) {
		bool[] vals = readBits(header);
		isValid = vals[0];
		isACK = vals[1];
		if(isACK) {
			isNACK = false;
			isPacketPair = false;
			hasBAndAS = vals[2];
		} else {
			isNACK = vals[2];
			if(isNACK) {
				isPacketPair = false;
			} else {
				isPacketPair = vals[3];
				isContinuousSend = vals[4];
				needsBAndAs = vals[5];
			}
		}
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
	RELIABLE_ORDERED_WITH_ACK_RECEIPT = 7
}

class AcknowledgePacket : Packet {
	uint[] nums;

	override {
		protected void _encode(ref ByteStream stream) @trusted {
			assert(nums !is null, "no sequence numbers provided");
			uint count = cast(uint) nums.length;
			uint records = 0;

			stream.setPosition(3);
			if(count > 0) {
				uint pointer = 0;
				uint start = nums[0];
				uint last = nums[0];

				while(pointer + 1 < count) {
					uint current = nums[pointer++];
					uint diff = current - last;
					if(diff == 1) {
						last = current;
					} else if(diff > 1) { // Skip duplicated packets
						if(start == last) {
							stream.writeByte(0); // False
							stream.writeUInt24_LE(start);
							start = last = current;
						} else {
							stream.writeByte(1); // True
							stream.writeUInt24_LE(start);
							stream.writeUInt24_LE(last);
							start = last = current;
						}
						records = records + 1;
					}
				}

				if(start == last) {
					stream.writeByte(1); // True
					stream.writeUInt24_LE(start);
				} else {
					stream.writeByte(0); // False
					stream.writeUInt24_LE(start);
					stream.writeUInt24_LE(last);
				}
				records = records + 1;
			}

			size_t oldPos = stream.getPosition();

			stream.setPosition(1);
			stream.writeUShort(cast(ushort)records);
			stream.trimTo(oldPos);
		}

		protected void _decode(ref ByteStream stream) @trusted {
			nums = cast(uint[]) [];

			uint count = stream.readUShort();
			uint cnt = 0;
			for(uint i = 0; i < count && stream.getRemainingLength() > 0 && cnt < 4096; i++) {
				if(stream.readByte == 0) {
					uint start = stream.readUInt24_LE();
					uint end = stream.readUInt24_LE();
					if((end - start) > 512) {
						end = start + 512;
					}
					for(uint c = start; c <= end; c++) {
						cnt = cnt + 1;
						nums ~= c;
					}
				} else {
					nums ~= stream.readUInt24_LE();
				}
			}
		}

		size_t getSize() @safe {
			return 2048;
		}
	}
}

class ACKPacket : AcknowledgePacket {
	override {
		ubyte getID() @safe {
			return ACK;
		}
	}
}

class NACKPacket : AcknowledgePacket {
	override {
		ubyte getID() @safe {
			return NACK;
		}
	}
}

class ContainerPacket : Packet {
	//ContainerHeader header;
	ubyte header;
	uint sequenceNumber;
	EncapsulatedPacket[] packets;

	override {
		void decode(byte[] data) @safe {
			ByteStream stream = ByteStream.wrap(data);
			/*
			header = ContainerHeader();
			header.decode(stream.readUByte());
			*/
			header = stream.readUByte();
			_decode(stream);
		}

		protected void _encode(ref ByteStream stream) @trusted {
			stream.writeUInt24_LE(sequenceNumber);
			foreach(packet; packets) {
				packet._encode(stream);
			}
		}
		
		protected void _decode(ref ByteStream stream) @trusted {
			packets = cast(EncapsulatedPacket[]) [];

			sequenceNumber = stream.readUInt24_LE();
			while(stream.getRemainingLength() > 0) {
				try {
					EncapsulatedPacket ep = new EncapsulatedPacket();
					ep._decode(stream);
					packets ~= ep;
				} catch(OutOfBoundsException e) {
					debug {
						import std.stdio;
						writeln("WARNING: OutofBoundsException while processing ContainerPacket!");
					}
				}
			}
		}
		
		ubyte getID() @safe {
			return header;
		}
		
		size_t getSize() @safe {
			size_t size = 4;
			foreach(pk; packets) {
				size = size + pk.getSize();
			}
			return size;
		}
	}
}

class EncapsulatedPacket : Packet {
	byte reliability;
	bool split = false;
	int messageIndex = -1;
	int orderIndex = -1;
	byte orderChannel = -1;
	uint splitCount;
	ushort splitID;
	uint splitIndex;
	byte[] payload;

	override {
		protected void _encode(ref ByteStream stream) @trusted {
			stream.writeByte(cast(byte) ((reliability << 5) | (split ? 0b00010000 : 0)));
			stream.writeUShort(cast(ushort) (payload.length * 8));
			if(reliability > 0) {
				if(reliability >= Reliability.RELIABLE && reliability != Reliability.UNRELIABLE_WITH_ACK_RECEIPT) {
					stream.writeUInt24_LE(messageIndex);
				}
				if(reliability <= Reliability.RELIABLE_SEQUENCED && reliability != Reliability.RELIABLE) {
					stream.writeUInt24_LE(orderIndex);
					stream.writeByte(orderChannel);
				}
			}
			if(split) {
				stream.writeUInt(splitCount);
				stream.writeUShort(splitID);
				stream.writeUInt(splitIndex);
			}
			
			stream.write(payload);
		}
		
		protected void _decode(ref ByteStream stream) @trusted {
			ubyte header = stream.readUByte();
			reliability = (header & 0b11100000) >> 5;
			split = (header & 0b00010000) > 0;
			//writeln(reliability, " ", split);

			import std.math : ceil;

			ushort len = cast(ushort) ceil(cast(float) stream.readUShort() / 8);
			if(reliability > 0) {
				if(reliability >= Reliability.RELIABLE && Reliability.UNRELIABLE_WITH_ACK_RECEIPT) {
					messageIndex = stream.readUInt24_LE();
				}
				if(reliability <= Reliability.RELIABLE_SEQUENCED && reliability != Reliability.RELIABLE) {
					orderIndex = stream.readUInt24_LE();
					orderChannel = stream.readByte();
				}
			}
			if(split) {
				splitCount = stream.readUInt();
				splitID = stream.readUShort();
				splitIndex = stream.readUInt();
			}
			payload = stream.read(len);
		}
		
		ubyte getID() @safe {
			return 0;
		}
		
		size_t getSize() @safe {
			return cast(uint) (3 + (messageIndex != -1 ? 3 : 0) + ((orderIndex != -1 && orderChannel != -1) ? 4 : 0) + (split ? 10 : 0) + (payload.length));
		}
	}
}