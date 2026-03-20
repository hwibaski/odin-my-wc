# Exit Code와 오류 처리 학습 노트

## Exit Code란?

프로그램이 종료될 때 OS에 돌려주는 **숫자 신호**입니다.

### 기본 규칙
- **0**: 프로그램이 성공적으로 완료됨
- **0이 아닌 수** (보통 1): 프로그램이 실패함
- **음수**: 시그널로 인한 종료 (예: Ctrl+C)

### 예시
```bash
odin run . sample.txt
echo $?  # 0이면 성공, 1이면 실패
```

---

## Odin에서 Exit Code 설정

### os.exit() 함수 사용

```odin
import "core:os"

main :: proc() {
    // 성공하면 0으로 종료
    os.exit(0)
    
    // 실패하면 0이 아닌 수로 종료 (보통 1)
    os.exit(1)
}
```

### Phase 2 구현 예시

```odin
main :: proc() {
    args := os.args
    path, ok := validate_args(args)
    
    if !ok {
        print_usage()
        os.exit(1)  // ← 인자 검증 실패
    }
    
    fmt.println("Processing file:", path)
    os.exit(0)  // ← 정상 종료
}
```

---

## Exit Code가 필요한 이유

### 1. 쉘 스크립트에서 조건부 실행

```bash
# program1 성공하면 program2 실행
program1 && program2

# program1 실패하면 program2 실행
program1 || program2

# 체이닝
program1 && program2 && program3
```

### 2. 파이프라인 처리

```bash
# 여러 프로그램을 조건부로 연결
./build.sh && ./test.sh && ./deploy.sh
```

### 3. 자동화 및 CI/CD

- GitHub Actions, Jenkins 등에서 프로그램 성공/실패 판단
- 빌드 파이프라인에서 다음 단계 결정

### 4. 표준 Unix 관례

- 모든 Unix/Linux 프로그램이 따르는 규칙
- 사용자와 다른 도구들의 기대치

---

## `odin run`에서 테스트하기

### 주의: 인자 전달 문제

`odin run`으로 프로그램 인자를 전달할 때는 `--` 구분자가 필요합니다.

```bash
# ❌ 잘못된 방법
odin run . sample.txt
# → "Invalid flag: sample.txt" 에러

# ✅ 올바른 방법
odin run . -- sample.txt
```

### 왜 `--`이 필요한가?

`odin run` 명령이 자신의 플래그와 프로그램의 인자를 구분하기 위해 `--`를 기준으로 나눕니다.

- `odin run .` 까지: odin 자체의 옵션
- `--` 이후: 프로그램에 전달할 인자

---

## Exit Code 테스트 방법

### Bash에서 exit code 확인

```bash
# 프로그램 실행
odin run . -- sample.txt

# 직전 프로그램의 exit code 확인
echo $?
```

### 스크립트로 자동화

```bash
#!/bin/bash

# 성공 케이스
odin run . -- sample.txt
if [ $? -eq 0 ]; then
    echo "✓ 성공 케이스 통과"
else
    echo "✗ 성공 케이스 실패"
fi

# 실패 케이스 (인자 없음)
odin run .
if [ $? -ne 0 ]; then
    echo "✓ 실패 케이스 통과"
else
    echo "✗ 실패 케이스 실패"
fi
```

---

## Phase 2에서 구현할 Exit Code 시나리오

### 시나리오 1: 인자 0개
```bash
odin run .
# 출력: usage: odin-my-wc <path>
# exit code: 1
```

### 시나리오 2: 인자 2개 이상
```bash
odin run . -- file1.txt file2.txt
# 출력: usage: odin-my-wc <path>
# exit code: 1
```

### 시나리오 3: 인자 1개 (정상)
```bash
odin run . -- sample.txt
# 출력: Will process file: sample.txt
# exit code: 0
```

---

## 체크리스트

- [ ] `os.exit()` import 확인
- [ ] 인자 검증 실패 시 `os.exit(1)` 호출
- [ ] 정상 경로에서 `os.exit(0)` 호출
- [ ] `--` 구분자를 사용하여 인자 테스트
- [ ] `echo $?`로 exit code 확인

