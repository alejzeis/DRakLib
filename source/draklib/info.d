module draklib.info;

immutable int RAKNET_PROTOCOL = 6;
immutable ubyte[] RAKNET_MAGIC = [
0x00,  0xff,  0xff, 0x00,
 0xfe,  0xfe,  0xfe,  0xfe,
 0xfd,  0xfd,  0xfd,  0xfd,
0x12, 0x34, 0x56, 0x78];

immutable ubyte UNCONNECTED_PING_1 = 0x01;
immutable ubyte UNCONNECTED_PING_2 = 0x02;
immutable ubyte OFFLINE_CONNECTION_REQUEST_1 = 0x05;
immutable ubyte OFFLINE_CONNECTION_RESPONSE_1 = 0x06;
immutable ubyte OFFLINE_CONNECTION_REQUEST_2 = 0x07;
immutable ubyte OFFLINE_CONNECTION_RESPONSE_2 = 0x08;
immutable ubyte UNCONNECTED_PONG = 0x1C;
immutable ubyte ADVERTISE_SYSTEM = 0x1D;

immutable ubyte ACK =  0xC0;
immutable ubyte NACK =  0xA0;

immutable ubyte CONNECTED_PING = 0x00;
immutable ubyte CONNECTED_PONG = 0x03;

immutable ubyte ONLINE_CONNECTION_REQUEST = 0x09;
immutable ubyte ONLINE_CONNECTION_REQUEST_ACCEPTED = 0x10;
immutable ubyte DISCONNECT_NOTIFICATION = 0x15;