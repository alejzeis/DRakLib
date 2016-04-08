/*
 * Code is originally from JRakLibPlus,
 * https://github.com/jython234/JRakLibPlus/blob/master/src/main/java/io/github/jython234/jraklibplus/JRakLibPlus.java
 * 
 * Authors: jython234
 */
module draklib.DRakLib;
import draklib.RakSocket;

export class DRakLib {
	public const int RAKNET_VERSION = 7;
	public const byte[] RAKNET_MAGIC = [
		0x00,  0xff,  0xff, 0x00,
			 0xfe,  0xfe,  0xfe,  0xfe,
			 0xfd,  0xfd,  0xfd,  0xfd,
		0x12, 0x34, 0x56, 0x78];
	
	public const byte ID_CONNECTED_PING_OPEN_CONNECTIONS = 0x01;
	public const byte ID_UNCONNECTED_PING_OPEN_CONNECTIONS = 0x02;
	public const byte ID_OPEN_CONNECTION_REQUEST_1 = 0x05;
	public const byte ID_OPEN_CONNECTION_REPLY_1 = 0x06;
	public const byte ID_OPEN_CONNECTION_REQUEST_2 = 0x07;
	public const byte ID_OPEN_CONNECTION_REPLY_2 = 0x08;
	public const byte ID_INCOMPATIBLE_PROTOCOL_VERSION = 0x1A;
	public const byte ID_UNCONNECTED_PONG_OPEN_CONNECTIONS = 0x1C;
	public const byte ID_ADVERTISE_SYSTEM = 0x1D;
	
	public const byte CUSTOM_PACKET_0 =  0x80;
	public const byte CUSTOM_PACKET_1 =  0x81;
	public const byte CUSTOM_PACKET_2 =  0x82;
	public const byte CUSTOM_PACKET_3 =  0x83;
	public const byte CUSTOM_PACKET_4 =  0x84;
	public const byte CUSTOM_PACKET_5 =  0x85;
	public const byte CUSTOM_PACKET_6 =  0x86;
	public const byte CUSTOM_PACKET_7 =  0x87;
	public const byte CUSTOM_PACKET_8 =  0x88;
	public const byte CUSTOM_PACKET_9 =  0x89;
	public const byte CUSTOM_PACKET_A =  0x8A;
	public const byte CUSTOM_PACKET_B =  0x8B;
	public const byte CUSTOM_PACKET_C =  0x8C;
	public const byte CUSTOM_PACKET_D =  0x8D;
	public const byte CUSTOM_PACKET_E =  0x8E;
	public const byte CUSTOM_PACKET_F =  0x8F;
	
	public const byte ACK =  0xC0;
	public const byte NACK =  0xA0;
	
	public const byte MC_PING = 0x00;
	public const byte MC_PONG = 0x03;
	
	public const byte MC_CLIENT_CONNECT = 0x09;
	public const byte MC_SERVER_HANDSHAKE = 0x10;
	public const byte MC_CLIENT_HANDSHAKE = 0x13;
	public const byte MC_DISCONNECT_NOTIFICATION = 0x15;
}