package braindin

import "core:os"
import "core:fmt"
import "core:io"

read_to_eof :: proc(fd: os.Handle, allocator := context.allocator) -> ([]byte, bool) {
    code: [dynamic]byte
    buf: [256]byte
    for {
        n, err := os.read(fd, buf[:])
        if err != nil {
            return code[:], false
        } else if n == 0 {
            return code[:], true
        }
        append(&code, ..buf[:n])
    }
}

main :: proc() {
    tape: [30_000]byte
    head: int
    jumps: [dynamic]int

    code, success := read_to_eof(os.stdin)
    if !success {
        fmt.eprintln("Error reading from stdin")
        return
    }
    defer delete(code)
    fmt.eprintln("Read", len(code), "bytes from stdin")

    stdin := os.stream_from_handle(os.stdin)
    reader := io.to_reader(stdin)
    stdout := os.stdout
    i := 0
    for i < len(code) {
        fmt.eprintfln("Code: %c \tHead: %d \tCell: %d", code[i], head, tape[head])
        switch (code[i]) {
        case '>': head += 1
        case '<': head -= 1
        case '+': tape[head] += 1
        case '-': tape[head] -= 1
        case '.': os.write_byte(stdout, tape[head])
        case ',': tape[head], _ = io.read_byte(reader)
        case '[':
            fmt.eprintfln("Storing jump point %d!", i)
            append(&jumps, i)
            if tape[head] == 0 {
                depth := 0
                for {
                    depth += 1 if code[i] == '[' else 0
                    depth -= 1 if code[i] == ']' else 0
                    i += 1
                    if depth == 0 {
                        break
                    }
                }
                continue
            }
        case ']':
            if tape[head] != 0 {
                new := pop(&jumps)
                fmt.eprintln("Jumping to %d!", new)
                i = new - 1
            }
        }
        i += 1
    }
    if i == len(code) {
        fmt.eprintln()
        fmt.eprintln(i)
        fmt.eprintln(tape[head])
        return
    }
}
