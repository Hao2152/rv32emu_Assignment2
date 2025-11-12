    .section .rodata
    .balign 1

msg_in:     .ascii "x = "
    .set msg_in_len, .-msg_in
msg_out:    .ascii "rsqrt(x) = 0x"
    .set msg_out_len, .-msg_out
nl:         .ascii "\n"
    .set nl_len, .-nl

hexchars:   .ascii "0123456789ABCDEF"

    .balign 4
test_values:
    .word 9
case_count:
    .word 1

# =================================================================
    .section .text
    .globl  quiz3_problemC_main
    .extern putchar

# ================================================================
# write_stdout(a0=ptr, a1=len)
# ================================================================
write_stdout:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    mv      t0, a0
    mv      t1, a1
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

# ================================================================
# putc(a0=char)
# ================================================================
putc:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    jal     ra, putchar
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

# ================================================================
# print_dec20(a0)
# ================================================================
print_dec20:
    addi    sp, sp, -80
    sw      ra, 76(sp)
    sw      s0, 72(sp)
    sw      s1, 68(sp)
    sw      s2, 64(sp)
    sw      s3, 60(sp)
    sw      t0, 56(sp)
    sw      t1, 52(sp)
    sw      t2, 48(sp)
    sw      t3, 44(sp)
    sw      t4, 40(sp)
    sw      t5, 36(sp)
    sw      t6, 32(sp)
    sw      a0, 28(sp)

    mv      s0, a0
    addi    s1, sp, 16
    li      s2, 0
    beqz    s0, .pd20_zero

.pd20_outer:
    li      t0, 10
    li      t1, 0
.pd20_div:
    bltu    s0, t0, .pd20_done
    sub     s0, s0, t0
    addi    t1, t1, 1
    j       .pd20_div
.pd20_done:
    addi    t2, s0, '0'
    sb      t2, 0(s1)
    addi    s1, s1, 1
    addi    s2, s2, 1
    mv      s0, t1
    bnez    s0, .pd20_outer
    addi    s1, s1, -1
.pd20_print:
    lb      a0, 0(s1)
    jal     ra, putc
    addi    s1, s1, -1
    addi    s2, s2, -1
    bnez    s2, .pd20_print
    j       .pd20_end

.pd20_zero:
    li      a0, '0'
    jal     ra, putc
.pd20_end:
    lw      a0, 28(sp)
    lw      t6, 32(sp)
    lw      t5, 36(sp)
    lw      t4, 40(sp)
    lw      t3, 44(sp)
    lw      t2, 48(sp)
    lw      t1, 52(sp)
    lw      t0, 56(sp)
    lw      s3, 60(sp)
    lw      s2, 64(sp)
    lw      s1, 68(sp)
    lw      s0, 72(sp)
    lw      ra, 76(sp)
    addi    sp, sp, 80
    ret

# ================================================================
# print_hex32(a0)
# ================================================================
print_hex32:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      t0, 24(sp)
    sw      t1, 20(sp)
    sw      t2, 16(sp)
    sw      t3, 12(sp)

    mv      t2, a0
    li      t1, 28
hex32_loop:
    srl     t0, t2, t1
    andi    t0, t0, 0xF
    la      t3, hexchars
    add     t3, t3, t0
    lbu     a0, 0(t3)
    jal     ra, putc
    addi    t1, t1, -4
    bgez    t1, hex32_loop

    lw      t3, 12(sp)
    lw      t2, 16(sp)
    lw      t1, 20(sp)
    lw      t0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

# ================================================================
# mul32_shift32(a0=x, a1=y)
# ================================================================
mul32_shift32:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    mv      t0, a0
    mv      t1, a1
    li      t2, 0
    li      t3, 0
1:  beqz    t1, 2f
    andi    t4, t1, 1
    beqz    t4, 3f
    add     t2, t2, t0
    sltu    t5, t2, t0
    add     t3, t3, t5
3:  slli    t0, t0, 1
    srli    t1, t1, 1
    j       1b
2:  mv      a0, t3
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