---

## 참고

### 관련 Odin 문서
- `core:os` 패키지의 `exit` 함수
- Odin official docs

### Unix 표준
- Exit code 0: 성공
- Exit code 1-255: 오류 (일반적으로 1 사용)
- Exit code 128+: 시그널로 인한 종료

---

## context.allocator란?

### 기본 개념

`context.allocator`는 Odin에서 **메모리 할당**을 담당하는 할당자(allocator) 입니다.

- **allocator**: 메모리를 어디서, 어떻게 할당할지를 결정하는 객체
- **context**: Odin의 컨텍스트 시스템 (전역 설정 같은 것)
- **context.allocator**: 현재 스레드/프로시저의 기본 메모리 할당자

### 왜 필요한가?

Odin은 **명시적 메모리 관리** 언어입니다. 동적 메모리를 할당할 때마다 "어느 할당자를 사용할 것인가"를 명시해야 합니다.

```odin
// ❌ 에러: allocator 지정 안 함
data := make([]u8, 100)

// ✅ 올바름: allocator 지정
data := make([]u8, 100, context.allocator)
```

### 메모리 할당이 필요한 경우

1. **동적 배열 만들기**
   ```odin
   arr := make([]int, 10, context.allocator)
   ```

2. **문자열 만들기**
   ```odin
   str := strings.builder_to_string(&builder, context.allocator)
   ```

3. **구조체 포인터 할당**
   ```odin
   ptr := new(MyStruct, context.allocator)
   ```

4. **맵, 딕셔너리**
   ```odin
   m := make(map[string]int, context.allocator)
   ```

### Phase 3에서의 사용

`read_file`에서 allocator가 필요한 지점은 2곳입니다.

```odin
read_file :: proc(path: string) -> (data: []u8, err: ReadFileError) {
    file_handler, open_err := os.open(path)
    if open_err != nil {
        return nil, ReadFileError.OpenFailed
    }
    defer os.close(file_handler)

    // allocator 필요: File_Info.fullpath 내부 문자열이 할당될 수 있음
    file_info, stat_err := os.fstat(file_handler, context.allocator)
    if stat_err != nil {
        return nil, ReadFileError.ReadFailed
    }
    defer os.file_info_delete(file_info, context.allocator)

    // allocator 필요: 파일 내용을 저장할 버퍼 생성
    data = make([]u8, int(file_info.size), context.allocator)
    _, read_err := os.read_full(file_handler, data)
    if read_err != nil {
        delete(data)
        return nil, ReadFileError.ReadFailed
    }

    return data, ReadFileError.None
}
```

### allocator의 종류

Odin은 여러 종류의 allocator를 제공합니다:

1. **default allocator** (`context.allocator`)
   - 기본값, 보통 C의 malloc/free 기반
   - 대부분의 경우 이것을 사용

2. **temporary allocator** (`context.temp_allocator`)
   - 임시 메모리 (함수 종료 시 자동 정리)
   - 짧은 생명주기의 데이터에 사용

3. **arena allocator**
   - 블록 단위로 메모리를 할당하고 한 번에 정리
   - 성능 최적화에 사용

4. **커스텀 allocator**
   - 직접 만든 할당 전략

**v1에서는 `context.allocator`만 사용하면 됩니다.**

### 메모리 정리 (delete)

할당한 메모리는 반드시 정리해야 합니다:

```odin
data := make([]u8, 1000, context.allocator)

// ... 사용 ...

delete(data)  // 메모리 해제
```

`read_file`에서 특히 주의할 점은 3가지입니다.

- `os.fstat`는 `File_Info` 내부에 allocator로 할당된 문자열을 만들 수 있으므로 `os.file_info_delete(...)`가 필요합니다.
- `data`를 할당한 뒤 읽기 실패가 나면 바로 `delete(data)`를 해야 합니다.
- 성공 시 반환한 `data`의 해제 책임은 호출자에게 넘어갑니다.

