package main

import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"

Options :: struct {
	file:  string `args:"pos=0,required" usage:"input file path"`,
	lines: bool `usage:"print the newline counts"`,
	words: bool `usage:"print the word counts"`,
	bytes: bool `usage:"print the byte counts"`,
}

main :: proc() {
	args := os.args

	opt: Options
	flags.parse_or_exit(&opt, args, .Unix)
	fmt.println(opt)

	path := opt.file

	data, err := read_file(path)
	if err != ReadFileError.None {
		print_file_error(err, path)
		os.exit(1)
	}
	defer delete(data)

	counts := count_all(data)

	print(counts, opt)
}

format_output :: proc(
	counts: Counts,
	path: string,
	show_lines, show_words, show_bytes: bool,
) -> string {
	parts: [dynamic]string
	defer delete(parts)

	show_all := !show_bytes && !show_words && !show_lines
	if show_all || show_bytes {
		append(&parts, fmt.tprintf("bytes: %d", counts.byte_count))
	}
	if show_all || show_words {
		append(&parts, fmt.tprintf("words: %d", counts.word_count))
	}
	if show_all || show_lines {
		append(&parts, fmt.tprintf("lines: %d", counts.line_count))
	}
	append(&parts, path)

	return strings.join(parts[:], ", ")
}


print :: proc(counts: Counts, opt: Options) {
	output := format_output(counts, opt.file, opt.lines, opt.words, opt.bytes)
	fmt.println(output)
}

// odin run . -- path 로 입력
// 빌드 후 실행
// odin build .
// ./odin-my-wc this
validate_args :: proc(args: []string) -> (string, bool) {
	// args[0] -> 프로그램 이름, args[1] -> 파일 경로

	// 인자가 0개 -> 오류
	if (len(args) < 2) {
		return "", false
	}

	// 인자가 2개 초과 -> 오류
	if (len(args) > 2) {
		return "", false
	}

	// 정상: args[1] -> 파일 경로 반환
	return args[1], true
}

print_usage :: proc() {
	fmt.eprintln("usage: odin-my-wc <path>")
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
