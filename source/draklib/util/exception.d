module draklib.util.exception;

class InvalidParameterException : Exception {
	this() {
		super("Invalid Parameter supplied.");
	}

	this(string msg) {
		super(msg);
	}
}

class IllegalOperationException : Exception {
	this(string msg) {
		super(msg);
	}
}