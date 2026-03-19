package main

import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"

Options :: struct {
	overflow: [dynamic]string,
	lines:    bool `usage:"print the newline counts"`,
	words:    bool `usage:"print the word counts"`,
	bytes:    bool `usage:"print the byte counts"`,
}

main :: proc() {
	args := os.args

	opt: Options
	flags.parse_or_exit(&opt, args, .Unix)

	if len(opt.overflow) == 0 {
		fmt.eprintln("error: no file specified")
		os.exit(1)
	}

	total_counts := Counts{0, 0, 0}
	has_error := false

	for path in opt.overflow {
		data, err := read_file(path)
		if err != ReadFileError.None {
			print_file_error(err, path)
			has_error = true
			continue
		}
		defer delete(data)

		counts := count_all(data)

		total_counts.line_count += counts.line_count
		total_counts.word_count += counts.word_count
		total_counts.byte_count += counts.byte_count

		print_counts(counts, opt, path)
	}

	if len(opt.overflow) > 1 {
		print_counts(total_counts, opt, "", "total_")
	}

	if has_error {
		os.exit(1)
	}
}

format_output :: proc(
	counts: Counts,
	path: string,
	show_lines, show_words, show_bytes: bool,
	prefix := ""
) -> string {
	parts: [dynamic]string
	defer delete(parts)

	show_all := !show_bytes && !show_words && !show_lines
	if show_all || show_bytes {
		append(&parts, fmt.tprintf("%sbytes: %d", prefix, counts.byte_count))
	}
	if show_all || show_words {
		append(&parts, fmt.tprintf("%swords: %d", prefix, counts.word_count))
	}
	if show_all || show_lines {
		append(&parts, fmt.tprintf("%slines: %d", prefix, counts.line_count))
	}
	if path != "" {
		append(&parts, path)
	}

	return strings.join(parts[:], ", ")
}


print_counts :: proc(counts: Counts, opt: Options, path: string, prefix := "") {
	output := format_output(counts, path, opt.lines, opt.words, opt.bytes, prefix)
	defer delete(output)
	fmt.println(output)
}

print_file_error :: proc(err: ReadFileError, path: string) {
	switch err {
	case ReadFileError.None:
		// 에러 없음, 아무것도 출력 안 함
		break
	case ReadFileError.FileNotFound, ReadFileError.ReadFailed:
		fmt.eprintln("error: failed to read file:", path)
	}
}

ReadFileError :: enum {
	None = 0,
	FileNotFound,
	ReadFailed,
}

read_file :: proc(path: string) -> (data: []u8, err: ReadFileError) {
	file_handler, open_err := os.open(path)
	if open_err != nil {
		return nil, ReadFileError.FileNotFound
	}
	defer os.close(file_handler)

	file_info, stat_err := os.fstat(file_handler, context.allocator)
	if stat_err != nil {
		return nil, ReadFileError.ReadFailed
	}
	defer os.file_info_delete(file_info, context.allocator)

	data = make([]u8, int(file_info.size), context.allocator)

	_, read_err := os.read_full(file_handler, data)
	if read_err != nil {
		delete(data)
		return nil, ReadFileError.ReadFailed
	}

	return data, ReadFileError.None
}