# ================================================================
# fast_rsqrt(a0=Q0.32)
# ================================================================
fast_rsqrt:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)

    mv      s0, a0
    beqz    s0, 9f

    mv      a0, s0
    jal     ra, isqrt32
    mv      s1, a0

    mv      a0, s1
    jal     ra, recip_q32
    mv      a0, a0

    lw      ra, 28(sp)
    lw      s0, 24(sp)
    lw      s1, 20(sp)
    addi    sp, sp, 32
    ret

9:  li      a0, 0
    lw      ra, 28(sp)
    lw      s0, 24(sp)
    lw      s1, 20(sp)
    addi    sp, sp, 32
    ret

# ================================================================
# isqrt32
# ================================================================
isqrt32:
    addi    sp, sp, -48
    sw      ra, 44(sp)
    sw      s0, 40(sp)
    sw      s1, 36(sp)
    sw      s2, 32(sp)

    mv      s0, a0
    li      s1, 0
    li      s2, 1
    slli    s2, s2, 30

.isq_align:
    bgtu    s2, s0, 1f
    j       .isq_aligned
1:  srli    s2, s2, 2
    bnez    s2, .isq_align
.isq_aligned:

.isq_loop:
    beqz    s2, .isq_done
    add     t0, s1, s2
    bltu    s0, t0, .isq_skip
    sub     s0, s0, t0
    srli    s1, s1, 1
    add     s1, s1, s2
    j       .isq_next
.isq_skip:
    srli    s1, s1, 1
.isq_next:
    srli    s2, s2, 2
    j       .isq_loop
.isq_done:
    mv      a0, s1
    lw      s2, 32(sp)
    lw      s1, 36(sp)
    lw      s0, 40(sp)
    lw      ra, 44(sp)
    addi    sp, sp, 48
    ret

# ================================================================
# recip_q32(a0)
# ================================================================
recip_q32:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)
    sw      s2, 16(sp)
    sw      s3, 12(sp)

    mv      s0, a0
    beqz    s0, .rcp_zero

    li      s1, 0
    li      s2, 0
    li      s3, 33
.rcp_loop:
    beqz    s3, .rcp_done
    slli    s1, s1, 1
    li      t0, 33
    beq     s3, t0, 1f
    j       2f
1:  ori     s1, s1, 1
2:  slli    s2, s2, 1
    bltu    s1, s0, .rcp_next
    sub     s1, s1, s0
    ori     s2, s2, 1
.rcp_next:
    addi    s3, s3, -1
    j       .rcp_loop

.rcp_done:
    mv      a0, s2
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

.rcp_zero:
    li      a0, 0
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

# ================================================================
# quiz3_problemC_main
# ================================================================
quiz3_problemC_main:
    addi    sp, sp, -48
    sw      ra, 44(sp)
    sw      s0, 40(sp)
    sw      s1, 36(sp)
    sw      s2, 32(sp)
    sw      s3, 28(sp)
    sw      s4, 24(sp)

    la      s0, test_values
    la      s1, case_count
    lw      s1, 0(s1)
    li      s2, 0

loop:
    beq     s2, s1, done
    lw      t0, 0(s0)
    mv      s3, t0

    la      a0, msg_in
    li      a1, msg_in_len
    jal     ra, write_stdout
    mv      a0, s3
    jal     ra, print_dec20
    la      a0, nl
    li      a1, nl_len
    jal     ra, write_stdout

    mv      a0, s3
    jal     ra, fast_rsqrt
    mv      s4, a0

    la      a0, msg_out
    li      a1, msg_out_len
    jal     ra, write_stdout
    mv      a0, s4
    jal     ra, print_hex32
    la      a0, nl
    li      a1, nl_len
    jal     ra, write_stdout

    addi    s0, s0, 4
    addi    s2, s2, 1
    j       loop

done:
    lw      s4, 24(sp)
    lw      s3, 28(sp)
    lw      s2, 32(sp)
    lw      s1, 36(sp)
    lw      s0, 40(sp)
    lw      ra, 44(sp)
    addi    sp, sp, 48
    ret