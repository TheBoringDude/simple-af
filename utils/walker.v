module utils

import os { is_dir, is_link, join_path, ls }

// walk_ext_exclude returns a recursive list of files ending with ext
//  but excluding files under exclude path dirs
// note: this is a modified version of the modules: os.walk_ext()
pub fn walk_ext_exclude(path string, ext string, exclude []string) []string {
	if !is_dir(path) {
		return []
	}

	mut fls := []string{}
	files_paths := ls(path) or { return [] }

	for file in files_paths {
		// ignore folders starting with .
		if file.starts_with('.') || file in exclude {
			continue
		}

		p := join_path(path, file)

		if file.ends_with(ext) {
			fls << p
		}

		if is_dir(p) && !is_link(p) {
			fls << walk_ext_exclude(p, ext, exclude)
		}
	}

	return fls
}
