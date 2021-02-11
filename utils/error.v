module utils

// show_error prints error messae and exits
pub fn show_error(message string) {
	eprintln('\n $message')
	exit(1)
}