### 왜 현재 구현이 완전히 안전하지 않은가?

현재 `main.odin`의 `read_file`은 학습용 골격으로는 괜찮지만, 그대로 두면 아래 문제가 남습니다.

1. `os.open` 실패를 전부 `FileNotFound`로 취급하면 권한 오류나 잘못된 경로를 구분하지 못합니다.
2. `os.fstat(..., context.allocator)` 결과를 정리하지 않으면 `File_Info.fullpath`가 누수됩니다.
3. `os.read`는 "최대 len(p)까지"만 읽으므로, 한 번만 호출하면 부분 읽기를 성공으로 오인할 수 있습니다.
4. 버퍼 할당 뒤 읽기 실패 시 `delete(data)`가 없으면 누수가 생깁니다.

### 학습용으로 안전하게 작성하는 패턴

수동으로 `open -> fstat -> read -> close` 흐름을 배우고 싶다면 아래 패턴이 안전합니다.

```odin
read_file :: proc(path: string) -> (data: []u8, err: ReadFileError) {
    file_handler, open_err := os.open(path)
    if open_err != nil {
        // v1에서는 열기 실패를 한 종류로 묶어도 안전하다.
        return nil, ReadFileError.OpenFailed
    }
    defer os.close(file_handler)

    file_info, stat_err := os.fstat(file_handler, context.allocator)
    if stat_err != nil {
        return nil, ReadFileError.ReadFailed
    }
    defer os.file_info_delete(file_info, context.allocator)

    // int 변환이 안전한지 먼저 확인
    if i64(int(file_info.size)) != file_info.size || file_info.size < 0 {
        return nil, ReadFileError.ReadFailed
    }

    data = make([]u8, int(file_info.size), context.allocator)

    // os.read는 부분 읽기가 가능하므로 read_full을 사용
    _, read_err := os.read_full(file_handler, data)
    if read_err != nil {
        delete(data)
        return nil, ReadFileError.ReadFailed
    }

    return data, ReadFileError.None
}
```

이 패턴의 핵심은 아래입니다.

- 파일 핸들은 `defer os.close(...)`로 정리한다.
- `fstat`가 만든 `File_Info`는 `defer os.file_info_delete(...)`로 정리한다.
- 실제 데이터 버퍼는 읽기 실패 시 함수 안에서 `delete(data)` 한다.
- 성공 시 반환한 버퍼는 호출자가 `delete(data)` 한다.
- `os.read` 대신 `os.read_full` 또는 직접 루프를 써서 부분 읽기를 막는다.

### 호출자의 책임

`read_file`에서 반환한 `data`는 **호출자가 정리**해야 합니다:

```odin
main :: proc() {
    data, err := read_file(path)
    if err != ReadFileError.None {
        fmt.println("error: failed to read file:", path)
        os.exit(1)
    }

    defer delete(data)

    // ... data 사용 ...

    os.exit(0)
}
```

### 더 간단한 방법: os.read_entire_file

Odin의 `os` 패키지에는 파일 읽기를 한 줄로 하는 함수가 있습니다:

```odin
read_file :: proc(path: string) -> (data: []u8, err: ReadFileError) {
    data, read_err := os.read_entire_file(path, context.allocator)
    if read_err != nil {
        return nil, ReadFileError.ReadFailed
    }
    return data, ReadFileError.None
}
```

이 방법이:
- 더 간단
- 더 안전 (부분 읽기, 크기 확인, 반복 읽기를 내부에서 처리)
- Odin 표준 방식

하지만 **학습 목적**으로는 수동 구현도 가치가 있습니다. 다만 그 경우에도 `read_full`, `file_info_delete`, 실패 시 `delete(data)`는 꼭 넣어야 합니다.

---

## 체크리스트

- [ ] `context.allocator`를 이해했다
- [ ] `make(..., context.allocator)` 패턴을 알고 있다
- [ ] 할당한 메모리를 `delete`로 정리해야 함을 안다
- [ ] 할당자의 책임 소재 (함수 vs 호출자)를 이해했다
- [ ] `os.fstat` 결과도 정리 대상이라는 점을 안다
- [ ] `os.read`와 `os.read_full`의 차이를 이해했다

