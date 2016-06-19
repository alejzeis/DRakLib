module draklib.protocol.packet;
import draklib.bytestream;
import draklib.util : NotImplementedException;

abstract class Packet {
	void encode(out byte[] data) @safe {
		ByteStream stream = ByteStream.alloc(getSize());
		stream.writeUByte(getID());
		_encode(stream);
		data = stream.getBuffer().dup;
		stream.clear();
	}

	void decode(byte[] data) @safe {
		ByteStream stream = ByteStream.wrap(data);
		stream.skip(1); // ID
		_decode(stream);
	}

	protected void _encode(ref ByteStream stream) @trusted {
		throw new NotImplementedException("Encoding has not been implemented by underlying class.");
	}

	protected void _decode(ref ByteStream stream) @trusted {
		throw new NotImplementedException("Decoding has not been implemented by underlying class.");
	}

	abstract size_t getSize() @safe;
	abstract ubyte getID() @safe;
}