
  .globl $sym
  .p2align 4
  .type $sym, %function
#ifndef IMPLIB_EXPORT_SHIMS
  .hidden $sym
#endif
$sym:
  .cfi_startproc

1:
  // Load address
  // TODO: can we do this faster on newer ARMs?
  adrp ip0, _${lib_suffix}_tramp_table+$offset
  ldr ip0, [ip0, #:lo12:_${lib_suffix}_tramp_table+$offset]
 
  cbz ip0, 2f

  // Fast path
  br ip0

2:
  // Slow path
  mov ip0, $number
  stp ip0, lr, [sp, #-16]!; .cfi_adjust_cfa_offset 16; .cfi_rel_offset ip0, 0; .cfi_rel_offset lr, 8;
  bl _${lib_suffix}_save_regs_and_resolve
  ldp ip0, lr, [sp], #16; .cfi_adjust_cfa_offset -16; .cfi_restore lr; .cfi_restore ip0
  b 1b
  .cfi_endproc

