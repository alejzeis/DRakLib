module draklib.protocol.raknet.AcknowledgePacket;
import draklib.ByteStream;
import draklib.DRakLib;
import draklib.protocol.Packet;

class ACKPacket  : Packet {
	public static const PID = DRakLib.ACK;
	public uint[] packets;

	override {
		protected void _encode(ByteStream stream) {
			assert(packets !is null, "Packets is null");
			uint count = cast(uint) packets.length;
			uint records = 0;

			stream.setPosition(3);

			if(count > 0) {
				uint pointer = 0;
				uint start = packets[0];
				uint last = packets[0];

				while(pointer + 1 < count) {
					uint current = packets[pointer++];
					uint diff = current - last;
					if(diff == 1) {
						last = current;
					} else if(diff > 1) { //Skip duplicated packets
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

			stream.setPosition(1);
			stream.writeUShort(cast(ushort) records);

		}
		
		protected void _decode(ByteStream stream) {
			uint count = stream.readUShort();
			uint pkCount = 0;
			uint cnt = 0;
			for(uint i = 0; i < count && stream.getRemainingLength() > 0 && cnt < 4096; i++) {
				if(!cast(bool) stream.readByte()) { 
					uint start = stream.readUInt24_LE();
					uint end = stream.readUInt24_LE();
					if((end - start) > 512) {
						end = start + 512;
					}
					for(uint c = start; c <= end; c++) {
						cnt = cnt + 1;
						packets[pkCount++] = c;
					}
				} else {
					packets[pkCount++] = stream.readUInt24_LE();
				}
			}
		}
		
		public ubyte getID() {
			return PID;
		}
	}
}

class NACKPacket : ACKPacket {
	public static const PID = DRakLib.NACK;
	
	override {
		public ubyte getID() {
			return PID;
		}
	}
}