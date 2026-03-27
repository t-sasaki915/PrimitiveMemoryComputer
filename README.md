# BF-AVR
An 8-bit AVR computer whose assembly language is strangely Brainfuck

## Instruction Set
- `>` Increments physical memory pointer. It would break through the user memory space if used unsafely.
- `<` Decrements physical memory pointer. It would break through the user memory space if used unsafely.
- `+` Increments the value of the current pointer. It may call an unexpected system call if used unsafely.
- `-` Decrements the value of the current pointer. It may involve physical side effects such as desync of VGA signals if used unsafely.
- `.` Dumps the value of the current pointer, as an ASCII character (very useless indeed!)
- `,` Pauses the entire system until a keyboard input is observed and stores the ASCII character code to which correspond to the input.
