module draklib.util.util;

version(Posix) {
	import std.c.linux.linux;
	long getTime() {
		timeval t;
		gettimeofday(&t, null);
		
		return t.tv_sec * 1000 + t.tv_usec / 1000;
	}
} else {
	//TODO
}