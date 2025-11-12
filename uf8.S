    .section .rodata
    .balign 1

msg_in:     .ascii "Input value: "
    .set msg_in_len, .-msg_in
msg_enc:    .ascii "Encoded uf8: "
    .set msg_enc_len, .-msg_enc
msg_dec:    .ascii "Decoded value: "
    .set msg_dec_len, .-msg_dec
msg_hex:    .ascii " (hex) = 0x"
    .set msg_hex_len, .-msg_hex
nl:         .ascii "\n"
    .set nl_len, .-nl

hexchars:   .ascii "0123456789ABCDEF"

    .balign 4
pow10_tbl:
    .word 100000, 10000, 1000, 100, 10, 1

    .balign 4
test_values:
    .word 16
case_count:
    .word 1

    .section .text
    .globl uf8_main
    .extern putchar 

uf8_main:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)
    sw      s2, 16(sp)
    sw      s3, 12(sp)
    sw      s4, 8(sp)
    sw      s5, 4(sp)

    la   s0, test_values
    la   s1, case_count
    lw   s1, 0(s1)            # case count
    li   s2, 0                # i = 0

loop_values:
    beq  s2, s1, end

    # load value
    lw   s3, 0(s0)            # s3 = input value

    # "Input value: "
    la   a0, msg_in
    li   a1, msg_in_len
    jal  ra, write_stdout

    # decimal
    mv   a0, s3
    jal  ra, print_dec20

    # " (hex) = 0x"
    la   a0, msg_hex
    li   a1, msg_hex_len
    jal  ra, write_stdout

    # hex (20 bits)
    mv   a0, s3
    jal  ra, print_hex20bits

    # newline
    la   a0, nl
    li   a1, nl_len
    jal  ra, write_stdout

    ################ Encode ################
    mv   a0, s3
    jal  ra, uf8_encode
    mv   s4, a0                # s4 = uf8 code (8 bits)

    # "Encoded uf8: "
    la   a0, msg_enc
    li   a1, msg_enc_len
    jal  ra, write_stdout

    # decimal (<=255)
    mv   a0, s4
    jal  ra, print_dec20

    # " (hex) = 0x"
    la   a0, msg_hex
    li   a1, msg_hex_len
    jal  ra, write_stdout

    # hex2
    mv   a0, s4
    jal  ra, print_hex2bits

    # newline
    la   a0, nl
    li   a1, nl_len
    jal  ra, write_stdout

    ################ Decode ################
    mv   a0, s4
    jal  ra, uf8_decode
    mv   s5, a0

    # "Decoded value: "
    la   a0, msg_dec
    li   a1, msg_dec_len
    jal  ra, write_stdout

    # decimal
    mv   a0, s5
    jal  ra, print_dec20

    # " (hex) = 0x"
    la   a0, msg_hex
    li   a1, msg_hex_len
    jal  ra, write_stdout

    # hex20
    mv   a0, s5
    jal  ra, print_hex20bits

    # "\n\n"
    la   a0, nl
    li   a1, nl_len
    jal  ra, write_stdout
    la   a0, nl
    li   a1, nl_len
    jal  ra, write_stdout

    # next
    addi s0, s0, 4
    addi s2, s2, 1
    j    loop_values

end:
    lw      s5, 4(sp)
    lw      s4, 8(sp)
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

write_stdout:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    mv      t0, a0        # ptr
    mv      t1, a1        # len
1:
    beqz    t1, 2f
    lbu     a0, 0(t0)
    jal     ra, putchar   
    addi    t0, t0, 1
    addi    t1, t1, -1
    j       1b
2:
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

putc:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    jal     ra, putchar   
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

print_dec20:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)
    sw      s2, 16(sp)
    sw      s3, 12(sp)

    mv      s0, a0
    la      s1, pow10_tbl
    li      s2, 0
    li      s3, 6

dec20_next_div:
    beqz    s3, dec20_done
    lw      t0, 0(s1)
    li      t1, 0

dec20_sub_loop:
    bltu    s0, t0, dec20_emit_digit
    sub     s0, s0, t0
    addi    t1, t1, 1
    j       dec20_sub_loop

