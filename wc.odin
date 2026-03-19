package main

Counts :: struct {
	byte_count: int,
	line_count: int,
	word_count: int,
}

count_bytes :: proc(data: []u8) -> (byte_count: int) {
	return len(data)
}

count_lines :: proc(data: []u8) -> (line_count: int) {
	line_count = 0
	for i := 0; i < len(data); i += 1 {
		if data[i] == '\n' {
			line_count += 1
		}
	}
	return line_count
}

count_words :: proc(data: []u8) -> (word_count: int) {
	word_count = 0
	in_word := false
	for i := 0; i < len(data); i += 1 {
		if data[i] == ' ' || data[i] == '\t' || data[i] == '\n' || data[i] == '\r' {
			in_word = false
		} else if in_word == false {
			in_word = true
			word_count += 1
		}
	}

	return word_count
}

count_all :: proc(data: []u8) -> Counts {
	byte_count := count_bytes(data)
	line_count := count_lines(data)
	word_count := count_words(data)

	return Counts{byte_count, line_count, word_count}
}
