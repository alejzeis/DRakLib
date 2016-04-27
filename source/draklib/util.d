module draklib.util;
import std.exception;

/**
 * Get the current time in milliseconds (since epoch).
 * This method uses bindings to the C functions gettimeofday and
 * GetSystemTime depending on the platform.
 */
long getTimeMillis() {
	version(Posix) {
		//import core.sys.linux.time; //Does not seem to work
		import std.c.linux.linux;
		
		timeval t;
		gettimeofday(&t, null);
		
		return t.tv_sec * 1000 + t.tv_usec / 1000;
	} version(Windows) {
		import core.sys.windows.winbase;
		
		SYSTEMTIME time;
		GetSystemTime(&time);
		
		return (time.wSecond * 1000) + time.wMilliseconds;
	}
}

/**
 * Split a byte array into multiple arrays of sizes
 * specified by "chunkSize"
 */
byte[][] splitByteArray(byte[] array, in uint chunkSize) {
	//TODO: optimize to not use GC
	byte[][] splits = cast(byte[][]) [[]];
	uint chunks = 0;
	for(int i = 0; i < array.length; i += chunkSize) {
		if((array.length - i) > chunkSize) {
			splits[chunks] = array[i..i+chunkSize];
		} else {
			splits[chunks] = array[i..array.length];
		}
		chunks++;
	}
	
	return splits;
}

class NotImplementedException : Exception {
	this() {
		super("Not implemented!");
	}

	this(string message) {
		super(message);
	}
}