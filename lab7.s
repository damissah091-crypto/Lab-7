.data
MEM:  .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

.text
.globl _start                   # GAS needs this as the entry point

_start:
    mov  $0b10000000, %al
    mov  $0x643, %dx            # 0x703 -> 0x643, lab uses base address 0x640
    out  %al, %dx

    mov  $0, %bx                # scroll position counter, 0-15

scroll_loop:                    # outer loop to keep SHE bouncing
    call UPDATE_MEM
    call DISP
    inc  %bx
    cmp  $16, %bx
    jl   scroll_loop
    mov  $0, %bx
    jmp  scroll_loop

UPDATE_MEM:                     # writes SHE into MEM at current scroll position
    push %ax
    push %bx
    push %si
    lea  MEM, %si
    mov  $0x00, %ax
    mov  %al, 0(%si)            # blank all 8 digits before placing letters
    mov  %al, 1(%si)
    mov  %al, 2(%si)
    mov  %al, 3(%si)
    mov  %al, 4(%si)
    mov  %al, 5(%si)
    mov  %al, 6(%si)
    mov  %al, 7(%si)
    cmp  $0, %bx
    jl   done_update
    cmp  $7, %bx
    jg   done_update
    lea  MEM, %si
    mov  $0x79, %al             # E: segments a,d,e,f,g
    mov  %al, (%si,%bx)
    dec  %bx
    cmp  $0, %bx
    jl   skip_h
    mov  $0x76, %al             # H: segments b,c,e,f,g
    mov  %al, (%si,%bx)
skip_h:
    dec  %bx
    cmp  $0, %bx
    jl   skip_s
    mov  $0x6F, %al             # S: segments a,b,c,d,f,g
    mov  %al, (%si,%bx)
skip_s:
    add  $2, %bx
done_update:
    pop  %si
    pop  %bx
    pop  %ax
    ret

DISP:
    pushf
    push %ax
    push %bx
    push %dx
    push %si

    mov  $8,     %bx
    mov  $0xFE,  %ah            # 0x7F -> 0xFE, Port A bit0 is dig-0 so active-low starts here
    lea  MEM,    %si
    mov  $0x640, %dx            # 0x701 -> 0x640, Port A is digit-select in Fig A

disp_loop:
    mov  %ah, %al
    out  %al, %dx               # digit-select to Port A (was Port B in textbook)

    inc  %dx                    # DEC -> INC, Port B is one above Port A at 0x641
    mov  (%si), %al
    out  %al, %dx               # segment data to Port B (was Port A in textbook)

    call DELAY

    rol  $1, %ah                # ROR -> ROL, walking active-low bit from bit0 to bit7

    dec  %dx                    # INC -> DEC, back to Port A for next digit
    inc  %si

    dec  %bx
    jnz  disp_loop

    pop  %si
    pop  %dx
    pop  %bx
    pop  %ax
    popf
    ret

DELAY:                          # defined here since original only called but never wrote it
    push %cx
    mov  $0xFFFF, %cx
delay_loop:
    dec  %cx
    jnz  delay_loop
    pop  %cx
    ret