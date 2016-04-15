module draklib.util.misc;

version(Posix) {
	import core.sys.linux.time;
	long getTime() {
		timeval t;
		gettimeofday(&t, null);
		
		return t.tv_sec * 1000 + t.tv_usec / 1000;
	}
} version(Windows) {
	import core.sys.windows.winbase;
	long getTime() {
		SYSTEMTIME time;
		GetSystemTime(&time);

		return (time.wSecond * 1000) + time.wMilliseconds;
	}
}