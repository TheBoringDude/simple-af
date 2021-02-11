module main

import os
import atver

struct SAF {
mut:
	formatter_cmd string   [required]
	file_ext      string   [required]
	exclude_dirs  []string
	exclude_files []string
}

const (
	config_file = '.autoformat'
	cf_fcmd     = 'FORMATTER'
	cf_fext     = 'FILE_EXT'
	cf_edirs    = 'EXCLUDE_DIRS'
	cf_efiles   = 'EXCLUDE_FILES'
	working_dir = os.getwd()
)

// init_run checks for os arguments
fn check_args_live() bool {
	if os.args.len > 1 {
		if os.args[1] == '--live' {
			return true
		}
	}
	return false
}

// init_direct_format just directly formats all files
//   and will not watch any file changes
fn init_direct_format(saffer &SAF, temp_files []string) {
	for i in temp_files {
		t := i.split('/')
		if t[t.len - 1] in saffer.exclude_files {
			// do nothing
		} else {
			format_file(saffer.formatter_cmd, i)
		}
	}
}

// format_file runs the formatter defined in the config file
fn format_file(cmd string, filename string) {
	os.exec(cmd + ' ' + filename) or {
		eprintln('\n formatter failed: please check the FORMATTER command and try again')
	}
}

// main app
fn main() {
	// new saffer instance
	saffer := parse_config()
	mut temp_files := os.walk_ext(working_dir, saffer.file_ext)

	// run init
	if !check_args_live() {
		init_direct_format(saffer, temp_files)
		exit(0)
	}
	// new watcher instance
	mut watcher := atver.new_watcher()
	defer {
		watcher.stop()
	}

	done := chan bool{}

	// watch files

	go fn (watcher &atver.Watcher, saffer &SAF) {
		for {
			select {
				e := <-watcher.events {
					match e.op {
						.write {
							format_file(saffer.formatter_cmd, e.filename)
						}
						.delete {
							println('$e.filename is removed')
						}
					}
				}
			}
		}
	}(watcher, saffer)

	// loop to the working_dir
	// WATCHING FOLDER CHANGES IS TOO HEAVY, . THIS WILL BE IMPLMENTED IN THE FUTURE
	for i in temp_files {
		t := i.split('/')
		if t[t.len - 1] in saffer.exclude_files {
			// do nothing
		} else {
			if (i in watcher.files) == false {
				watcher.add_file(i)
			}
		}
	}

	done <- true
}

// check_config_file checks if the required config file exists or not
fn get_config_file() []string {
	cfg_file := os.join_path(working_dir, config_file)

	if os.exists(cfg_file) {
		println('loaded `$cfg_file`')
	} else {
		eprintln('\n `$config_file` is required for this to be run')
		exit(0)
	}

	contents := os.read_lines(cfg_file) or {
		eprintln('\n  cannot read contents of `$cfg_file`')
		exit(0)
	}

	return contents
}

// parse_config parse the config file from path
//   it checks if the required configurations are present or set
fn parse_config() &SAF {
	// new saf intance
	mut saf := &SAF{
		formatter_cmd: ''
		file_ext: ''
	}

	for i in get_config_file() {
		if ':' in i {
			t := i.split(':')
			attr := t[0]
			value := t[1]

			match attr {
				cf_fcmd {
					saf.formatter_cmd = value.trim_space()

					if saf.formatter_cmd == '' {
						eprintln('\n  Please set the FORMATTER in your `.autoformat` config file.')
						exit(0)
					}
				}
				cf_fext {
					saf.file_ext = value.trim_space()

					if saf.file_ext == '' {
						eprintln('\n  Please set the FILE_EXT in your `.autoformat` config file.')
						exit(0)
					}
				}
				cf_edirs {
					saf.exclude_dirs = value.split(',').map(it.trim_space())
				}
				cf_efiles {
					saf.exclude_files = value.split(',').map(it.trim_space())
				}
				else {
					// do nothing if there are unknown configurations
				}
			}
		}
	}

	return saf
}