---

## `string <-> []u8` 변환 정리

`odin_book_1_9_original.html` 기준으로, `string`과 `[]u8`는 메모리 레이아웃이 비슷해서 "뷰(view)"로 바꾸는 방법과 "복사본"을 만드는 방법을 구분해서 써야 합니다.

### 한눈에 보는 표

| 방향 | 방법 | 추가 할당 | 복사 | 용도 | 주의점 |
| --- | --- | --- | --- | --- | --- |
| `string -> []u8` | `transmute([]u8)(str)` | 없음 | 없음 | UTF-8 바이트 읽기 | 원본 문자열 메모리를 그대로 본다. 수정용으로 생각하면 위험 |
| `string -> []u8` | `make + copy` | 있음 | 있음 | 수정 가능한 독립 바이트 버퍼 | 호출자가 `delete`로 해제 |
| `[]u8 -> string` | `string(data)` | 없음 | 없음 | 바이트 슬라이스를 문자열로 보기 | `data`의 수명에 의존 |
| `[]u8 -> string` | `strings.clone_from_bytes(data)` | 있음 | 있음 | 오래 보관할 문자열 만들기 | 호출자가 문자열 메모리를 정리해야 함 |

### 1. `string -> []u8` 읽기 전용 바이트 뷰

```odin
import "core:fmt"

main :: proc() {
    str := "Cät=猫"
    bytes := transmute([]u8)(str)

    for b in bytes {
        fmt.println(b)
    }
}
```

- 추가 할당이 없습니다.
- UTF-8 문자열을 "문자"가 아니라 "바이트들"로 봅니다.
- 책에서는 UTF-8 인코딩된 바이트를 조사할 때 이 방식을 사용합니다.

### 2. `string -> []u8` 복사본 만들기

```odin
import "core:fmt"

main :: proc() {
    str := "Hello"

    src := transmute([]u8)(str)
    buf := make([]u8, len(src), context.allocator)
    copy(buf, src)
    defer delete(buf)

    buf[0] = 'Y'
    fmt.println(buf)
}
```

- `buf`는 독립 메모리라서 수정 가능합니다.
- 이런 경우에는 `transmute` 결과를 직접 수정하려고 하지 말고, 새 버퍼를 만들어 복사하는 편이 안전합니다.

### 3. `[]u8 -> string` 할당 없이 보기

```odin
import "core:fmt"

main :: proc() {
    data: []u8 = []u8{'H', 'e', 'l', 'l', 'o'}
    str := string(data)

    fmt.println(str)
}
```

- 책의 파일 읽기 예제 설명에서도 `string(data)`는 추가 할당 없이 문자열을 만든다고 설명합니다.
- 대신 `str`은 `data`의 바이트를 기반으로 하므로, `data`가 사라지면 `str`도 안전하지 않습니다.

### 4. `[]u8 -> string` 독립된 복사본 만들기

```odin
import "core:fmt"
import "core:strings"

main :: proc() {
    data: []u8 = []u8{'H', 'e', 'l', 'l', 'o'}
    str := strings.clone_from_bytes(data)
    defer delete(str)

    fmt.println(str)
}
```

- 오래 들고 있을 문자열이면 이 방식이 더 안전합니다.
- `strings.clone_from_bytes(data)`는 새 메모리에 문자열을 복사합니다.

### UTF-8 주의사항

`[]u8`로 보면 문자열은 문자 단위가 아니라 **UTF-8 바이트 단위**입니다.

```odin
str := "가"
bytes := transmute([]u8)(str)
fmt.println(len(bytes)) // 3
```

- 영어 알파벳은 보통 1바이트입니다.
- 한글, 한자, 이모지는 여러 바이트일 수 있습니다.
- 그래서 `bytes[0]` 같은 접근은 "첫 글자"가 아니라 "첫 바이트"를 의미합니다.

### 실전 기준 요약

