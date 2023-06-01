    .section .init
    .globl _start
    .type _start,@function

_start:
	la sp, _sp

	call main
done:
    j done

	.globl _init
_init:
    ret