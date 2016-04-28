module draklib.logging;

interface Logger {
	const void logDebug(in string message);
	const void logInfo(in string message);
	const void logWarn(in string message);
	const void logError(in string message);
	const void logTrace(in string trace);
}