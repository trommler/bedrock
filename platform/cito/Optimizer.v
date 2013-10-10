Require Import Syntax.
Require Import Semantics.
Import SemanticsExpr.
Import Safety.
Require Import GeneralTactics.

Inductive Outcome := 
  | Done : st -> Outcome
  | ToCall : W -> W -> Statement -> st -> Outcome.
                   
Inductive Step : Statement -> st -> Outcome -> Prop :=
  | Skip : forall v, Step Syntax.Skip v (Done v)
  | Seq1 : forall v v' v'' a b,
      Step a v (Done v') -> 
      Step b v' v'' -> 
      Step (Syntax.Seq a b) v v''
  | Seq2 : forall v v' a b f x s,
      Step a v (ToCall f x s v') -> 
      Step (Syntax.Seq a b) v (ToCall f x (Syntax.Seq s b) v')
  | Calling : forall vs arrs f arg,
      let v := (vs, arrs) in
      let f_v := exprDenote f vs in
      let arg_v := exprDenote arg vs in
      Step (Syntax.Call f arg) v (ToCall f_v arg_v Syntax.Skip v).

Lemma Step_deterministic : forall s v v1 v2, Step s v v1 -> Step s v v2 -> v1 = v2.
  admit.
Qed.

Definition bisimulation (R : Statement -> Statement -> Prop) := 
  forall s t, 
    R s t -> 
    forall v, 
      (exists v', 
         Step s v (Done v') /\ 
         Step t v (Done v')) \/ 
      (exists f x s' t' v', 
         Step s v (ToCall f x s' v') /\ 
         Step t v (ToCall f x t' v') /\ 
         R s' t').

Definition bisimilar s t := exists R, bisimulation R /\ R s t.

(* each function can be optimized by different optimizors, hence using different bisimulations *)
Inductive bisimilar_callee : Callee -> Callee -> Prop :=
  | BothForeign : forall a b, (forall x, a x <-> b x) -> bisimilar_callee (Foreign a) (Foreign b)
  | BothInternal : forall a b, bisimilar a b -> bisimilar_callee (Internal a) (Internal b).

Definition bisimilar_fs a b := 
  forall (w : W), 
    (a w = None /\ b w = None) \/
    exists x y,
      a w = Some x /\ b w = Some y /\
      bisimilar_callee x y.

Section Functions.

  Variable fs : W -> option Callee.

  Inductive StepsTo : Statement -> st -> st -> Prop :=
    | NoCall :
        forall s v v',
          Step s v (Done v') ->
          StepsTo s v v'
    | HasForeign :
      forall s v f x s' v' spec v'' v''',
        Step s v (ToCall f x s' v') ->
        fs f = Some (Foreign spec) -> 
        spec {| Arg := x; InitialHeap := snd v'; FinalHeap := snd v'' |} ->
        StepsTo s' v'' v''' ->
        StepsTo s v v'''
    | HasInternal :
      forall s v f x s' v' body vs_arg v'' v''',
        Step s v (ToCall f x s' v') ->
        fs f = Some (Internal body) -> 
        Locals.sel vs_arg "__arg" = x ->
        StepsTo body (vs_arg, snd v') v'' ->
        StepsTo s' v'' v''' ->
        StepsTo s v v'''.

End Functions.

Theorem RunsTo_StepsTo_equiv : forall fs s v v', RunsTo fs s v v' <-> StepsTo fs s v v'.
  admit.
Qed.
Hint Resolve RunsTo_StepsTo_equiv.

Hint Unfold bisimilar.

Lemma correct_StepsTo : forall sfs s v v', StepsTo sfs s v v' -> forall tfs t, bisimilar s t -> bisimilar_fs sfs tfs -> StepsTo tfs t v v'.
  induction 1; simpl; intuition.

  unfold bisimilar, bisimulation in *; openhyp.
  eapply H0 in H2; openhyp.
  econstructor.
  eapply Step_deterministic in H2; [ | eapply H]; injection H2; intros; subst.
  eauto.
  eapply Step_deterministic in H2; [ | eapply H]; discriminate.

  generalize H3; intro.
  unfold bisimilar, bisimulation in H3; openhyp.
  generalize H4; intro.
  unfold bisimilar_fs in H4; openhyp.
  specialize (H4 f).
  openhyp.
  rewrite H0 in *; discriminate.
  rewrite H0 in *; injection H4; intros; subst.
  inversion H9; subst.
  eapply H3 in H6; openhyp.
  eapply Step_deterministic in H6; [ | eapply H]; discriminate.
  eapply Step_deterministic in H6; [ | eapply H]; injection H6; intros; subst.
  econstructor 2; eauto.
  firstorder.

  generalize H4; intro.
  unfold bisimilar, bisimulation in H4; openhyp.
  generalize H5; intro.
  unfold bisimilar_fs in H5; openhyp.
  specialize (H5 f).
  openhyp.
  rewrite H0 in *; discriminate.
  rewrite H0 in *; injection H5; intros; subst.
  inversion H10; subst.
  eapply H4 in H7; openhyp.
  eapply Step_deterministic in H1; [ | eapply H]; discriminate.
  eapply Step_deterministic in H1; [ | eapply H]; injection H1; intros; subst.
  econstructor 3; eauto.
Qed.
Hint Resolve correct_StepsTo.

Theorem correct_RunsTo : forall sfs s tfs t, bisimilar s t -> bisimilar_fs sfs tfs -> forall v v', RunsTo sfs s v v' -> RunsTo tfs t v v'.
  intros.
  eapply RunsTo_StepsTo_equiv in H1.
  eapply RunsTo_StepsTo_equiv.
  eauto.
Qed.

Theorem correct_Safe : forall sfs s tfs t, bisimilar s t -> bisimilar_fs sfs tfs -> forall v, Safe sfs s v -> Safe tfs t v.
  admit.
Qed.

Hint Resolve correct_RunsTo correct_Safe.

Lemma bisimilar_symm : forall a b, bisimilar a b -> bisimilar b a.
  admit.
Qed.

Hint Resolve bisimilar_symm.

Lemma bisimilar_fs_symm : forall a b, bisimilar_fs a b -> bisimilar_fs b a.
  admit.
Qed.

Hint Resolve bisimilar_fs_symm.

Theorem correct : forall sfs s tfs t, bisimilar s t -> bisimilar_fs sfs tfs -> forall v, (Safe sfs s v <-> Safe tfs t v) /\ forall v', RunsTo sfs s v v' <-> RunsTo tfs t v v'.
  intuition eauto.
Qed.
