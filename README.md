# odin-my-wc

Odin으로 만든 학습용 `wc` CLI 도구. Unix `wc`의 핵심 기능을 작은 범위로 재구현한다.

## 실행 방법

```bash
# 직접 실행
odin run . -- <path>

# 빌드 후 실행
odin build .
./odin-my-wc <path>
```

## 출력 형식

```
<lines> <words> <bytes> <path>
```

```bash
$ odin-my-wc sample.txt
12 53 301 sample.txt
```

## 에러 예시

```bash
$ odin-my-wc
usage: odin-my-wc <path>

$ odin-my-wc nonexistent.txt
error: failed to read file: nonexistent.txt
```

## v1 범위

- 단일 파일 입력
- 줄 수: `\n` 개수 기준
- 단어 수: ASCII 공백(space, tab, newline, carriage return) 기준
- 바이트 수: raw bytes 길이

## 제외 범위

- stdin 입력
- 다중 파일 입력
- 옵션 플래그 (`--lines`, `--words`, `--bytes`)
- 유니코드 단어 경계
- 디렉터리 재귀 탐색

## 테스트

```bash
odin test .
```