- 바이트를 읽기만 할 거면 `transmute([]u8)(str)`
- 바이트를 수정해야 하면 `make + copy`
- 잠깐 문자열로 볼 거면 `string(data)`
- 오래 보관할 문자열이면 `strings.clone_from_bytes(data)`

---

## `core:flags` 패키지 학습 노트

### 개요

`core:flags`는 Odin의 런타임 타입 정보를 활용해서 struct 필드를 CLI 인자로 자동 매핑해주는 패키지입니다.

- 공식 문서: https://pkg.odin-lang.org/core/flags/

---

### 파싱 스타일

```odin
flags.Parsing_Style :: enum int {
    Odin,  // -flag, -flag:option, -flag=option
    Unix,  // --flag, --flag=argument, --flag argument
}
```

- `.Odin` (기본값): `-lines`, `-bytes` 형태
- `.Unix`: `--lines`, `--bytes` 형태 (GNU 스타일)

---

### struct 태그로 플래그 정의하기

```odin
import "core:flags"

Options :: struct {
    file:  string `args:"pos=0,required" usage:"input file path"`,
    lines: bool   `usage:"print the newline counts"`,
    words: bool   `usage:"print the word counts"`,
    bytes: bool   `usage:"print the byte counts"`,
}
```

#### `args` 태그 옵션들

| 옵션 | 설명 | 예시 |
| --- | --- | --- |
| `pos=N` | N번째 위치 인자 (0부터 시작) | `args:"pos=0"` |
| `required` | 필수 인자 | `args:"pos=0,required"` |
| `name=S` | 플래그 이름 커스텀 지정 | `args:"name=lines"` |
| `hidden` | usage 출력에서 숨김 | `args:"hidden"` |

#### `usage` 태그

플래그 설명 문자열입니다. `-h` 또는 `--help` 시 자동 출력됩니다.

#### bool 필드

- 기본값은 `false`
- 플래그 이름만 넘기면 `true`로 세팅됨 (값 불필요)
- 예: `--lines` → `opt.lines == true`

---

### `parse_or_exit` vs `parse`

두 함수의 **가장 큰 차이**는 에러 처리 방식과 인자 전달 방식입니다.

#### `parse_or_exit` — 간편 버전

```odin
parse_or_exit :: proc(
    model:        ^$T,
    program_args: [][string],   // os.args 통째로 전달
    style:        Parsing_Style = .Odin,
    allocator := context.allocator,
)
```

**사용법:**

```odin
opt: Options
flags.parse_or_exit(&opt, os.args, .Unix)
// 여기까지 왔으면 파싱 성공이 보장됨
```

**동작:**
- `os.args`를 **통째로** 넘긴다 (내부에서 `[0]` 프로그램 이름을 알아서 빼줌)
- 에러 발생 시 → stderr에 에러 메시지 + usage 출력 후 `os.exit(1)`
- `-h` / `--help` 입력 시 → usage 출력 후 `os.exit(0)`
- 별도 에러 처리 코드가 **필요 없음**

**장점:** 코드가 짧고 간결함
**단점:** 에러 메시지를 커스텀할 수 없음

#### `parse` — 수동 에러 처리 버전

```odin
parse :: proc(
    model:         ^$T,
    args:          [][string],   // os.args[1:] 으로 잘라서 전달
    style:         Parsing_Style = .Odin,
    validate_args: bool = true,
    strict:        bool = true,
    allocator := context.allocator,
) -> (error: Error)
```

**사용법:**

```odin
opt: Options
error := flags.parse(&opt, os.args[1:], .Unix)

if error != nil {
    switch e in error {
    case flags.Parse_Error:
        fmt.eprintln(e.message)
    case flags.Validation_Error:
        fmt.eprintln(e.message)
    case flags.Help_Request:
        // usage 출력
    case flags.Open_File_Error:
        // 파일 타입 필드 관련
    }
    os.exit(1)
}
```

