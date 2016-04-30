module draklib.util;
import std.conv;
import std.exception;

/**
 * Get the current time in milliseconds (since epoch).
 * This method uses bindings to the C functions gettimeofday and
 * GetSystemTime depending on the platform.
 */
long getTimeMillis() {
	version(Posix) {
		pragma(msg, "Using core.sys.posix.sys.time.gettimeofday() for native getTimeMillis()");
		import core.sys.posix.sys.time;
		
		timeval t;
		gettimeofday(&t, null);
		
		return t.tv_sec * 1000 + t.tv_usec / 1000;
	} else version(Windows) {
		pragma(msg, "Using core.sys.windows.winbase.GetSystemTime() for native getTimeMillis()");
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

ubyte writeBits(in bool[] bits) {
	byte val = 0;
	enforce(bits.length <= 8, new InvalidArgumentException(to!string(bits.length) ~ " bits can't fit into one byte!"));
	foreach(i, bit; bits) {
		val += bit ? (1 << i) : 0;
	}
	return val;
}

bool[] readBits(in ubyte bits) {
	import std.stdio;
	bool[] vals = new bool[8];
	for(int i = 0; i < 8; i++) {
		if(((bits  >> i) & 1) > 0) {
			vals[i] = true;
		} else {
			vals[i] = false;
		}
	}
	return vals;
}

class NotImplementedException : Exception {
	this() {
		super("Not implemented!");
	}

	this(string message) {
		super(message);
	}
}

class InvalidOperationException : Exception {
	this(string message) {
		super(message);
	}
}

class InvalidArgumentException : Exception {
	this(string message) {
		super(message);
	}
}