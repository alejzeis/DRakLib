module draklib.bytestream;

import draklib.util;

import std.stdio;
import std.conv : to;
version(DigitalMars) { 
	import std.algorithm.mutation : reverse;
} else { // Compatibility with older GDC
	import std.algorithm : reverse;
}
import std.exception;
import std.system;

/**
 * Class that allows simple reading and writing of high
 * level types such as integers and strings to/from bytes.
 * 
 * Authors: jython234
 */ 
class ByteStream {
	private byte[] buffer;
	private uint position;
	private bool dynamic;
	private Endian endianess;

	private this(byte[] data, bool dynamic) {
		this.buffer = data;
		this.dynamic = dynamic;
		this.position = 0;
	}

	static ByteStream alloc(in uint size, in Endian endianess = Endian.bigEndian) {
		assert(size > 0);

		ByteStream stream = new ByteStream(new byte[size], false);
		stream.setEndianness(endianess);
		return stream;
	}

	static ByteStream allocDyn(in Endian endianness = Endian.bigEndian) {
		byte[] array = [];
		ByteStream stream = new ByteStream(array, true);
		stream.setEndianness(endianness);
		return stream;
	}

	static ByteStream wrap(byte[] data, in Endian endianess = Endian.bigEndian) {
		assert(data.length > 0);

		ByteStream stream = new ByteStream(data, false);
		stream.setEndianness(endianess);
		return stream;
	}

	/**
	 * Request "size" amount of bytes to be added to the buffer.
	 */
	void allocRequest(in ulong size) {
		version(ARM) { //Have to cast due to 32 bit
			this.buffer.length = this.buffer.length + cast(uint) size;
		} else {
			version(X86) { //Have to cast due to 32 bit
				this.buffer.length = this.buffer.length + cast(uint) size;
			} else {
				this.buffer.length = this.buffer.length + size;
			}
		}
	}

	/// Read "len" amount of bytes. The bytes returned have been DUPLICATED, to exactly read use readExact();
	byte[] read(in int len) {
		//assert(len > 0 && len < (getSize() - getPosition()), "Length not in bounds");
		enforce(len > 0 && len <= (getSize() - getPosition()), new OutOfBoundsException("Attempted to read " ~ to!string(len) ~ " but only " ~ to!string(getSize() - getPosition()) ~ " avaliable out of " ~ to!string(getSize())));

		int oldPos = getPosition();
		setPosition(getPosition() + len);
		return this.buffer[oldPos .. getPosition()].dup;
	}

	/// Read "len amount of bytes unsigned. The bytes returned have been DUPLICATED.
	ubyte[] readU(in int len) {
		return cast(ubyte[]) read(len);
	}

	byte[] readExact(in int len) {
		enforce(len > 0 && len <= (getSize() - getPosition()), new OutOfBoundsException("Attempted to read " ~ to!string(len) ~ " but only " ~ to!string(getSize() - getPosition()) ~ " avaliable out of " ~ to!string(getSize())));
		
		int oldPos = getPosition();
		setPosition(getPosition() + len);
		return this.buffer[oldPos .. getPosition()];
	}

	/// Write "data" to the buffer
	void write(in byte[] data) {
		assert(data.length > 0);
		if(!dynamic) enforce((data.length + getPosition()) <= getSize(), new OutOfBoundsException(to!string(data.length) ~ " needed but only " ~ to!string(getSize() - getPosition()) ~ " avaliable out of " ~ to!string(getSize())));
		else if((data.length + getPosition()) > getSize()) {
			allocRequest(data.length + getPosition());
		}

		uint counter = 0;
		for(uint i = 0; i < data.length; i++) {
			///debug writeln("i: ", i, ", counter: ", counter, ", data: ", data, "data.len: ", data.length, ", buffer.len: ", buffer.length, ", buffer: ", buffer);
			this.buffer[getPosition() + counter] = data[i];
			counter++;
		}
		this.setPosition(getPosition() + counter);
	}

	void writeU(in ubyte[] data) {
		write(cast(byte[]) data);
	}

	//Read Methods

	byte readByte() {
		return read(1)[0];
	}

	ubyte readUByte() {
		return cast(ubyte) readByte();
	}

	short readShort() {
		ubyte[] b = readU(2);
		switch(getEndianess()) {
			case Endian.bigEndian:
				return cast(short) (b[0] << 8) | b[1];
			case Endian.littleEndian:
				return cast(short) (b[1] << 8) | b[0];
			default:
				return 0;
		}
	}

	ushort readUShort() {
		return cast(ushort) readShort();
	}

	uint readUInt24_LE() {
		return (readUByte()) | (readUByte() << 8) | (readUByte() << 16);
	}

	int readInt() {
		ubyte[] b = readU(4);

		switch(getEndianess()) {
			case Endian.bigEndian:
				return ((b[0] & 0xFF) << 24) | ((b[1] & 0xFF) << 16) | ((b[2] & 0xFF) << 8) | (b[3] & 0xFF);
			case Endian.littleEndian:
				return ((b[3] & 0xFF) << 24) | ((b[2] & 0xFF) << 16) | ((b[1] & 0xFF) << 8) | (b[0] & 0xFF);
			default:
				return 0;
		}
	}

	uint readUInt() {
		return cast(uint) readInt();
	}

