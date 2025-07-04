; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 5
; RUN: llc -mtriple=riscv64 -mcpu=sifive-p670 -O3 -verify-machineinstrs -riscv-enable-pipeliner=false < %s \
; RUN:   | FileCheck %s --check-prefixes=CHECK,CHECK-NOT-PIPELINED
; RUN: llc -mtriple=riscv64 -mcpu=sifive-p670 -O3 -verify-machineinstrs -riscv-enable-pipeliner=true < %s \
; RUN:   | FileCheck %s --check-prefixes=CHECK,CHECK-PIPELINED

; We shouldn't pipeline this loop as one operand of branch is a PHI.
define i32 @test_phi() {
; CHECK-LABEL: test_phi:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    li a0, 0
; CHECK-NEXT:  .LBB0_1: # %for.body
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    mv a1, a0
; CHECK-NEXT:    li a0, 1
; CHECK-NEXT:    sh a0, 0(zero)
; CHECK-NEXT:    bnez a1, .LBB0_1
; CHECK-NEXT:  # %bb.2: # %for.cond.cleanup
; CHECK-NEXT:    li a0, 0
; CHECK-NEXT:    ret
entry:
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body
  ret i32 0

for.body:                                         ; preds = %for.body, %entry
  %indvars.iv1 = phi i64 [ 0, %entry ], [ 1, %for.body ]
  store i16 1, ptr null, align 4
  %exitcond.not.31 = icmp eq i64 %indvars.iv1, 0
  br i1 %exitcond.not.31, label %for.cond.cleanup, label %for.body
}

define void @test_pipelined_1(ptr noalias %in, ptr noalias %out, i32 signext %cnt) {
; CHECK-NOT-PIPELINED-LABEL: test_pipelined_1:
; CHECK-NOT-PIPELINED:       # %bb.0: # %entry
; CHECK-NOT-PIPELINED-NEXT:    blez a2, .LBB1_3
; CHECK-NOT-PIPELINED-NEXT:  # %bb.1: # %for.body.preheader
; CHECK-NOT-PIPELINED-NEXT:    addi a2, a2, -1
; CHECK-NOT-PIPELINED-NEXT:    sh2add.uw a2, a2, a1
; CHECK-NOT-PIPELINED-NEXT:    addi a2, a2, 4
; CHECK-NOT-PIPELINED-NEXT:  .LBB1_2: # %for.body
; CHECK-NOT-PIPELINED-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NOT-PIPELINED-NEXT:    lw a3, 0(a1)
; CHECK-NOT-PIPELINED-NEXT:    addi a1, a1, 4
; CHECK-NOT-PIPELINED-NEXT:    addi a3, a3, 1
; CHECK-NOT-PIPELINED-NEXT:    sw a3, 0(a0)
; CHECK-NOT-PIPELINED-NEXT:    addi a0, a0, 4
; CHECK-NOT-PIPELINED-NEXT:    bne a1, a2, .LBB1_2
; CHECK-NOT-PIPELINED-NEXT:  .LBB1_3: # %for.end
; CHECK-NOT-PIPELINED-NEXT:    ret
;
; CHECK-PIPELINED-LABEL: test_pipelined_1:
; CHECK-PIPELINED:       # %bb.0: # %entry
; CHECK-PIPELINED-NEXT:    blez a2, .LBB1_7
; CHECK-PIPELINED-NEXT:  # %bb.1: # %for.body.preheader
; CHECK-PIPELINED-NEXT:    lw a4, 0(a1)
; CHECK-PIPELINED-NEXT:    addi a2, a2, -1
; CHECK-PIPELINED-NEXT:    addi a3, a0, 4
; CHECK-PIPELINED-NEXT:    sh2add.uw a6, a2, a1
; CHECK-PIPELINED-NEXT:    addi a1, a1, 4
; CHECK-PIPELINED-NEXT:    addi a6, a6, 4
; CHECK-PIPELINED-NEXT:    beq a1, a6, .LBB1_5
; CHECK-PIPELINED-NEXT:  # %bb.2: # %for.body
; CHECK-PIPELINED-NEXT:    lw a5, 0(a1)
; CHECK-PIPELINED-NEXT:    addi a2, a3, 4
; CHECK-PIPELINED-NEXT:    addi a4, a4, 1
; CHECK-PIPELINED-NEXT:    addi a1, a1, 4
; CHECK-PIPELINED-NEXT:    beq a1, a6, .LBB1_4
; CHECK-PIPELINED-NEXT:  .LBB1_3: # %for.body
; CHECK-PIPELINED-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-PIPELINED-NEXT:    sw a4, 0(a0)
; CHECK-PIPELINED-NEXT:    mv a4, a5
; CHECK-PIPELINED-NEXT:    lw a5, 0(a1)
; CHECK-PIPELINED-NEXT:    mv a0, a3
; CHECK-PIPELINED-NEXT:    mv a3, a2
; CHECK-PIPELINED-NEXT:    addi a2, a2, 4
; CHECK-PIPELINED-NEXT:    addi a4, a4, 1
; CHECK-PIPELINED-NEXT:    addi a1, a1, 4
; CHECK-PIPELINED-NEXT:    bne a1, a6, .LBB1_3
; CHECK-PIPELINED-NEXT:  .LBB1_4:
; CHECK-PIPELINED-NEXT:    sw a4, 0(a0)
; CHECK-PIPELINED-NEXT:    j .LBB1_6
; CHECK-PIPELINED-NEXT:  .LBB1_5:
; CHECK-PIPELINED-NEXT:    mv a3, a0
; CHECK-PIPELINED-NEXT:    mv a5, a4
; CHECK-PIPELINED-NEXT:  .LBB1_6:
; CHECK-PIPELINED-NEXT:    addi a5, a5, 1
; CHECK-PIPELINED-NEXT:    sw a5, 0(a3)
; CHECK-PIPELINED-NEXT:  .LBB1_7: # %for.end
; CHECK-PIPELINED-NEXT:    ret
entry:
  %cmp = icmp sgt i32 %cnt, 0
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %entry, %for.body
  %inc.next = phi i32 [ %inc, %for.body ], [ 0, %entry ]
  %in.addr.next = phi ptr [ %incdec.in, %for.body ], [ %in, %entry ]
  %out.addr.next = phi ptr [ %incdec.out, %for.body ], [ %out, %entry ]
  %0 = load i32, ptr %out.addr.next, align 4
  %1 = add i32 %0, 1
  store i32 %1, ptr %in.addr.next, align 4
  %incdec.in = getelementptr inbounds i8, ptr %in.addr.next, i64 4
  %incdec.out = getelementptr inbounds i8, ptr %out.addr.next, i64 4
  %inc = add nuw nsw i32 %inc.next, 1
  %exitcond.not = icmp eq i32 %inc, %cnt
  br i1 %exitcond.not, label %for.end, label %for.body

for.end:                                          ; preds = %for.body, %entry
  ret void
}
