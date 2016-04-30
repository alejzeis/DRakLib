import std.stdio;
import std.array;
import std.concurrency;

import draklib.logging;
import draklib.util;
import draklib.server.raknetserver;

int main() {
	ServerOptions options = ServerOptions();
	options.serverIdent = "MCPE;A DRakLib Server!;60;0.14.2;0;0";
	//options.serverIdent = "MCCPP;MINECON;A DRakLib Server";

	RakNetServer server = new RakNetServer(thisTid(), new LoggerImpl(), 19132, "0.0.0.0", options);
	server.start();

	return server.hasCrashed() ? 1 : 0;
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