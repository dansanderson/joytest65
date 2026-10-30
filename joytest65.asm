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
    jsr read_joystick_ports
    jsr update_display

    ; Sync raster for cleaner screen updates
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

!macro disp_feature_flag val, mask, locptr {
    ; Determine "on " or "off"
    ; X=string offset; Y=attr
    lda val
    and #mask
    beq +
    ldx #0        ; "on "
    ldy #$07
    bra ++
+   ldx #3        ; "off"
    ldy #$0e
++

    ; Plot attr: 1.f800 + (locptr), three locations
    lda #$00
    clc
    adc locptr
    sta $fc
    lda #$f8
    adc locptr+1
    sta $fd
    lda #$01
    adc #$00
    sta $fe
    lda #$00
    sta $ff   ; [$fc] = attr address
    tya
    ldz #0
    sta [$fc],z
    inz
    sta [$fc],z
    inz
    sta [$fc],z

    ; Plot word: from ff_on,x to [$d060] + (locptr), three locations
    lda $d060
    clc
    adc locptr
    sta $fc
    lda $d061
    adc locptr+1
    sta $fd
    lda $d062
    adc #$00
    sta $fe
    lda $d063
    and #$0f
    sta $ff   ; [$fc] = attr address
    lda ff_on,x
    ldz #0
    sta [$fc],z
    inx
    lda ff_on,x
    inz
    sta [$fc],z
    inx
    lda ff_on,x
    inz
    sta [$fc],z
}


make_screen_addr:
    ; Input: $fc-$fd: screen offset
    ; Output: $fc-$ff: screen address + offset
    lda $d060
    clc
    adc $fc
    sta $fc
    lda $d061
    adc $fd
    sta $fd
    lda $d062
    adc #$00
    sta $fe
    lda $d063
    and #$0f
    sta $ff   ; [$fc] = char address
    rts

disp_byte_dec:
    ; $fc-$fd: screen offset
    ; A: byte value to print: three digit unsigned decimal
    sta $1600
    lda #0
    sta $1601
    sta $1602
    sta $1603
    jsr make_screen_addr

    ; Calculate three-digit BCD in $1601-$1602 ($0x $yz)
    sed
    ldx #8
-   rol $1600
    ldy #2
--  lda $1600,y
    adc $1600,y
    sta $1600,y
    dey
    bne --
    dex
    bne -
    cld

    ; DEBUG
    ; 128 -> $1601:$01 $1602:$28
;     lda $1601
;     cmp #$01
;     bne +
;     brk
; +

    ; Plot screen codes
    lda $1601
    jsr hex_az
    ldz #0
    sta [$fc],z
    lda $1602
    jsr hex_az
    pha
    tza
    ldz #1
    sta [$fc],z
    pla
    inz
    sta [$fc],z

    rts

; Input: A = byte
; Output: A/Z = hex digit screen codes
hex_az:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr hex_nyb
    taz
    pla

hex_nyb:
    and #15
    cmp #10
    bcs +
    adc #48 ; (carry clear)
    bra ++
+   sbc #9  ; (carry set)
++  rts

disp_byte_hex:
    ; $fc-$fd: screen offset
    ; A: byte value to print: two digit unsigned hexadecimal
    pha
    jsr make_screen_addr
    pla
    jsr hex_az
    phz
    ldz #1
    sta [$fc],z
    pla
    dez
    sta [$fc],z

    rts

disp_byte_bin5:
    ; $fc-$fd: screen offset
    ; A: byte value to print: lowest 5 binary digits
    pha
    jsr make_screen_addr
    pla
    rol
    rol
    rol

    ldz #0
-   rol
    pha
    bcc +
    lda #49  ; screen code '1'
    bra ++
+   lda #48  ; screen code '0'
++  sta [$fc],z
    pla
    inz
    cpz #5
    bne -

    rts

joyfunc_dirs:
!byte %1111, %1110, %0110, %0111, %0101, %1101, %1001, %1011, %1010

calc_joyfunc:
    ; Input: A=CIA bits
    ; Output: A=JOY()
    tax
    and #%00010000
    bne +
    lda #$80
    bra ++
+   lda #$00
++  sta $1600
    txa

    and #%00001111
    ldx #0
-   cmp joyfunc_dirs,x
    beq ++
    inx
    cpx #9
    bne -
    ldx #0
++  txa

    clc
    adc $1600
    rts

disp_paddle_bar:
    ; Input: $fc-$fd = screen offset; A = paddle value
    ; TODO: adjust bar size to 37 and positions in the layout! I thought it'd be 43!

    ldx $fc
    stx $1600
    ldx $fd
    stx $1601

    ldz #0

-   cmp #7
    bcs +
    ; A<7
    tax
    lda #0
    bra ++
+   ; A>=7
    ldx #7
    sec
    sbc #7
