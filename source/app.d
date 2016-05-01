import std.stdio;
import std.array;
import std.concurrency;

import draklib.logging;
import draklib.util;
import draklib.server.raknetserver;
import draklib.server.serverinterface;

int main() {
	ServerOptions options = ServerOptions();
	options.serverIdent = "MCPE;A DRakLib Server!;60;0.14.2;0;0";
	//options.serverIdent = "MCCPP;MINECON;A DRakLib Server";

	//Tid t = spawn(&handle);

	RakNetServer server = new RakNetServer(thisTid(), new LoggerImpl(), 19132, "0.0.0.0", options);
	server.start();

	return server.hasCrashed() ? 1 : 0;
}

void handle() {
	for(;;) {
		receive(&handler1, &handler2, &handler3);
	}
}

void handler1(SessionOpenMessage m) {
	writeln(m);
}

void handler2(SessionCloseMessage m) {
	writeln(m);
}

void handler3(SessionReceivePacketMessage m) {
	import std.format;
	writeln(format("%02X", cast(ubyte) m.payload[0]));
}

class LoggerImpl : Logger {
	override {
		const void logDebug(in string message) {
			writeln("[DEBUG]: " ~ message);
		}

		const void logInfo(in string message) {
			writeln("[INFO]: " ~ message);
		}

		const void logWarn(in string message) {
			writeln("[WARN]: " ~ message);
		}

		const void logError(in string message) {
			writeln("[ERROR]: " ~ message);
		}

		const void logTrace(in string trace) {
			foreach(string segment; split(trace, "\n")) {
				writeln("[TRACE]: " ~ segment);
			}
		}
	}
}