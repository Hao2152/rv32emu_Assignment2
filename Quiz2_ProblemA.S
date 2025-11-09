    .section .rodata
    .balign 1

str_move:   .ascii "Move Disk "
    .set str_move_len, .-str_move
str_from:   .ascii " from "
    .set str_from_len, .-str_from
str_to:     .ascii " to "
    .set str_to_len,   .-str_to
nl:         .ascii "\n"
    .set nl_len, .-nl

hexchars:   .ascii "0123456789ABCDEF"
    .balign 4
pow10_tbl:
    .word 100000, 10000, 1000, 100, 10, 1

    .balign 1
obdata:     .byte 0x3c, 0x3b, 0x3a


    .section .text
    .globl quiz2_problemA_main
    .extern putchar

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

quiz2_problemA_main:
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)
    sw      s2, 16(sp)
    sw      s3, 12(sp)

    li      s1, 0
    li      s2, 0
    li      s3, 0
    li      s0, 1         

loop:
    li      t0, 8
    bge     s0, t0, finish

    mv      t1, s0
    srli    t2, t1, 1
    xor     t2, t2, t1     
    addi    t3, s0, -1
    srli    t4, t3, 1
    xor     t4, t4, t3   
    xor     t5, t2, t4     

    andi    t6, t5, 1
    bnez    t6, disk0
    andi    t6, t5, 2
    bnez    t6, disk1
    li      t6, 2
    j       disk_sel
disk1:
    li      t6, 1
    j       disk_sel
disk0:
    li      t6, 0
disk_sel:

    mv      t4, s1
    mv      t5, s2
    mv      t6, s3

    beqz    t6, pos0
    li      t0, 1
    beq     t6, t0, pos1
    mv      t1, t6         
    j       got_old
pos1:
    mv      t1, t5
    j       got_old
pos0:
    mv      t1, t4
got_old:

    beqz    t6, small_move
    li      t0, 3
    sub     t2, t0, t1
    sub     t2, t2, t4
    j       ready
small_move:
    addi    t2, t1, 2
    li      t0, 3
    blt     t2, t0, ready
    sub     t2, t2, t0
ready:
    la      t0, obdata
    add     t3, t0, t1
    lbu     t3, 0(t3)
    li      t4, 0x6F
    xor     t3, t3, t4
    addi    t3, t3, -0x12  

    la      t0, obdata
    add     t4, t0, t2
    lbu     t4, 0(t4)
    li      t5, 0x6F
    xor     t4, t4, t5
    addi    t4, t4, -0x12 

    la      a0, str_move
    li      a1, str_move_len
    jal     ra, write_stdout

    addi    a0, t6, 1
    jal     ra, print_dec20

    la      a0, str_from
    li      a1, str_from_len
    jal     ra, write_stdout

    mv      a0, t3
    jal     ra, putc

    la      a0, str_to
    li      a1, str_to_len
    jal     ra, write_stdout

    mv      a0, t4
    jal     ra, putc

    la      a0, nl
    li      a1, nl_len
    jal     ra, write_stdout

    beqz    t6, upd0
    li      t0, 1
    beq     t6, t0, upd1
    mv      s3, t2
    j       next
upd1:
    mv      s2, t2
    j       next
upd0:
    mv      s1, t2

next:
    addi    s0, s0, 1
    j       loop

finish:
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret