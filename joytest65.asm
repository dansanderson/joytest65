!cpu m65
!to "joytest65.prg", cbm

* = $2001

!8 $12,$20,$0a,$00,$fe,$02,$20,$30,$3a,$9e,$20
!pet "$2014"
!8 $00,$00,$00

init:
    ; Print a sequence of PETSII codes through the screen terminal
    ldx #0
-   lda screen_setup_petscii,x
    jsr $ffd2
    inx
    cpx #screen_setup_petscii_end-screen_setup_petscii
    bne -

    ; Copy initial layout to screen via DMA
    lda #0
    sta $d704
    lda #^display_data_dmajob
    sta $d702
    lda #>display_data_dmajob
    sta $d701
    lda #<display_data_dmajob
    sta $d705

loop:
    inc $d020
    jsr read_joystick_ports
    dec $d020
    jsr update_display

    ; Wait to a spot in the frame
-   lda $d012
    cmp #$ff
    bne -

    bra loop

disp:
    ; $fc-$fd = 16-bit addr of: (screen offset, screen code, attr code)
    ; $fb = offset to add to screen offset
    ldy #0
    lda ($fc),y
    clc
    adc $fb
    sta $1600
    iny
    lda ($fc),y
    adc #0
    sta $1601  ; ($1600) = screen offset + offset
    iny
    lda ($fc),y
    sta $1602  ; screen code
    iny
    lda ($fc),y
    sta $1603  ; attr code

    ; Plot attr: 1.f800 + ($1600)
    lda #$00
    clc
    adc $1600
    sta $fc
    lda #$f8
    adc $1601
    sta $fd
    lda #$01
    adc #$00
    sta $fe
    lda #$00
    sta $ff   ; [$fc] = attr address
    lda $1603
    ldz #0
    sta [$fc],z

    ; Plot char: [$d060] + ($1600)
    lda $d060
    clc
    adc $1600
    sta $fc
    lda $d061
    adc $1601
    sta $fd
    lda $d062
    adc #$00
    sta $fe
    lda $d063
    and #$0f
    sta $ff   ; [$fc] = char address
    lda $1602
    ldz #0
    sta [$fc],z

    rts

!macro disp_indicator seqaddr {
    lda #<seqaddr
    sta $fc
    lda #>seqaddr
    sta $fd
    jsr disp
}

!macro disp_indicator_bitmask val, mask, comp, off, on {
    lda val
    and #mask
    cmp #comp
    beq +
    +disp_indicator off
    bra ++
+   +disp_indicator on
++
}

update_display:

    lda #joy1_offset
    sta $fb

    +disp_indicator_bitmask joystick1, %00001101, %00001000, joy_ul_off, joy_ul_on
    +disp_indicator_bitmask joystick1, %00001101, %00001100, joy_u1_off, joy_u1_on
    +disp_indicator_bitmask joystick1, %00001101, %00001100, joy_u2_off, joy_u2_on
    +disp_indicator_bitmask joystick1, %00001101, %00000100, joy_ur_off, joy_ur_on
    +disp_indicator_bitmask joystick1, %00000111, %00000011, joy_l1_off, joy_l1_on
    +disp_indicator_bitmask joystick1, %00000111, %00000011, joy_l2_off, joy_l2_on
    +disp_indicator_bitmask joystick1, %00001011, %00000011, joy_r1_off, joy_r1_on
    +disp_indicator_bitmask joystick1, %00001011, %00000011, joy_r2_off, joy_r2_on
    +disp_indicator_bitmask joystick1, %00001110, %00001000, joy_dl_off, joy_dl_on
    +disp_indicator_bitmask joystick1, %00001110, %00001100, joy_d1_off, joy_d1_on
    +disp_indicator_bitmask joystick1, %00001110, %00001100, joy_d2_off, joy_d2_on
    +disp_indicator_bitmask joystick1, %00001110, %00000100, joy_dr_off, joy_dr_on
    +disp_indicator_bitmask joystick1, %00010000, %00000000, joy_b1_off, joy_b1_on
    +disp_indicator_bitmask joystick1, %00000011, %00000000, joy_b4_off, joy_b4_on
    +disp_indicator_bitmask joystick1, %00001100, %00000000, joy_b5_off, joy_b5_on

    lda paddle1a
    cmp #$10
    bcc +
    +disp_indicator joy_b2_off
    bra ++
+   +disp_indicator joy_b2_on
++

    lda paddle1b
    cmp #$10
    bcc +
    +disp_indicator joy_b3_off
    bra ++