**동작:**
- `os.args[1:]`을 넘겨야 함 (**프로그램 이름을 직접 제거**)
- 에러를 `Error` union으로 반환 → 직접 분기 처리
- `validate_args = true` (기본): `required` 필드 검증 수행
- `strict = true` (기본): 첫 에러에서 즉시 반환. `false`면 가능한 만큼 파싱 후 마지막 에러만 반환

**장점:** 에러 메시지 커스텀 가능, 세밀한 제어
**단점:** 코드가 길어짐

---

### ⚠️ 핵심 차이: 인자 전달 방식

| 함수 | 넘겨야 할 인자 | 이유 |
| --- | --- | --- |
| `parse_or_exit` | `os.args` (통째로) | 내부에서 `[0]`을 프로그램 이름으로 빼서 usage에 표시 |
| `parse` | `os.args[1:]` (잘라서) | 프로그램 이름을 직접 제거해야 함 |

```odin
// ✅ 올바른 사용
flags.parse_or_exit(&opt, os.args, .Unix)
flags.parse(&opt, os.args[1:], .Unix)

// ❌ 잘못된 사용 — pos=0에 프로그램 경로가 들어감
flags.parse_or_exit(&opt, os.args[1:], .Unix)
flags.parse(&opt, os.args, .Unix)
```

---

### Error 타입

`parse`가 반환하는 에러는 union 타입입니다:

```odin
Error :: union {
    Parse_Error,       // 값 파싱 실패, 잘못된 플래그 등
    Open_File_Error,   // os.Handle 타입 필드의 파일 열기 실패
    Help_Request,      // -h 또는 --help 입력
    Validation_Error,  // required 필드 누락
}
```

에러 메시지는 `temp_allocator`로 할당됩니다.

---

### 예약된 플래그

`-h`와 `-help`은 기본적으로 예약되어 있어서 `Help_Request` 에러를 발생시킵니다.

---

### 실전 사용 예시

```bash
# 플래그 없이 (기본 동작)
./odin-my-wc temp.txt

# 단일 플래그
./odin-my-wc --lines temp.txt

# 복수 플래그 (순서 무관)
./odin-my-wc --lines --bytes temp.txt
./odin-my-wc temp.txt --words

# 도움말
./odin-my-wc -h

# odin run으로 실행 시 (-- 구분자 필요)
odin run . -- --lines temp.txt
```

---

### 실전 기준 요약

- 간단한 CLI면 `parse_or_exit` 사용
- 커스텀 에러 메시지가 필요하면 `parse` 사용
- GNU 스타일(`--flag`)을 원하면 `.Unix` 지정
- `parse_or_exit`에는 `os.args`, `parse`에는 `os.args[1:]`
- bool 플래그는 값 없이 이름만 넘기면 `true`

---

## 문자열 동적 조합 학습 노트

여러 조각의 문자열을 조건에 따라 조합해야 할 때 두 가지 방법이 있습니다.

---

### 방법 1: `[dynamic]string` + `strings.join`

동적 배열에 문자열 조각을 `append`하고, 마지막에 `strings.join`으로 합치는 방식입니다.

```odin
import "core:fmt"
import "core:strings"

build_with_dynamic_array :: proc() -> string {
    parts: [dynamic]string
    defer delete(parts)  // 동적 배열 자체의 메모리 해제

    append(&parts, fmt.tprintf("%d", 3))    // "3"
    append(&parts, fmt.tprintf("%d", 5))    // "5"
    append(&parts, fmt.tprintf("%d", 34))   // "34"
    append(&parts, "temp.txt")

    return strings.join(parts[:], " ")  // "3 5 34 temp.txt"
}
```

#### 핵심 포인트

- `[dynamic]string` — 길이가 가변인 배열. `append`로 요소를 추가할 수 있음
- `&parts` — `append`는 배열을 변경하므로 포인터를 넘겨야 함
- `parts[:]` — 동적 배열을 슬라이스(`[]string`)로 변환. `strings.join`은 슬라이스를 받음
- `defer delete(parts)` — 동적 배열이 내부적으로 할당한 메모리를 정리
- `strings.join`의 반환값 — **새로 할당된 문자열**이므로 호출자가 `delete`로 정리해야 함

