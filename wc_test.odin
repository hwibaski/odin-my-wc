package main

import "core:fmt"
import "core:strings"
import "core:testing"

@(test)
test_empty_string :: proc(t: ^testing.T) {
	str := ""
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 0)
	testing.expect_value(t, counts.byte_count, 0)
	testing.expect_value(t, counts.char_count, 0)
}

@(test)
test_single_word :: proc(t: ^testing.T) {
	str := "hello"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 1)
	testing.expect_value(t, counts.byte_count, 5)
	testing.expect_value(t, counts.char_count, 5)
}

@(test)
test_multiple_words_single_space :: proc(t: ^testing.T) {
	str := "hello world foo"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 3)
	testing.expect_value(t, counts.byte_count, 15)
}

@(test)
test_multiple_words_multiple_spaces :: proc(t: ^testing.T) {
	str := "hello   world"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 2)
	testing.expect_value(t, counts.byte_count, 13)
}

@(test)
test_tab_included :: proc(t: ^testing.T) {
	str := "hello\tworld"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 2)
	testing.expect_value(t, counts.byte_count, 11)
}

@(test)
test_multiple_lines :: proc(t: ^testing.T) {
	str := "hello\nworld\n"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 2)
	testing.expect_value(t, counts.word_count, 2)
	testing.expect_value(t, counts.byte_count, 12)
}

@(test)
test_no_final_newline :: proc(t: ^testing.T) {
	str := "hello\nworld"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 1)
	testing.expect_value(t, counts.word_count, 2)
	testing.expect_value(t, counts.byte_count, 11)
}

@(test)
test_whitespace_only :: proc(t: ^testing.T) {
	str := "   \t\n  "
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 1)
	testing.expect_value(t, counts.word_count, 0)
	testing.expect_value(t, counts.byte_count, 7)
}

@(test)
test_korean_included :: proc(t: ^testing.T) {
	str := "안녕 세계"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 2)
	testing.expect_value(t, counts.byte_count, 13)
	testing.expect_value(t, counts.char_count, 5)
}

@(test)
test_emoji_char_count :: proc(t: ^testing.T) {
	str := "a🙂b"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.byte_count, 6)
	testing.expect_value(t, counts.char_count, 3)
}

@(test)
test_long_single_line :: proc(t: ^testing.T) {
	str := "a b c d e f g h i j"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 10)
	testing.expect_value(t, counts.byte_count, 19)
}

@(test)
test_crlf :: proc(t: ^testing.T) {
	str := "hello\r\nworld\r\n"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 2)
	testing.expect_value(t, counts.word_count, 2)
	testing.expect_value(t, counts.byte_count, 14)
}

// --- format_output 테스트 ---

make_test_counts :: proc() -> Counts {
	return Counts{byte_count = 34, line_count = 3, word_count = 5, char_count = 21}
}

@(test)
test_format_no_flags :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", false, false, false, false)
	defer delete(output)
	testing.expect_value(t, output, "bytes: 34, words: 5, lines: 3, chars: 21, temp.txt")
}

@(test)
test_format_all_flags :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", true, true, true, true)
	defer delete(output)
	testing.expect_value(t, output, "bytes: 34, words: 5, lines: 3, chars: 21, temp.txt")
}

@(test)
test_format_lines_only :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", true, false, false, false)
	defer delete(output)
	testing.expect_value(t, output, "lines: 3, temp.txt")
}

@(test)
test_format_words_only :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", false, true, false, false)
	defer delete(output)
	testing.expect_value(t, output, "words: 5, temp.txt")
}

@(test)
test_format_bytes_only :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", false, false, true, false)
	defer delete(output)
	testing.expect_value(t, output, "bytes: 34, temp.txt")
}

@(test)
test_format_chars_only :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", false, false, false, true)
	defer delete(output)
	testing.expect_value(t, output, "chars: 21, temp.txt")
}

@(test)
test_format_lines_and_bytes :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", true, false, true, false)
	defer delete(output)
	testing.expect_value(t, output, "bytes: 34, lines: 3, temp.txt")
}

@(test)
test_format_lines_and_words :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", true, true, false, false)
	defer delete(output)
	testing.expect_value(t, output, "words: 5, lines: 3, temp.txt")
}