++  ; X=bar char index, Z=bar pos
    pha
    txa
    asl
    tay  ; Y=2*x (bar_steps offset)

    lda $1600
    sta $fc
    lda $1601
    sta $fd
    jsr make_screen_addr
    lda bar_steps,y    ; A=screen code
    sta [$fc],z

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
    lda bar_steps+1,y  ; A=attr
    sta [$fc],z

    pla
    inz
    cpz #37
    bne -

    rts


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

    ; Joy bits
    lda joy_cia_5bits
    sta $fc
    lda joy_cia_5bits+1
    sta $fd
    lda joystick1
    jsr disp_byte_bin5

    lda joy_cia_5bits
    clc
    adc #joy2_offset
    sta $fc
    lda joy_cia_5bits+1
    adc #0
    sta $fd
    lda joystick2
    jsr disp_byte_bin5

    ; Joy hex
    lda joy_cia_hex
    sta $fc
    lda joy_cia_hex+1
    sta $fd
    lda joystick1
    jsr disp_byte_hex

    lda joy_cia_hex
    clc
    adc #joy2_offset
    sta $fc
    lda joy_cia_hex+1
    adc #0
    sta $fd
    lda joystick2
    jsr disp_byte_hex

    ; Joy basfunc dec
    lda joy_basfunc_dec
    sta $fc
    lda joy_basfunc_dec+1
    sta $fd
    lda joystick1
    jsr calc_joyfunc
    jsr disp_byte_dec

    lda joy_basfunc_dec
    clc
    adc #joy2_offset
    sta $fc
    lda joy_basfunc_dec+1
    adc #0
    sta $fd
    lda joystick2
    jsr calc_joyfunc
    jsr disp_byte_dec

    ; Paddle numbers
    lda pad1_val_hex
    sta $fc
    lda pad1_val_hex+1
    sta $fd
    lda paddle1a
    jsr disp_byte_hex

    lda pad1_val_hex
    clc
    adc #3
    sta $fc
    lda pad1_val_hex+1
    adc #0
    sta $fd
    lda paddle1a
    jsr disp_byte_dec

    lda pad2_val_hex
    sta $fc
    lda pad2_val_hex+1
    sta $fd
    lda paddle1b
    jsr disp_byte_hex

    lda pad2_val_hex
    clc
    adc #3
    sta $fc
    lda pad2_val_hex+1
    adc #0
    sta $fd
    lda paddle1b
    jsr disp_byte_dec

    lda pad3_val_hex
    sta $fc
    lda pad3_val_hex+1
    sta $fd
    lda paddle2a
    jsr disp_byte_hex

    lda pad3_val_hex
    clc
    adc #3
    sta $fc
    lda pad3_val_hex+1
    adc #0
    sta $fd
    lda paddle2a
    jsr disp_byte_dec

    lda pad4_val_hex
    sta $fc
    lda pad4_val_hex+1
    sta $fd
    lda paddle2b
    jsr disp_byte_hex

    lda pad4_val_hex
    clc
    adc #3
    sta $fc
    lda pad4_val_hex+1
    adc #0
    sta $fd
    lda paddle2b
    jsr disp_byte_dec

    ; Paddle bars
    lda pad1_bar
    sta $fc
    lda pad1_bar+1
    sta $fd
    lda paddle1a
    jsr disp_paddle_bar

    lda pad2_bar
    sta $fc
    lda pad2_bar+1
    sta $fd
    lda paddle1b
    jsr disp_paddle_bar

    lda pad3_bar
    sta $fc
    lda pad3_bar+1
    sta $fd
    lda paddle2a
    jsr disp_paddle_bar

    lda pad4_bar
    sta $fc
    lda pad4_bar+1
    sta $fd
    lda paddle2b
    jsr disp_paddle_bar

    ; Feature flags
    +disp_feature_flag $d612, %00100000, ff_joyswap
    +disp_feature_flag $d612, %01000000, ff_ljoya
    +disp_feature_flag $d612, %10000000, ff_ljoyb

    rts

read_joystick_ports:
    ; This demonstrates the C64 method of reading joystick and paddle lines
    ; using the CIA and SID chips.
    ;
    ; Another way to read joystick digital pins on the MEGA65 is to set the
    ; J21 data directions $D627-$D628 bits 0-11 to zero (input), then read the
    ; corresponding bits of $D625-$D626.
    ;
    ; An easier way to read paddles on the MEGA65 is to read registers
    ; $D620-$D623, one byte per paddle (AX, AY, BX, BY). This does not require
    ; fiddling with the CIA or waiting for the SID to settle.

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
;     01234567890123456789012345678901234567890123456789012345678901234567890123456789
!scr "                 joystick and paddle tester v0.2, by dddaaannn                  "
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
!scr "                                                    pot(n) / $d419 / $d41a      "
;                          0123456789012345678901234567890123456
!scr "     paddle 1 (1a): [                                     ] $00 000  ($d620)    "
!scr "     paddle 2 (1b): [                                     ] $00 000  ($d621)    "
!scr "     paddle 3 (2a): [                                     ] $00 000  ($d622)    "
!scr "     paddle 4 (2b): [                                     ] $00 000  ($d623)    "
!scr "                                                                                "
;     01234567890123456789012345678901234567890123456789012345678901234567890123456789
!scr "     ($d612 5-7:)  joy swap [f1]: off  rotate 180: j1 [f3] off, j2 [f5] off     "
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
pad1_val_hex:    !word (18*80 + 61)
pad2_val_hex:    !word (19*80 + 61)
pad3_val_hex:    !word (20*80 + 61)
pad4_val_hex:    !word (21*80 + 61)
pad1_bar:        !word (18*80 + 21)
pad2_bar:        !word (19*80 + 21)
pad3_bar:        !word (20*80 + 21)
pad4_bar:        !word (21*80 + 21)

; Each step is one screen code and one char attr.
bar_steps:
!byte $20, $01
!byte $65, $01
!byte $74, $01
!byte $75, $01
!byte $76, $21
!byte $6a, $21
!byte $67, $21
!byte $20, $21

; Start of "off"/"on" for each feature flag
; - uint16: Screen memory offset (joy 1)
ff_joyswap:      !word (23*80 + 34)
ff_ljoya:        !word (23*80 + 59)
ff_ljoyb:        !word (23*80 + 72)
ff_on:           !scr "on "
ff_off:          !scr "off"
