module draklib.util.Exception;

class InvalidParameterException : Exception {
	this() {
		super("Invalid Parameter supplied.");
	}

	this(string msg) {
		super(msg);
	}
}