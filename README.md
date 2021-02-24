# simple-af
Simple Auto-Formatting utility tool.

## Usage
```bash
saf
```

### Live Auto-format
It will watch all changes being made in the folder and will format it.
```bash
saf --live
```

## `.autoformat`
**saf** requires a `.autoformat` file configu in your project dir
```
FORMATTER: v fmt -w
FILE_EXT: .v
EXCLUDE_DIRS: bin
EXCLUDE_FILES:
```
### Fields
- **`FORMATTER`** - the command for your formatter, formatters usually have the `filename` as the last argument
- **`FILE_EXT`** - the file extensions to be formatted by the formatter
- **`EXCLUDE_DIRS`** - exclude a dir to be crawled (use a comma, **`,`** to separate multiple items)
- **`EXCLUDE_FILES`** - exclude files to be formatter (use a comma, **`,`** to separate multiple items)


#### &copy; TheBoringDude