        .org $0200
.org $0200

start:
        ; init
        LDA #0
        STA offset

main_loop:
        ; Wait for VSync
        .byte $FF
        JSR print_message

        ; offset++
        INC offset
        LDA offset
        CMP #227
        BCC continue_loop
        ; clear display
        JSR clear_message
        ; reset A & offset
        LDA #0
        STA offset
continue_loop:
        JMP main_loop

; -----------------------------------
; print
; -----------------------------------
print_message:
        LDY #0
        LDX offset
print_loop:
        LDA message,Y
        BEQ print_done
        STA $E000,X
        INY
        INX
        BNE print_loop
print_done:
        RTS
; -----------------------------------
; clear chars at $E0E3- (last 13 chars of 4th line)
; -----------------------------------
clear_message:
        LDA #$20
        LDX #0
clear_message_loop:
        STA $E0E3,X
        INX
        CPX #13
        BNE clear_message_loop
        RTS

; -----------------------------------
; variables
; -----------------------------------
offset: .res 1

; -----------------------------------
; message
; -----------------------------------
message:
        .byte " Hello, World!", 0
