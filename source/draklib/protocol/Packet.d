/**
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
module draklib.protocol.Packet;
import draklib.ByteStream;

abstract class Packet {
	public final byte[] encode() {
		ByteStream stream;
		if(getLength() > 0) {
			stream = ByteStream.alloc(cast(uint) getLength());
		} else stream = ByteStream.allocDyn();
		stream.writeByte(getID());
		_encode(stream);
		return stream.getBuffer().dup;
	}

	public final void decode(byte[] data) {
		ByteStream stream = ByteStream.wrap(data);
		stream.readByte(); //ID
		_decode(stream);
	}

	protected void _encode(ByteStream stream) {
	}

	protected void _decode(ByteStream stream) {
	}

	/**
	 * Returns the length of the packet in bytes. If
	 * the length is negative, then the buffer will dynamically
	 * allocate extra bytes when encoding.
	 */
	public ulong getLength() {
		return -1;
	}

	public abstract ubyte getID();
}

