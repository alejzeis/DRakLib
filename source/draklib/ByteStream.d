﻿/**
 * Author:
 * jython234 <>
 * 
 * Copyright (c) 2016  jython234
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
module draklib.ByteStream;
import std.stdio;
import std.conv;
import std.exception;
import std.system;

class ByteStream {
	private byte[] buffer;
	private uint position;
	private bool dynamic;
	private Endian endianess;
	private bool d = false;

	private this(byte[] data, bool dynamic) {
		this.buffer = data;
		this.dynamic = dynamic;
		this.position = 0;
	}

	public static ByteStream alloc(in uint size, in Endian endianess = Endian.bigEndian) {
		assert(size > 0);
		
		ByteStream stream = new ByteStream(new byte[size], false);
		stream.setEndianness(endianess);
		return stream;
	}

	public static ByteStream allocDyn(in Endian endianness = Endian.bigEndian) {
		byte[] array = [];
		ByteStream stream = new ByteStream(array, true);
		stream.setEndianness(endianness);
		return stream;
	}

	public static ByteStream wrap(byte[] data, in Endian endianess = Endian.bigEndian) {
		assert(data.length > 0);

		ByteStream stream = new ByteStream(data, false);
		stream.setEndianness(endianess);
		return stream;
	}

	/**
	 * Request "size" amount of bytes to be added to the buffer.
	 */
	public void allocRequest(in ulong size) {
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

	//Read "len" amount of bytes
	public byte[] read(in int len) {
		//assert(len > 0 && len < (getSize() - getPosition()), "Length not in bounds");
		enforce(len > 0 && len <= (getSize() - getPosition()), new OutOfBoundsException("Attempted to read " ~ to!string(len) ~ " but only " ~ to!string(getSize() - getPosition()) ~ " avaliable out of " ~ to!string(getSize())));

		if(d) writeln("reading " ~ to!string(len), " position ", getPosition(), " left ", getSize() - getPosition());

		int oldPos = getPosition();
		setPosition(getPosition() + len);
		return this.buffer[oldPos .. getPosition()].dup;
		/*
		byte[] data = new byte[len];
		uint offset = 0;
		for(uint i = 0; i < len; i++) {
			data[i] = buffer[position + offset];
			offset++;
		}
				position = position + offset;
		*/
	}

	//Write "data" to the buffer
	public void write(in byte[] data) {
		assert(data.length > 0);
		if(!dynamic) enforce((data.length + getPosition()) <= getSize(), new OutOfBoundsException(to!string(data.length) ~ " needed but only " ~ to!string(getSize() - getPosition()) ~ " avaliable out of " ~ to!string(getSize())));
		else if((data.length + getPosition()) > getSize()) {
			allocRequest(data.length + getPosition());
		}

		uint counter = 0;
		for(uint i = 0; i < data.length; i++) {
			debug if(d) writeln("i: ", i, ", counter: ", counter, ", data: ", data, "data.len: ", data.length, ", buffer.len: ", buffer.length, ", buffer: ", buffer);
			this.buffer[getPosition() + counter] = data[i];
			counter++;
		}
		this.setPosition(getPosition() + counter);
	}

	//Read Methods

	public byte readByte() {
		return read(1)[0];
	}

	public ubyte readUByte() {
		//return to!ubyte(readByte());
		return cast(ubyte) readByte();
	}

	public short readShort() {
		ubyte b1 = readUByte();
		ubyte b2 = readUByte();
		switch(getEndianess()) {
			case Endian.bigEndian:
				return cast(short) (b1 << 8) | b2;
			case Endian.littleEndian:
				return cast(short) (b2 << 8) | b1;
			default:
				return 0;
		}
	}

	public ushort readUShort() {
		return cast(ushort) readShort();
	}

	public uint readUInt24_LE() {
		return (readUByte()) | (readUByte() << 8) | (readUByte() << 16);
	}

	public int readInt() {
		ubyte b1 = readUByte();
		ubyte b2 = readUByte();
		ubyte b3 = readUByte();
		ubyte b4 = readUByte();

		switch(getEndianess()) {
			case Endian.bigEndian:
				return ((b1 & 0xFF) << 24) | ((b2 & 0xFF) << 16) | ((b3 & 0xFF) << 8) | (b4 & 0xFF);
			case Endian.littleEndian:
				return ((b4 & 0xFF) << 24) | ((b3 & 0xFF) << 16) | ((b2 & 0xFF) << 8) | (b1 & 0xFF);
			default:
				return 0;
		}
	}

	public uint readUInt() {
		return cast(uint) readInt();
	}

	public long readLong() {
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

	public ulong readULong() {
		return cast(ulong) readLong();
	}

	public string readStrUTF8() {
		ushort len = readUShort();
		return cast(string) (cast(ubyte[]) read(len));
	}

	public wstring readStrUTF16() {
		ushort len = readUShort();
		return cast(wstring) (cast(ubyte[]) read(len));
	}

	public dstring readStrUTF32() {
		ushort len = readUShort();
		return cast(dstring) (cast(ubyte[]) read(len));
	}

	//Write methods
	public void writeByte(in byte b) {
		write([b]);
	}

	public void writeUByte(in ubyte b) {
		writeByte(cast(byte) b);
	}

	public void writeShort(in short s) {
		write(cast(byte[]) [(s >> 8) & 0xFF,  s & 0xFF]);
	}

	public void writeUShort(in ushort s) {
		writeShort(cast(short) s);
	}

	public void writeUInt24_LE(in uint i24) {
		writeUByte(i24 & 0xFF);
		writeUByte((i24 >> 8) & 0xFF);
		writeUByte((i24 >> 16) & 0xFF);
	}

	public void writeInt(in int i) {
		byte[4] bytes;
		bytes[0] = cast(byte) ((i >> 24) & 0xFF);
		bytes[1] = cast(byte) ((i >> 16) & 0xFF);
		bytes[2] = cast(byte) ((i >> 8) & 0xFF);
		bytes[3] = cast(byte) (i & 0xFF);
		write(bytes);
	}

	public void writeUInt(in uint i) {
		writeInt(cast(int) i);
	}

	public void writeLong(in long l) {
		byte[8] bytes;
		bytes[0] = cast(byte) ((l >> 56) & 0xFF);
		bytes[1] = cast(byte) ((l >> 48) & 0xFF);
		bytes[2] = cast(byte) ((l >> 40) & 0xFF);
		bytes[3] = cast(byte) ((l >> 32) & 0xFF);
		bytes[4] = cast(byte) ((l >> 24) & 0xFF);
		bytes[5] = cast(byte) ((l >> 16) & 0xFF);
		bytes[6] = cast(byte) ((l >> 8) & 0xFF);
		bytes[7] = cast(byte) (l & 0xFF);
		write(bytes);
	}

	public void writeULong(in ulong l) {
		writeLong(cast(long) l);
	}

	public void writeStrUTF8(in string s) {
		byte[] data = cast(byte[]) s;
		writeUShort(cast(ushort) data.length);
		write(data);
	}

	public void writeStrUTF16(in wstring s) {
		byte[] data = cast(byte[]) s;
		writeUShort(cast(ushort) data.length);
		write(data);
	}

	public void writeStrUTF32(in dstring s) {
		byte[] data = cast(byte[]) s;
		writeUShort(cast(ushort) data.length);
		write(data);
	}

	//Util methods

	/**
	 * Skip "bytes" amount of bytes. The buffer's
	 * position will increment by that amount.
	 */
	public void skip(in uint bytes) {
		setPosition(getPosition() + bytes);
	}

	public void setDebug(bool d) {
		this.d= d;
	}

	//Getters/Setters

	public uint getPosition() {
		return this.position;
	}

	public void setPosition(in uint position) {
		this.position = position;
	}

	public uint getSize() {
		return cast(uint) this.buffer.length;
	}

	public uint getRemainingLength() {
		return cast(uint) (this.buffer.length - getPosition());
	}

	public Endian getEndianess() {
		return this.endianess;
	}

	public void setEndianness(Endian endianess) {
		this.endianess = endianess;
	}

	public byte[] getBuffer() {
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