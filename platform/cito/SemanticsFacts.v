Set Implicit Arguments.

Require Import ADT.

Module Make (Import E : ADT).

  Require Import Safe.
  Module Import SafeMake := Safe.Make E.
  Import SafeMake.SemanticsMake.

  Section TopSection.

    Require Import SemanticsExpr.
    Require Import Notations.

    Local Open Scope stmt.

    Lemma Safe_Seq_Skip : forall fs k v, Safe fs (skip ;; k) v -> Safe fs k v.
      admit.
    Qed.

    Lemma RunsTo_Seq_Skip : forall fs k v v', RunsTo fs k v v' -> RunsTo fs (skip ;; k) v v'.
      admit.
    Qed.

    Lemma Safe_Seq_assoc : forall fs a b c v, Safe fs ((a ;; b) ;; c) v -> Safe fs (a ;; b;; c) v.
      admit.
    Qed.

    Lemma RunsTo_Seq_assoc : forall fs a b c v v', RunsTo fs (a ;; b ;; c) v v' -> RunsTo fs ((a ;; b) ;; c) v v'.
      admit.
    Qed.

    Lemma Safe_Seq_If_true : forall fs e t f k v, Safe fs (Syntax.If e t f ;; k) v -> wneb (eval (fst v) e) $0 = true -> Safe fs (t ;; k) v.
      admit.
    Qed.

    Lemma RunsTo_Seq_If_true : forall fs e t f k v v', RunsTo fs (t ;; k) v v' -> wneb (eval (fst v) e) $0 = true -> RunsTo fs (Syntax.If e t f ;; k) v v'.
      admit.
    Qed.

    Lemma Safe_Seq_If_false : forall fs e t f k v, Safe fs (Syntax.If e t f ;; k) v -> wneb (eval (fst v) e) $0 = false -> Safe fs (f ;; k) v.
      admit.
    Qed.

    Lemma RunsTo_Seq_If_false : forall fs e t f k v v', RunsTo fs (f ;; k) v v' -> wneb (eval (fst v) e) $0 = false -> RunsTo fs (Syntax.If e t f ;; k) v v'.
      admit.
    Qed.

    Lemma Safe_Seq_While_false : forall fs e s k v, Safe fs (Syntax.While e s ;; k) v -> wneb (eval (fst v) e) $0 = false -> Safe fs k v.
      admit.
    Qed.

    Lemma RunsTo_Seq_While_false : forall fs e s k v v', RunsTo fs k v v' -> wneb (eval (fst v) e) $0 = false -> RunsTo fs (Syntax.While e s ;; k) v v'.
      admit.
    Qed.

    Lemma Safe_Seq_While_true : forall fs e s k v, Safe fs (Syntax.While e s ;; k) v -> wneb (eval (fst v) e) $0 = true -> Safe fs (s ;; Syntax.While e s ;; k) v.
      admit.
    Qed.

    Lemma RunsTo_Seq_While_true : forall fs e s k v v', RunsTo fs (s ;; Syntax.While e s ;; k) v v' -> wneb (eval (fst v) e) $0 = true -> RunsTo fs (Syntax.While e s ;; k) v v'.
      admit.
    Qed.

  End TopSection.

End Make.