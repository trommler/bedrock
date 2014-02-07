Require Import Syntax.

Set Implicit Arguments.

(* syntactic_requirement *)
Section SynReq.

  Require Import String.

  Variable vars : list string.

  Variable temp_size : nat.

  Variable s : Stmt.

  Require Import FreeVars.
  Require Import Depth.
  Require Import StringSet.
  Require Import SetUtil.

  Local Open Scope nat.

  Definition in_scope := 
    Subset (free_vars s) (to_set vars) /\
    depth s <= temp_size.

  Require Import WellFormed.

  Definition syn_req := in_scope /\ wellformed s.

End SynReq.

Require Import ADT.
Require Import RepInv.

Module Make (Import E : ADT) (Import M : RepInv E).

  Require Import Inv.
  Module Import InvMake := Make E.
  Module Import InvMake2 := Make M.
  Import SafeMake.SemanticsMake.

  Section Spec.

    Variable vars : list string.

    Variable temp_size : nat.

    Variable s k : Stmt.

    Variable rv_postcond : W -> State -> Prop.

    Definition precond := inv vars temp_size rv_postcond (Syntax.Seq s k).

    Definition postcond := inv vars temp_size rv_postcond k.

    Definition imply (pre new_pre: assert) := forall specs x, interp specs (pre x) -> interp specs (new_pre x).

    Definition verifCond pre := imply pre precond :: syn_req vars temp_size (Syntax.Seq s k) :: nil.

  End Spec.

End Make.