	long readLong() {
		ubyte[] array = cast(ubyte[]) read(8);
		switch(getEndianess()) {
			case Endian.bigEndian:
				return ((cast(long) array[0]   & 0xff) << 56) | ((cast(long) array[1] & 0xff) << 48) | ((cast(long) array[2] & 0xff) << 40) | ((cast(long) array[3] & 0xff) << 32) | ((cast(long) array[4] & 0xff) << 24) | ((cast(long) array[5] & 0xff) << 16) | ((cast(long) array[6] & 0xff) << 8) | ((cast(long) array[7] & 0xff));
			case Endian.littleEndian:
				return ((cast(long) array[7]   & 0xff) << 56) | ((cast(long) array[6] & 0xff) << 48) | ((cast(long) array[5] & 0xff) << 40) | ((cast(long) array[4] & 0xff) << 32) | ((cast(long) array[3] & 0xff) << 24) | ((cast(long) array[2] & 0xff) << 16) | ((cast(long) array[1] & 0xff) << 8) | ((cast(long) array[0] & 0xff));
			default:
				return 0;
		}
	}

	ulong readULong() {
		return cast(ulong) readLong();
	}

	string readStrUTF8() {
		ushort len = readUShort();
		return cast(string) (cast(ubyte[]) read(len));
	}

	void readSysAddress(ref string ip, ref ushort port) {
		ubyte version_ = readUByte();
		switch(version_) {
			case 4:
				ubyte[] addressBytes = readU(4);
				ip = to!string(~addressBytes[0]) ~ "." ~ to!string(~addressBytes[1]) ~ "." ~ to!string(~addressBytes[2]) ~ "." ~ to!string(~addressBytes[3]);
				port = readUShort();
				break;
			default:
				throw new DecodeException("Invalid IP version: " ~ to!string(version_));
		}
	}

	//Write methods
	void writeByte(in byte b) {
		write([b]);
	}

	void writeUByte(in ubyte b) {
		writeByte(cast(byte) b);
	}

	void writeShort(in short s) {
		switch(getEndianess()) {
			case Endian.bigEndian:
				write(cast(byte[]) [(s >> 8) & 0xFF,  s & 0xFF]);
				break;
			case Endian.littleEndian:
				write(cast(byte[]) [s & 0xFF, (s >> 8) & 0xFF]);
				break;
			default:
				break;
		}
	}

	void writeUShort(in ushort s) {
		writeShort(cast(short) s);
	}

	void writeUInt24_LE(in uint i24) {
		write(cast(byte[]) [i24 & 0xFF, (i24 >> 8) & 0xFF, (i24 >> 16) & 0xFF]);
	}

	void writeInt(in int i) {
		byte[] bytes;
		bytes.length = 4;
		bytes[0] = cast(byte) ((i >> 24) & 0xFF);
		bytes[1] = cast(byte) ((i >> 16) & 0xFF);
		bytes[2] = cast(byte) ((i >> 8) & 0xFF);
		bytes[3] = cast(byte) (i & 0xFF);

		if(getEndianess() == Endian.littleEndian) 
			reverse(bytes);

		write(bytes);
	}

	void writeUInt(in uint i) {
		writeInt(cast(int) i);
	}

	void writeLong(in long l) {
		byte[] bytes;
		bytes.length = 8;
		bytes[0] = cast(byte) ((l >> 56) & 0xFF);
		bytes[1] = cast(byte) ((l >> 48) & 0xFF);
		bytes[2] = cast(byte) ((l >> 40) & 0xFF);
		bytes[3] = cast(byte) ((l >> 32) & 0xFF);
		bytes[4] = cast(byte) ((l >> 24) & 0xFF);
		bytes[5] = cast(byte) ((l >> 16) & 0xFF);
		bytes[6] = cast(byte) ((l >> 8) & 0xFF);
		bytes[7] = cast(byte) (l & 0xFF);

		if(getEndianess() == Endian.littleEndian) 
			reverse(bytes);

		write(bytes);
	}

	void writeULong(in ulong l) {
		writeLong(cast(long) l);
	}

	void writeStrUTF8(in string s) {
		byte[] data = cast(byte[]) s;
		writeUShort(cast(ushort) data.length);
		write(data);
	}

	void writeSysAddress(in string ip, in ushort port, in ubyte version_ = 4) {
		enforce(version_ == 4, new EncodeException("Invalid IP version: " ~ to!string(version_)));

		import std.array;

		writeUByte(version_);
		foreach(s; split(ip, ".")) {
			writeUByte(~to!ubyte(s));
		}
		writeUShort(port);
	}

	//Util methods

	/**
	* Skip "bytes" amount of bytes. The buffer's
	* position will increment by that amount.
	*/
	void skip(in uint bytes) {
		setPosition(getPosition() + bytes);
	}
	
	void skip(in ulong bytes) {
		setPosition(cast(uint) (getPosition() + bytes));
	}

	void trimTo(in uint bytes) {
		enforce(getSize() - bytes > 0 && getSize() - bytes >= getPosition(), new InvalidArgumentException("Can't trim by value greater than buffer size/position: " ~ to!string(bytes) ~ ", " ~ to!string(getPosition())));
		buffer.length = bytes;
	}
	
	void clear() {
		buffer = null;
		position = 0;

	}

	//Getters/Setters

	uint getPosition() {
		return this.position;
	}

	void setPosition(in uint position) {
		this.position = position;
	}

	uint getSize() {
		return cast(uint) this.buffer.length;
	}

	uint getRemainingLength() {
		return cast(uint) (this.buffer.length - getPosition());
	}

	Endian getEndianess() {
		return this.endianess;
	}

	void setEndianness(in Endian endianess) {
		this.endianess = endianess;
	}

	byte[] getBuffer() {
		return this.buffer;
	}
}

class OutOfBoundsException : Exception {
	this() {
		super("Data is out of bounds");
	}
	
	this(string msg) {
		super(msg);
	}
}

class EncodeException : Exception {
	this(string msg) {
		super(msg);
	}
}

class DecodeException : Exception {
	this(string msg) {
		super(msg);
	}
}