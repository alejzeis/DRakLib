module draklib.util.Logger;

interface Logger {
	public void logDebug(in string message);
	public void logInfo(in string message);
	public void logWarn(in string message);
	public void logError(in string message);
	public void logTrace(in string fullTrace);
}