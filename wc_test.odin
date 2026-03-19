package main

import "core:testing"

@(test)
test_empty_string :: proc(t: ^testing.T) {
	str := ""
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 0)
	testing.expect_value(t, counts.byte_count, 0)
}

@(test)
test_single_word :: proc(t: ^testing.T) {
	str := "hello"
	data := transmute([]u8)(str)
	counts := count_all(data)
	testing.expect_value(t, counts.line_count, 0)
	testing.expect_value(t, counts.word_count, 1)
	testing.expect_value(t, counts.byte_count, 5)
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
