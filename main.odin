package main

import "core:fmt"
import "core:os"
import "core:testing"

main :: proc() {
	args := os.args
	path, ok := validate_args(args)
	if !ok {
		print_usage()
		os.exit(1)
	}

	data, err := read_file(path)
	if err != ReadFileError.None {
		print_file_error(err, path)
		os.exit(1)
	}
	defer delete(data)

	counts := count_all(data)
	fmt.printfln("%d %d %d %s", counts.line_count, counts.word_count, counts.byte_count, path)

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
