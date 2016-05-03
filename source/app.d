import std.stdio;
import std.array;
import std.concurrency;

import draklib.logging;
import draklib.util;
import draklib.server.raknetserver;
import draklib.server.serverinterface;

Tid t;
bool go = true;
int code;

int main() {
	t = spawn(&run);
	handle();

	//return server.hasCrashed() ? 1 : 0;
	return code;
}

void run() {
	ServerOptions options = ServerOptions();
	options.serverIdent = "MCPE;A DRakLib Server!;60;0.14.2;0;0";
	//options.serverIdent = "MCCPP;MINECON;A DRakLib Server";

	RakNetServer server = new RakNetServer(ownerTid, new LoggerImpl(), 19132, "0.0.0.0", options);
	server.start();
}

void handle() {
	while(go) {
		writeln("read");
		receive(&handler1, &handler2, &handler3, &handler4);
	}
}

void handler1(SessionOpenMessage m) {
	writeln(m);
}

void handler2(SessionCloseMessage m) {
	writeln(m);
	t.send(StopServerMessage());
}

void handler3(SessionReceivePacketMessage m) {
	import std.format;
	writeln(format("%02X", cast(ubyte) m.payload[0]));
}

void handler4(ServerStoppedMessage m) {
	go = false;
	code = m.crashed ? 1 : 0;
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