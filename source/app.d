import std.stdio;
import std.conv;
import draklib.DRakLib;
import draklib.util.Logger;
import draklib.server.RakNetServer;

int main() {
	Logger l = new LoggerImpl();
	ServerOptions options = ServerOptions();
	options.broadcastName = "MCPE;A DRakLib Server;46;0.15.0;0;0";
	RakNetServer server = new RakNetServer(l, cast(ushort) 19132, "0.0.0.0", options);
	server.start();
	return 0;
}

public class LoggerImpl : Logger {
	override {
		public void logDebug(string message) {
			writeln("[DEBUG]: " ~ message);
		}
		public void logInfo(string message) {
			writeln("[INFO]: " ~ message);
		}
		public void logWarn(string message) {
			writeln("[WARN]: " ~ message);
		}
		public void logError(string message) {
			writeln("[ERROR]: " ~ message);
		}
	}
}