+   +disp_indicator joy_b3_on
++

    lda #joy2_offset
    sta $fb

    +disp_indicator_bitmask joystick2, %00001101, %00001000, joy_ul_off, joy_ul_on
    +disp_indicator_bitmask joystick2, %00001101, %00001100, joy_u1_off, joy_u1_on
    +disp_indicator_bitmask joystick2, %00001101, %00001100, joy_u2_off, joy_u2_on
    +disp_indicator_bitmask joystick2, %00001101, %00000100, joy_ur_off, joy_ur_on
    +disp_indicator_bitmask joystick2, %00000111, %00000011, joy_l1_off, joy_l1_on
    +disp_indicator_bitmask joystick2, %00000111, %00000011, joy_l2_off, joy_l2_on
    +disp_indicator_bitmask joystick2, %00001011, %00000011, joy_r1_off, joy_r1_on
    +disp_indicator_bitmask joystick2, %00001011, %00000011, joy_r2_off, joy_r2_on
    +disp_indicator_bitmask joystick2, %00001110, %00001000, joy_dl_off, joy_dl_on
    +disp_indicator_bitmask joystick2, %00001110, %00001100, joy_d1_off, joy_d1_on
    +disp_indicator_bitmask joystick2, %00001110, %00001100, joy_d2_off, joy_d2_on
    +disp_indicator_bitmask joystick2, %00001110, %00000100, joy_dr_off, joy_dr_on
    +disp_indicator_bitmask joystick2, %00010000, %00000000, joy_b1_off, joy_b1_on
    +disp_indicator_bitmask joystick2, %00000011, %00000000, joy_b4_off, joy_b4_on
    +disp_indicator_bitmask joystick2, %00001100, %00000000, joy_b5_off, joy_b5_on

    lda paddle2a
    cmp #$10
    bcc +
    +disp_indicator joy_b2_off
    bra ++
+   +disp_indicator joy_b2_on
++

    lda paddle2b
    cmp #$10
    bcc +
    +disp_indicator joy_b3_off
    bra ++
+   +disp_indicator joy_b3_on
++

    ; TODO: write joy bits
    ; TODO: write joy hex
    ; TODO: write joy basfunc dec
    ; TODO: write paddle hex
    ; TODO: write paddle dec
    ; TODO: draw paddle bar

    rts

read_joystick_ports:
    ; Disable interrupts
    sei

    ; Lock out the keyboard lines
    lda #$ff
    sta $dc00

    ; Read joystick port 1 state
    lda $dc01
    and #%00011111
    sta joystick1

    ; Read joystick port 2 state
    lda $dc00
    and #%00011111
    sta joystick2

    ; Down-clock MEGA65 CPU to 1 MHz
    ; FAST $D031.6 -> 0
    lda #$40
    trb $d031

    ; Connect SID to port 1 analog inputs
    lda #%01000000
    sta $dc00

    ; Wait for SID to read, ~512 1 MHz cycles
    ldx #$00
-   inx
    bne -

    ; Read port 1 paddles, with debounce
-   lda $d419
    cmp $d419
    bne -
    sta paddle1a
-   lda $d41a
    cmp $d41a
    bne -
    sta paddle1b

    ; Connect SID to port 2 analog inputs
    lda #%10000000
    sta $dc00

    ; Wait for SID to read, ~512 1 MHz cycles
    ldx #$00
-   inx
    bne -

    ; Read port 2 paddles, with debounce
-   lda $d419
    cmp $d419
    bne -
    sta paddle2a
-   lda $d41a
    cmp $d41a
    bne -
    sta paddle2b

    ; Reset MEGA65 CPU to 40 MHz
    ; FAST $D031.6 -> 1
    lda #$40
    tsb $d031
    ; tsb $d054

    ; Restore keyboard lines
    ; (POT() does this but I'm not sure it's necessary.)
    lda #$7f
    sta $dc00

    ; Re-enable interrupts
    cli

    rts

; Joystick state variables
;
; Bit 0: Up
; Bit 1: Down
; Bit 2: Left
; Bit 3: Right
; Bit 4: Button A
joystick1: !byte $00
joystick2: !byte $00

; Paddle state variables, $00-$ff
;
; Paddle fire buttons are in the joystick values:
; Bit 1: Paddle A fire
; Bit 2: Paddle B fire
;
; For a three-button gamepad:
; Paddle A < $7f: Button B
; Paddle B < $7f: Button C
paddle1a:  !byte $00
paddle1b:  !byte $00
paddle2a:  !byte $00
paddle2b:  !byte $00

screen_setup_petscii:
!pet 5,147,27,"8",11,142
screen_setup_petscii_end:

display_data:
!scr "                        joystick and paddle tester v0.1                         "
!scr "                                                                                "
!scr "                       joystick 1             joystick 2                        "
!scr "                                                                                "
!scr "                         - -- -                 - -- -                          "
!scr "                                                                                "
!scr "                         -    -                 -    -                          "
!scr "                         -    -                 -    -                          "
!scr "                                                                                "
!scr "                         - -- -                 - -- -                          "
!scr "                                                                                "
!scr "                     1:-   2:-   3:-        1:-   2:-   3:-                     "
!scr "                        4:-   5:-              4:-   5:-                        "
!scr "                                                                                "
!scr "                   $dc00: %---00000 $00   $dc01: %---00000 $00                  "
!scr "                   joy(1): 000            joy(2): 000                           "
!scr "                                                                                "
!scr "                                                       pot(n) / $d419 / $d41a   "
!scr "  paddle 1 (1a): [                                           ] $00 000          "
!scr "  paddle 2 (1b): [                                           ] $00 000          "
!scr "  paddle 3 (2a): [                                           ] $00 000          "
!scr "  paddle 4 (2b): [                                           ] $00 000          "
display_data_end:

display_data_dmajob:
!byte $0b, $00
!byte $00
!word display_data_end-display_data
!word display_data
!byte $00
!word $0800
!byte $00, $00, $00, $00

joy1_offset = 0
joy2_offset = 23

; Indicator updates are described as:
; - uint16: Screen memory offset (joy 1)
; - uint8: Char screen code
; - uint8: Char attribute ($01=white, $21=reverse white)
joy_ul_on:  !word (4*80 + 25)
            !byte $69, $07
joy_ul_off: !word (4*80 + 25)
            !byte $4f, $0e
joy_u1_on:  !word (4*80 + 27)
            !byte $69, $27
joy_u2_on:  !word (4*80 + 28)
            !byte $5f, $27
joy_u1_off: !word (4*80 + 27)
            !byte $4e, $0e
joy_u2_off: !word (4*80 + 28)
            !byte $4d, $0e
joy_ur_on:  !word (4*80 + 30)
            !byte $5f, $07
joy_ur_off: !word (4*80 + 30)
            !byte $50, $0e
joy_l1_on:  !word (6*80 + 25)
            !byte $69, $27
joy_l2_on:  !word (7*80 + 25)
            !byte $5f, $07
joy_l1_off: !word (6*80 + 25)
            !byte $4e, $0e
joy_l2_off: !word (7*80 + 25)
            !byte $4d, $0e
joy_r1_on:  !word (6*80 + 30)
            !byte $5f, $27
joy_r2_on:  !word (7*80 + 30)
            !byte $69, $07
joy_r1_off: !word (6*80 + 30)
            !byte $4d, $0e
joy_r2_off: !word (7*80 + 30)
            !byte $4e, $0e
joy_dl_on:  !word (9*80 + 25)
            !byte $5f, $27
joy_dl_off: !word (9*80 + 25)
            !byte $4c, $0e
joy_d1_on:  !word (9*80 + 27)
            !byte $5f, $07
joy_d2_on:  !word (9*80 + 28)
            !byte $69, $07
joy_d1_off: !word (9*80 + 27)
            !byte $4d, $0e
joy_d2_off: !word (9*80 + 28)
            !byte $4e, $0e
joy_dr_on:  !word (9*80 + 30)
            !byte $69, $27
joy_dr_off: !word (9*80 + 30)
            !byte $7a, $0e
joy_b1_on:  !word (11*80 + 23)
            !byte $51, $07
joy_b1_off: !word (11*80 + 23)
            !byte $57, $0e
joy_b2_on:  !word (11*80 + 29)
            !byte $51, $07
joy_b2_off: !word (11*80 + 29)
            !byte $57, $0e
joy_b3_on:  !word (11*80 + 35)
            !byte $51, $07
joy_b3_off: !word (11*80 + 35)
            !byte $57, $0e
joy_b4_on:  !word (12*80 + 26)
            !byte $51, $07
joy_b4_off: !word (12*80 + 26)
            !byte $57, $0e
joy_b5_on:  !word (12*80 + 32)
            !byte $51, $07
joy_b5_off: !word (12*80 + 32)
            !byte $57, $0e

; Numbers and paddle bars are located by screen memory offset (uint16).
; Joystick-related values refer to joy 1.
joy_cia_5bits:   !word (14*80 + 30)
joy_cia_hex:     !word (14*80 + 37)
joy_basfunc_dec: !word (15*80 + 27)
pad1_val_hex:    !word (18*80 + 64)
pad2_val_hex:    !word (19*80 + 64)
pad3_val_hex:    !word (20*80 + 64)
pad4_val_hex:    !word (21*80 + 64)
pad1_bar:        !word (18*80 + 18)
pad2_bar:        !word (19*80 + 18)
pad3_bar:        !word (20*80 + 18)
pad4_bar:        !word (21*80 + 18)

; Each step is one screen code and one char attr.
bar_steps:
!byte $20, $00
!byte $65, $00
!byte $74, $00
!byte $75, $00
!byte $76, $10
!byte $6a, $10
!byte $67, $10
!byte $20, $10
