module main

import os { exists, file_last_mod_unix, getwd, join_path, read_lines }
import theboringdude.atver
import utils { show_error, walk_ext_exclude }

// main structs SAF
struct SAF {
mut:
	formatter_cmd string   [required]
	file_ext      string   [required]
	exclude_dirs  []string
	exclude_files []string
}

// constant values
const (
	config_file = '.autoformat'
	cf_fcmd     = 'FORMATTER'
	cf_fext     = 'FILES'
	cf_edirs    = 'EXCLUDE_DIRS'
	cf_efiles   = 'EXCLUDE_FILES'
	working_dir = getwd()
	cfg_file    = join_path(working_dir, config_file)
)

fn init() {
	if !exists(cfg_file) {
		show_error('`$config_file` is required for this to be run')
		exit(1)
	}
}

// check_config_file checks if the required config file exists or not
fn get_config_file() []string {
	contents := read_lines(cfg_file) or {
		show_error('cannot read contents of `$cfg_file`')
		return []
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
				}
				cf_fext {
					saf.file_ext = value.trim_space()
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

	// the formatter should be set
	if saf.formatter_cmd == '' {
		show_error('Please set the FORMATTER in your `.autoformat` config file.')
	}
	// the extensions to format should also be set
	if saf.file_ext == '' {
		show_error('Please set the FILES in your `.autoformat` config file.')
	}

	return saf
}

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
	mut fmt := true
	exec := os.execute(cmd + ' ' + filename)

	if exec.exit_code != 0 {
		eprintln('\n [$filename] formatter failed: please check the FORMATTER command and try again  \n')
		fmt = false
	}

	if fmt {
		println('>> formatted $filename')
	}
}

// main app
fn main() {
	// new saffer instance
	saffer := parse_config()
	mut temp_files := walk_ext_exclude(working_dir, saffer.file_ext, saffer.exclude_dirs)

	// run init
	init_direct_format(saffer, temp_files)

	// if --live is not present, exit
	//  else, continue
	if !check_args_live() {
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
	mut ftimestamp := file_last_mod_unix(working_dir)

	watcher_adder(mut watcher, temp_files, saffer)

	for {
		ltimestamp := file_last_mod_unix(working_dir)
		if ltimestamp > ftimestamp {
			ftimestamp = ltimestamp
			temp_files = walk_ext_exclude(working_dir, saffer.file_ext, saffer.exclude_dirs)

			watcher_adder(mut watcher, temp_files, saffer)
		}
	}

	// done, exit
	done <- true
}

// watcher_adder adds the files to the watcher
fn watcher_adder(mut watcher atver.Watcher, temp_files []string, saffer &SAF) {
	for i in temp_files {
		t := i.split('/')
		if (t[t.len - 1] in saffer.exclude_files) == false {
			if (i in watcher.files) == false {
				watcher.add_file(i)
			}
		}
	}
}