#### `fmt.tprintf`란?

```odin
fmt.tprintf("%d", 42)  // "42" 문자열 반환
```

- `fmt.printf`는 stdout에 출력하지만, `fmt.tprintf`는 문자열을 **반환**함
- **temp allocator**를 사용하므로 짧은 수명. 함수 범위 안에서 사용하기에 적합
- `fmt.aprintf`도 있음 — 이건 `context.allocator`를 사용해서 더 긴 수명

#### 메모리 정리 흐름

```odin
result := build_with_dynamic_array()
defer delete(result)  // strings.join이 할당한 문자열 정리
fmt.println(result)
```

---

### 방법 2: `strings.builder`

`strings.Builder`로 문자열을 점진적으로 구성하는 방식입니다. 하나의 버퍼에 직접 쓰므로 중간 문자열 할당이 없습니다.

```odin
import "core:fmt"
import "core:strings"

build_with_builder :: proc() -> string {
    b := strings.builder_make()
    defer strings.builder_destroy(&b)  // 빌더 내부 버퍼 정리

    strings.write_string(&b, "3")
    strings.write_string(&b, " ")
    strings.write_string(&b, "5")
    strings.write_string(&b, " ")
    strings.write_string(&b, "34")
    strings.write_string(&b, " ")
    strings.write_string(&b, "temp.txt")

    return strings.clone(strings.to_string(b))  // 독립된 복사본 반환
}
```

#### 핵심 포인트

- `strings.builder_make()` — 빌더 생성. 내부에 가변 길이 버퍼를 갖고 있음
- `strings.write_string(&b, ...)` — 버퍼 끝에 문자열 추가
- `strings.to_string(b)` — 빌더 내부 버퍼를 `string`으로 **보기** (복사 아님, 뷰)
- `strings.clone(...)` — 독립된 복사본 생성. 빌더가 파괴되어도 살아남음
- `defer strings.builder_destroy(&b)` — 빌더 내부 버퍼 메모리 정리

#### `fmt.sbprintf`로 더 간결하게

빌더에 포맷된 문자열을 직접 쓸 수도 있습니다:

```odin
b := strings.builder_make()
defer strings.builder_destroy(&b)

fmt.sbprintf(&b, "%d", 3)
strings.write_string(&b, " ")
fmt.sbprintf(&b, "%d", 5)

return strings.clone(strings.to_string(b))
```

- `fmt.sbprintf` — `strings.Builder`에 포맷 문자열을 직접 씀
- `tprintf` + `write_string`을 합친 것과 같은 효과

#### 구분자 처리를 깔끔하게

조각 사이에 구분자를 넣을 때 첫 번째 요소 전에는 구분자가 들어가면 안 됩니다:

```odin
b := strings.builder_make()
defer strings.builder_destroy(&b)

first := true
values := []int{3, 5, 34}

for v in values {
    if !first {
        strings.write_string(&b, " ")
    }
    fmt.sbprintf(&b, "%d", v)
    first = false
}

strings.write_string(&b, " temp.txt")
// 결과: "3 5 34 temp.txt"
```

---

### 두 방법 비교

| 항목 | `[dynamic]string` + `join` | `strings.builder` |
| --- | --- | --- |
| 코드 가독성 | 직관적, 배열에 추가하고 합침 | 약간 더 장황 |
| 중간 할당 | `tprintf`가 중간 문자열 생성 | 하나의 버퍼에 직접 씀 |
| 구분자 처리 | `join`이 알아서 처리 | 수동으로 넣어야 함 |
| 성능 | 조각이 적으면 차이 없음 | 조각이 많으면 더 효율적 |
| 적합한 상황 | 조건부로 조각을 선택하는 경우 | 순차적으로 문자열을 쌓아가는 경우 |

### 실전 기준 요약

- 조건에 따라 **조각을 선택**해서 합칠 때 → `[dynamic]string` + `strings.join`
- 순차적으로 **버퍼에 쌓아갈** 때 → `strings.builder`
- 성능이 중요하지 않은 학습/CLI 단계에서는 어느 쪽이든 상관없음
- 두 방법 모두 **반환된 문자열은 호출자가 `delete`로 정리**해야 함

