module draklib.util.Logger;

interface Logger {
	void logDebug(string message);
	void logInfo(string message);
	void logWarn(string message);
	void logError(string message);
}