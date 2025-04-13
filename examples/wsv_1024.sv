        .org $0200

start:
        ; ゼロページポインタ = $E000
        LDA #<$E000
        STA $00
        LDA #>$E000
        STA $01

        ; offset初期化
        LDA #0
        STA offset_lo
        STA offset_hi

main_loop:
        JSR print_message

        ; offset++
        INC offset_lo
        BNE skip_inc_hi
        INC offset_hi
skip_inc_hi:

        ; offset >= 1024 (0x0400) ?
        LDA offset_hi
        CMP #$04
        BCC continue
        ; リセット
        LDA #0
        STA offset_lo
        STA offset_hi
continue:
        JMP main_loop

; -----------------------------------
; 表示ルーチン: ($00),Y モードで描画
; -----------------------------------
print_message:
        LDY #0
print_loop:
        LDA message,Y
        BEQ done

        ; Y = 文字インデックス
        ; offset を $00/$01 に加算 → (indirect),Y で書き込む
        ; $00/$01 = base ($E000) + offset
        LDA offset_lo
        CLC
        ADC #<$E000
        STA $00
        LDA offset_hi
        ADC #>$E000
        STA $01

        LDA message,Y
        STA ($00),Y

        INY
        BNE print_loop
done:
        RTS

; -----------------------------------
; 変数
; -----------------------------------
offset_lo:  .res 1
offset_hi:  .res 1

; -----------------------------------
; メッセージ
; -----------------------------------
message:
        .byte " Hello, World!", 0