@(test)
test_format_words_and_bytes :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "temp.txt", false, true, true, false)
	defer delete(output)
	testing.expect_value(t, output, "bytes: 34, words: 5, temp.txt")
}

// --- 다중 파일 입력 관련 테스트 ---

@(test)
test_format_with_total_prefix :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "", false, false, false, false, "total_")
	defer delete(output)
	testing.expect_value(t, output, "total_bytes: 34, total_words: 5, total_lines: 3, total_chars: 21")
}

@(test)
test_format_with_total_prefix_lines_only :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "", true, false, false, false, "total_")
	defer delete(output)
	testing.expect_value(t, output, "total_lines: 3")
}

@(test)
test_format_empty_path_no_trailing_comma :: proc(t: ^testing.T) {
	counts := make_test_counts()
	output := format_output(counts, "", false, false, false, false)
	defer delete(output)
	testing.expect_value(t, output, "bytes: 34, words: 5, lines: 3, chars: 21")
}

// --- 문자열 동적 조합 학습 테스트 ---

// 방법 1: [dynamic]string + strings.join
// 동적 배열에 조각을 append하고 join으로 합치기
@(test)
test_learn_dynamic_array_join :: proc(t: ^testing.T) {
	parts: [dynamic]string
	defer delete(parts)

	append(&parts, "hello")
	append(&parts, "world")

	result := strings.join(parts[:], " ")
	defer delete(result)

	testing.expect_value(t, result, "hello world")
}

// tprintf로 숫자를 문자열로 변환해서 동적 배열에 넣기
@(test)
test_learn_tprintf_with_dynamic_array :: proc(t: ^testing.T) {
	parts: [dynamic]string
	defer delete(parts)

	append(&parts, fmt.tprintf("%d", 3))
	append(&parts, fmt.tprintf("%d", 5))
	append(&parts, fmt.tprintf("%d", 34))

	result := strings.join(parts[:], " ")
	defer delete(result)

	testing.expect_value(t, result, "3 5 34")
}

// 조건부로 조각을 선택해서 조합하기
@(test)
test_learn_conditional_join :: proc(t: ^testing.T) {
	parts: [dynamic]string
	defer delete(parts)

	show_a := true
	show_b := false
	show_c := true

	if show_a {append(&parts, "A")}
	if show_b {append(&parts, "B")}
	if show_c {append(&parts, "C")}

	result := strings.join(parts[:], ", ")
	defer delete(result)

	testing.expect_value(t, result, "A, C")
}

// 방법 2: strings.builder
// 빌더로 문자열을 점진적으로 구성하기
@(test)
test_learn_string_builder :: proc(t: ^testing.T) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	strings.write_string(&b, "hello")
	strings.write_string(&b, " ")
	strings.write_string(&b, "world")

	result := strings.to_string(b)

	testing.expect_value(t, result, "hello world")
}

// sbprintf로 빌더에 포맷 문자열 쓰기
@(test)
test_learn_sbprintf :: proc(t: ^testing.T) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	fmt.sbprintf(&b, "%d", 3)
	strings.write_string(&b, " ")
	fmt.sbprintf(&b, "%d", 5)
	strings.write_string(&b, " ")
	fmt.sbprintf(&b, "%d", 34)

	result := strings.to_string(b)

	testing.expect_value(t, result, "3 5 34")
}

// 빌더에서 독립된 복사본 만들기 (clone)
// to_string은 빌더 내부 버퍼의 뷰, clone은 독립 복사본
@(test)
test_learn_builder_clone :: proc(t: ^testing.T) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	strings.write_string(&b, "hello")

	view := strings.to_string(b) // 빌더 내부 버퍼의 뷰
	cloned := strings.clone(view) // 독립 복사본
	defer delete(cloned)

	// 둘 다 같은 값
	testing.expect_value(t, view, "hello")
	testing.expect_value(t, cloned, "hello")
}

// 빌더로 구분자 처리 (첫 요소 전에는 구분자 없이)
@(test)
test_learn_builder_with_separator :: proc(t: ^testing.T) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	values := []int{3, 5, 34}
	first := true

	for v in values {
		if !first {
			strings.write_string(&b, " ")
		}
		fmt.sbprintf(&b, "%d", v)
		first = false
	}

	result := strings.to_string(b)

	testing.expect_value(t, result, "3 5 34")
}
