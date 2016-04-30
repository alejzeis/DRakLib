module draklib.protocol.packet;
import draklib.bytestream;
import draklib.util : NotImplementedException;

abstract class Packet {
	void encode(out byte[] data) {
		ByteStream stream = ByteStream.alloc(getSize());
		stream.writeUByte(getID());
		_encode(stream);
		data = stream.getBuffer().dup;
		stream.clear();
	}

	void decode(byte[] data) {
		ByteStream stream = ByteStream.wrap(data);
		stream.skip(1); // ID
		_decode(stream);
	}

	protected void _encode(ByteStream stream) {
		throw new NotImplementedException("Encoding has not been implemented by underlying class.");
	}

	protected void _decode(ByteStream stream) {
		throw new NotImplementedException("Decoding has not been implemented by underlying class.");
	}

	abstract uint getSize();
	abstract ubyte getID();
}