/**
 * Author:
 * jython234 <>
 * 
 * Copyright (c) 2016 jython234
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
module draklib.server.RakSocket;
import std.socket;

class RakSocket {
	private string bindAddress;
	private ushort bindPort;

	private UdpSocket socket;

	this(string bindAddress, ushort bindPort) {
		this.bindAddress = bindAddress;
		this.bindPort = bindPort;

		this.socket = new UdpSocket(AddressFamily.INET);
	}

	public void bind() {
		this.socket.blocking(false); //Set to not blocking

		this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.BROADCAST, true);
		this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVBUF, 1024 * 1024 * 8);
		this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDBUF, 1024 * 1024 * 8);

		this.socket.bind(new InternetAddress(this.bindAddress, this.bindPort));
	}

	public DatagramPacket recv() {
		DatagramPacket pk = DatagramPacket();
		byte[2048] payload;

		auto length = this.socket.receiveFrom(payload, SocketFlags.NONE, pk.address);
		if(length > 0) {
			pk.payload = payload[0..length];
			return pk;
		}
		return DatagramPacket();
	}

	public void send(DatagramPacket pk) {
		assert(pk.payload.sizeof > 0);
		assert(pk.address !is null);

		this.socket.sendTo(pk.payload, SocketFlags.NONE, pk.address);
	}
}

struct DatagramPacket {
	public byte[] payload;
	public Address address;
}

