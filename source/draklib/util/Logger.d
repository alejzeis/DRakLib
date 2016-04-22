module draklib.util.Logger;

interface Logger {
	public void logDebug(string message);
	public void logInfo(string message);
	public void logWarn(string message);
	public void logError(string message);
	public void logTrace(string fullTrace);
}