---

## stdin 전체 읽기 학습 노트

파일과 달리 `stdin`은 길이를 미리 모를 수 있습니다. 파이프 입력은 특히 "얼마나 들어올지"를 먼저 알기 어렵기 때문에, `fstat + make + read_full` 패턴보다 `전체 읽기 유틸`이 더 편합니다.

### 가장 간단한 방식

```odin
import "core:os"

read_stdin :: proc() -> (data: []u8, ok: bool) {
    data, err := os.read_entire_file_from_file(os.stdin, context.allocator)
    if err != nil {
        return nil, false
    }
    return data, true
}
```

### 왜 이 방식이 편한가?

- `stdin` 크기를 미리 알 필요가 없음
- 내부에서 반복 읽기를 처리해줌
- `echo "hello" | program` 같은 파이프 입력에도 바로 쓸 수 있음

### 호출 쪽에서 잊기 쉬운 점

```odin
data, ok := read_stdin()
if !ok {
    os.exit(1)
}
defer delete(data)
```

- 읽은 바이트 슬라이스는 동적 메모리일 수 있으므로 `delete(data)`가 필요합니다.
- `stdin` 자체는 표준 스트림이라 직접 닫지 않습니다.

---

## UTF-8 문자 수와 바이트 수는 다르다

`len(data)`는 **바이트 수**이고, 사람이 보통 생각하는 "문자 수"와 다를 수 있습니다.

### 예시

```odin
str := "안녕"
data := transmute([]u8)(str)

fmt.println(len(data)) // 6 bytes
```

한글 2글자지만 UTF-8에서는 6바이트입니다.

### 문자 수를 세는 가장 쉬운 방법

```odin
import "core:unicode/utf8"

count_chars :: proc(data: []u8) -> int {
    return utf8.rune_count_in_bytes(data)
}
```

### `rune_count_in_bytes`가 의미하는 것

- UTF-8 code point 개수를 셉니다.
- ASCII는 보통 `bytes == chars`
- 한글, 한자, 이모지는 `bytes != chars`일 수 있음
- 잘못된 UTF-8 바이트가 있으면 그 부분도 폭 1의 에러 rune처럼 셉니다.

### 예시 감각 잡기

| 입력 | 바이트 수 | 문자 수 |
| --- | --- | --- |
| `"hello"` | 5 | 5 |
| `"안녕"` | 6 | 2 |
| `"a🙂b"` | 6 | 3 |

### 주의

이건 **grapheme cluster(사용자가 보는 글자 묶음)** 개수가 아닙니다.

예를 들어 조합형 문자 `"é"`는 화면에서는 1글자처럼 보여도 rune 기준으로는 2개일 수 있습니다. 지금 프로젝트의 `--chars`는 이 수준까지는 다루지 않고, UTF-8 rune 개수까지만 계산하면 충분합니다.

---

## 구조체 필드가 늘어나면 named literal이 더 안전하다

이번처럼 `Counts`에 `char_count`가 추가되면, 위치 기반 초기화는 바로 깨지기 쉽습니다.

### 위치 기반 초기화

```odin
Counts{0, 0, 0}
```

- 필드가 3개일 때만 맞습니다.
- 필드가 하나 추가되면 호출부를 전부 수정해야 합니다.
- 순서를 헷갈리면 컴파일은 되는데 값이 잘못 들어갈 수도 있습니다.

### named field 초기화

```odin
Counts{
    byte_count = 0,
    line_count = 0,
    word_count = 0,
    char_count = 0,
}
```

또는 기본값이 전부 0이면:

```odin
Counts{}
```

### 실전 기준

- 필드 수가 적고 순서가 절대 안 바뀌면 위치 기반도 가능
- 타입이 성장할 가능성이 있으면 named field가 안전
- 특히 테스트용 fixture나 total accumulator는 named field가 유지보수에 유리
