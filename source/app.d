import std.stdio;
import std.array;

import draklib.logging;
import draklib.util;
import draklib.server.raknetserver;

int main() {
	//ServerOptions options = ServerOptions();
	//options.serverIdent = "MCPE;A DRakLib Server!;46;0.14.1;0;0";

	//RakNetServer server = new RakNetServer(new LoggerImpl(), 19132, "0.0.0.0", options);
	//server.start();

	//ubyte v = writeBits(cast(bool[]) [false, false, true, false, false, false, false, false]);
	//writeln(v);
    return 0;
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