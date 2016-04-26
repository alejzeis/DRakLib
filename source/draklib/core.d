module draklib.core;

class RakNetInfo {
	static immutable int RAKNET_PROTOCOL = 7;
	static immutable ubyte[] RAKNET_MAGIC = [
	0x00,  0xff,  0xff, 0x00,
	 0xfe,  0xfe,  0xfe,  0xfe,
	 0xfd,  0xfd,  0xfd,  0xfd,
	0x12, 0x34, 0x56, 0x78];

	static immutable ubyte UNCONNECTED_PING_1 = 0x01;
	static immutable ubyte UNCONNECTED_PING_2 = 0x02;
	static immutable ubyte OFFLINE_CONNECTION_REQUEST_1 = 0x05;
	static immutable ubyte OFFLINE_CONNECTION_RESPONSE_1 = 0x06;
	static immutable ubyte OFFLINE_CONNECTION_REQUEST_2 = 0x07;
	static immutable ubyte OFFLINE_CONNECTION_RESPONSE_2 = 0x08;
	static immutable ubyte UNCONNECTED_PONG = 0x1C;
	static immutable ubyte ADVERTISE_SYSTEM = 0x1D;

	/*
	static immutable ubyte FRAME_PACKET_0 =  0x80;
	static immutable ubyte FRAME_PACKET_1 =  0x81;
	static immutable ubyte FRAME_PACKET_2 =  0x82;
	static immutable ubyte FRAME_PACKET_3 =  0x83;
	static immutable ubyte FRAME_PACKET_4 =  0x84;
	static immutable ubyte FRAME_PACKET_5 =  0x85;
	static immutable ubyte FRAME_PACKET_6 =  0x86;
	static immutable ubyte FRAME_PACKET_7 =  0x87;
	static immutable ubyte FRAME_PACKET_8 =  0x88;
	static immutable ubyte FRAME_PACKET_9 =  0x89;
	static immutable ubyte FRAME_PACKET_A =  0x8A;
	static immutable ubyte FRAME_PACKET_B =  0x8B;
	static immutable ubyte FRAME_PACKET_C =  0x8C;
	static immutable ubyte FRAME_PACKET_D =  0x8D;
	static immutable ubyte FRAME_PACKET_E =  0x8E;
	static immutable ubyte FRAME_PACKET_F =  0x8F;
	*/

	static immutable ubyte ACK =  0xC0;
	static immutable ubyte NACK =  0xA0;

	static immutable ubyte CONNECTED_PING = 0x00;
	static immutable ubyte CONNECTED_PONG = 0x03;

	static immutable ubyte ONLINE_CONNECTION_REQUEST = 0x09;
	static immutable ubyte ONLINE_CONNECTION_REQUEST_ACCEPTED = 0x10;
	//static immutable ubyte MC_CLIENT_HANDSHAKE = 0x13;
	static immutable ubyte DISCONNECT_NOTIFICATION = 0x15;
}