dec20_emit_digit:
    bnez    s2, dec20_do_print
    beqz    t1, dec20_skip_leading
dec20_do_print:
    li      s2, 1
    addi    a0, t1, '0'
    jal     ra, putc

dec20_skip_leading:
    addi    s1, s1, 4
    addi    s3, s3, -1
    j       dec20_next_div

dec20_done:
    beqz    s2, dec20_print0
    j       dec20_epilogue
dec20_print0:
    li      a0, '0'
    jal     ra, putc

dec20_epilogue:
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

print_hex2bits:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      t0, 8(sp)
    sw      t1, 4(sp)

    mv      t1, a0
    srli    t0, t1, 4
    andi    t0, t0, 0xF
    la      t2, hexchars
    add     t2, t2, t0
    lbu     a0, 0(t2)
    jal     ra, putc

    andi    t0, t1, 0xF
    la      t2, hexchars
    add     t2, t2, t0
    lbu     a0, 0(t2)
    jal     ra, putc

    lw      t1, 4(sp)
    lw      t0, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

print_hex20bits:
    addi    sp, sp, -20
    sw      ra, 16(sp)
    sw      t0, 12(sp)
    sw      t1, 8(sp)
    sw      t2, 4(sp)

    mv      t3, a0
    li      t1, 16
hex20_loop:
    srl     t0, t3, t1
    andi    t0, t0, 0xF
    la      t2, hexchars
    add     t2, t2, t0
    lbu     a0, 0(t2)
    jal     ra, putc
    addi    t1, t1, -4
    bgez    t1, hex20_loop

    lw      t2, 4(sp)
    lw      t1, 8(sp)
    lw      t0, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20
    ret

uf8_decode:
    andi    t0, a0, 0x0f
    srli    t1, a0, 4
    li      t2, 1
    sll     t2, t2, t1
    addi    t2, t2, -1
    slli    t2, t2, 4
    sll     t0, t0, t1
    add     a0, t0, t2
    ret

uf8_encode:
    li      t4, 16
    bltu    a0, t4, v_small

    addi    sp, sp, -8
    sw      ra, 4(sp)
    sw      s0, 0(sp)
    mv      s0, a0
    mv      a0, s0
    jal     ra, clz

    li      t0, 31
    sub     t3, t0, a0
    li      t4, 0
    li      t5, 0
    li      t0, 5
    blt     t3, t0, Lskip_est

    li      t0, 4
    sub     t4, t3, t0
    li      t0, 15
    ble     t4, t0, Lcap_ok
    li      t4, 15

Lcap_ok:
    li      t5, 0
    li      t1, 0
Lmk_off:
    bge     t1, t4, Lmk_off_end
    slli    t5, t5, 1
    addi    t5, t5, 16
    addi    t1, t1, 1
    j       Lmk_off
Lmk_off_end:

Lshrink:
    beqz    t4, Lafter_shrink
    bge     s0, t5, Lafter_shrink
    addi    t5, t5, -16
    srli    t5, t5, 1
    addi    t4, t4, -1
    j       Lshrink
Lafter_shrink:
Lskip_est:
Lgrow:
    li      t0, 15
    bge     t4, t0, Lgrow_end
    slli    t2, t5, 1
    addi    t2, t2, 16
    bltu    s0, t2, Lgrow_end
    mv      t5, t2
    addi    t4, t4, 1
    j       Lgrow
Lgrow_end:
    sub     t1, s0, t5
    srl     t1, t1, t4
    slli    t4, t4, 4
    or      a0, t4, t1
    lw      s0, 0(sp)
    lw      ra, 4(sp)
    addi    sp, sp, 8
    ret
v_small:
    ret

clz:
    li      t0, 32
    li      t1, 16
clz_loop:
    srl     t2, a0, t1
    beqz    t2, no_sub
    sub     t0, t0, t1
    mv      a0, t2
no_sub:
    srli    t1, t1, 1
    bnez    t1, clz_loop
    sub     a0, t0, a0
    ret