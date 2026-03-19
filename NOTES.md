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
