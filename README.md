# odin-my-wc

Odin으로 만든 학습용 `wc` CLI 도구. 파일 입력, `stdin`, 플래그 선택 출력, 다중 파일 합계를 포함해 Unix `wc`의 자주 쓰는 흐름을 작은 범위로 재구현한다.

## 실행 방법

```bash
# 단일 파일
odin run . -- sample.txt

# 여러 파일
odin run . -- sample1.txt sample2.txt

# 선택 출력
odin run . -- --lines --bytes sample.txt

# stdin
printf 'hello world\n' | odin run . --

# 빌드 후 실행
odin build .
./odin-my-wc sample.txt
```

## 출력 형식

기본 출력은 라벨이 붙은 요약 문자열이다.

```text
bytes: <n>, words: <n>, lines: <n>, chars: <n>, <path>
```

예시:

```bash
$ odin-my-wc sample.txt
bytes: 301, words: 53, lines: 12, chars: 287, sample.txt
```

여러 파일이면 각 파일 결과 뒤에 `total_` 접두사의 합계 줄이 추가된다.

```bash
$ odin-my-wc a.txt b.txt
bytes: 10, words: 2, lines: 1, chars: 10, a.txt
bytes: 20, words: 4, lines: 3, chars: 20, b.txt
total_bytes: 30, total_words: 6, total_lines: 4, total_chars: 30
```

파일 경로가 없으면 `stdin`을 읽고 경로 대신 `-`를 출력한다.

```bash
$ printf 'a🙂b\n' | odin-my-wc
bytes: 7, words: 1, lines: 1, chars: 4, -
```

## 지원 범위

- 단일 파일 입력
- 다중 파일 입력 + total 출력
- 파일 인자가 없을 때 `stdin` 입력
- `--lines`, `--words`, `--bytes`, `--chars` 플래그
- 줄 수: `\n` 개수 기준
- 단어 수: ASCII 공백(space, tab, newline, carriage return) 기준
- 바이트 수: raw bytes 길이
- 문자 수: UTF-8 rune count 기준

## 제외 범위

- 유니코드 단어 경계
- 디렉터리 재귀 탐색
- 정렬된 출력
- GNU `wc`와의 완전한 옵션 호환
- 대용량 스트리밍 최적화

## 에러 예시

```bash
$ odin-my-wc nonexistent.txt
error: failed to read file: nonexistent.txt
```

## 테스트

```bash
odin test .
```
