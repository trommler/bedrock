(** Compiling the deeply embedded programming language *)

Require Import AutoSep Wrap Malloc.

Require Import Depl.Logic Depl.Cancel Depl.AlgebraicDatatypes Depl.Statements.


(** * Lowering DEPL expressions to Bedrock SPS expressions *)

Definition exprC (e : expr) : rvalue' :=
  match e with
    | Var x => x
    | Const w => w
  end.
(** The above looks like a bit of magic.  It's all in the coercions (from main Bedrock library). *)

Theorem exprC_correct : forall specs P stn st xs V vs fE e e' res,
  vars_ok fE V vs
  -> exprD vs e = Some e'
  -> exprV xs e
  -> ~In "rp" xs
  -> interp specs (![locals ("rp" :: xs) V res (Regs st Sp) * P] (stn, st))
  -> exists w,
    evalRvalue stn st (exprC e xs) = Some w
    /\ Logic.exprD e' fE = Dyn w.
Proof.
  destruct e; simpl; intuition.

  injection H0; clear H0; intros; subst; eauto.

  assert (Hnone : evalInstrs stn st (IL.Assign Rv (variableSlot x xs) :: nil) <> None).
  simp.
  generalize dependent H0.
  evaluate auto_ext.

  assert (Hsome : forall st', evalInstrs stn st (IL.Assign Rv (variableSlot x xs) :: nil) = Some st'
    -> Regs st' Rv = sel V x).
  simp.
  generalize dependent H0.
  evaluate auto_ext; auto.

  Transparent evalInstrs.
  simpl in *.
  Opaque evalInstrs.
  match goal with
    | [ |- exists x, ?X = _ /\ _ ] => destruct X; try tauto
  end.
  specialize (Hsome _ eq_refl); simpl in *.
  rewrite rupd_eq in Hsome; subst.
  eauto.
Qed.


(** * Lowering statements *)

Definition SimpleSeq (ch1 ch2 : chunk) : chunk := fun ns res =>
  Structured nil (fun im mn H => Seq_ H (toCmd ch1 mn H ns res) (toCmd ch2 mn H ns res)).
Local Infix ";;" := SimpleSeq : SP_scope.

Fixpoint stmtC (s : stmt) : chunk :=
  match s with
    | Assign x e => x <- exprC e
    | Seq s1 s2 => stmtC s1;; stmtC s2
    | Ret e => Return (exprC e)
  end%SP.

(** Version of [Logic.predD] specialized to predicates with no free higher-order variables *)
Definition predD (p : pred) (fE : fo_env) : HProp :=
  predD p (fun _ _ => Emp)%Sep fE.

(** Helper to copy formal parameter values from a [vals] to a [fo_env] *)
Fixpoint formals (V : vals) (xs : list pr_var) (fE : fo_env) : fo_env :=
  match xs with
    | nil => fE
    | x :: xs => fo_set (formals V xs fE) x (Dyn (sel V x))
  end.

(** Generic precondition of a statement, translated to base Bedrock from Depl-speak *)
Definition precond (vs : vars) (pre post : pred) :=
  (* First, quantify over a context assigning values to specification variables. *)
  Al fE,
    (* Naturally, we rely on the malloc() data structures being around. *)
    PRE[V] mallocHeap 0
      (* We also need the Depl precondition, of course. *)
      * predD pre fE
      (* Finally, the symbolic variable valuation should be accurate. *)
      * [| vars_ok fE V vs |]
    POST[R] mallocHeap 0
      (* The postcondition holds, in an [fo_env] that lets it mention the return value. *)
      * predD post (fo_set fE "result" (Dyn R)).

(** Generic postcondition of a statement *)
Definition postcond (vs : vars) (pre post : pred) (s : stmt) :=
  match stmtD vs s with
    | Error =>
      (* It's going to crash.  No guarantees! *)
      fun _ _ _ _ => st ~> [| True |]
    | Returned _ =>
      (* We returned already.  Unreachable! *)
      PREonly[_] [| False |]
    | Success vs' =>
      (* Still executing. *)
      precond vs' pre post
  end.

(** * Key lemmas to pass to Wrap *)

Lemma vars_ok_sel : forall fE V vs,
  vars_ok fE (sel V) vs = vars_ok fE V vs.
Proof.
  auto.
Qed.

Hint Rewrite vars_ok_sel.

(* Use a hypothesis telling us an expanded form implied by the known precondition. *)
Ltac pre_implies :=
  match goal with
    | [ H : interp _ _, H' : forall specs0 : codeSpec _ _, _ |- _ ] =>
      apply H' in H; clear H'; post
  end.

(* Case-split on an [option] being [match]ed in conclusion. *)
Ltac case_option :=
  match goal with
    | [ |- context[match ?E with None => _ | _ => _ end] ] =>
      match E with
        | context[match _ with None => _ | _ => _ end] => fail 1
        | _ => case_eq E; post
      end
  end; autorewrite with core in *.

(* Ditto, for the [outcome] type *)
Ltac case_outcome :=
  match goal with
    | [ |- context[match ?E with Error => _ | _ => _ end] ] =>
      match E with
        | context[match _ with Error => _ | _ => _ end] => fail 1
        | _ => case_eq E; post
      end
  end; autorewrite with core in *.

(* Use a hypothesis about some fact olding for all members of a list. *)
Ltac use_In :=
  match goal with
    | [ H : forall x, In x ?xs -> _, H' : In _ ?xs |- _ ] =>
      specialize (H _ H')
  end.

(* Use [evaluate] to get pure facts in a precondition into the normal proof context. *)
Ltac pre_evalu :=
  repeat match goal with
           | [ H : evalInstrs _ _ _ = _ |- _ ] => generalize dependent H
           | [ H : _ _ = Some _ |- _ ] => generalize dependent H
           | [ H : _ _ = None -> False |- _ ] => generalize dependent H
           | [ x : _ -> option Logic.expr |- _ ] => change vars in x
         end;
  try match goal with
        | [ _ : interp _ (![_] (fst ?st, _)) |- _ ] =>
          destruct st; simpl in *
      end; clear_fancy; evaluate auto_ext; intros.

(* Clear hypotheses that will confuse Bedrock automation. *)
Ltac cancl_clear :=
  repeat match goal with
           | [ H : _ _ = Some _ |- _ ] => clear H
           | [ H : (_ _ <> None)%type |- _ ] => clear H
           | [ H : _ _ = None -> False |- _ ] => clear H
         end.

(* Use separation logic entailment from a hypothesis to conclusion. *)
Ltac cancl :=
  match goal with
    | [ _ : interp ?specs1 (![_] (?s1, ?x1)) |- interp ?specs2 (![_] (?s2, ?x2)) ] =>
      equate specs1 specs2; equate s1 s2; equate x1 x2;
      cancl_clear; cancel auto_ext
    | [ |- interp _  (![_]%PropX _ ---> ![_]%PropX _) ] => cancl_clear; cancel auto_ext
  end.

(* Apply the [exprC_correct] lemma, using cancelation to prove one of its premises. *)
Ltac exprC_correct :=
  match goal with
    | [ H : exprD _ _ = Some _ |- _ ] => eapply exprC_correct in H; eauto; try cancl;
      try match goal with
            | [ H : exists x, _ /\ _ |- _ ] => destruct H as [ ? [ ] ]
          end
  end.

Lemma determine_rvalue : forall stn st lv rv st' w,
  evalInstrs stn st (IL.Assign lv rv :: nil) = Some st'
  -> evalRvalue stn st rv = Some w
  -> evalInstrs stn st (IL.Assign lv w :: nil) = Some st'.
Proof.
  Transparent evalInstrs.
  simpl; intros.
  rewrite H0 in *; auto.
  Opaque evalInstrs.
Qed.

(* Use a previous conclusion of [exprC_correct] to simplify an [evalInstrs] hypothesis. *)
Ltac determine_rvalue :=
  match goal with
    | [ H1 : evalInstrs _ _ _ = Some _, H2 : evalRvalue _ _ _ = Some _ |- _ ] =>
      eapply determine_rvalue in H1; [ clear H2 | exact H2 ]
  end.

(* Full symbolic evaluation *)
Ltac evalu :=
  try determine_rvalue; simp;
    repeat match goal with
             | [ H : _ _ = Some _ |- _ ] => generalize dependent H
             | [ H : _ _ = None -> False |- _ ] => generalize dependent H
           end; clear_fancy; evaluate auto_ext; intros.



Ltac my_descend := descend; autorewrite with core.
Hint Rewrite sel_upd_ne using (intro; subst; tauto).

Lemma string_eq_complete : forall s1 s2,
  if string_eq s1 s2 then s1 = s2 else s1 <> s2.
Proof.
  intros; destruct (string_dec s1 s2); subst.
  rewrite string_eq_true; auto.
  rewrite string_eq_false; auto.
Qed.

Lemma vars_ok_upd : forall fE V vs x w e,
  vars_ok fE V vs
  -> Logic.exprD e fE = Dyn w
  -> vars_ok fE (upd V x w) (vars_set vs x e).
Proof.
  unfold vars_ok, sel, upd, vars_set; intros.
  generalize (string_eq_complete x0 x).
  destruct (string_eq x0 x), (string_dec x0 x); intuition.
Qed.

Local Hint Resolve vars_ok_upd.

Lemma stmtD_monotone' : forall x s vs vs',
  vs x <> None
  -> stmtD vs s = Success vs'
  -> vs' x <> None.
Proof.
  induction s; simpl; intuition.

  repeat match goal with
           | [ _ : context[match ?E with None => _ | _ => _ end] |- _ ] =>
             match E with
               | context[match _ with None => _ | _ => _ end] => fail 1
               | _ => destruct E
             end
         end; intuition.
  injection H0; clear H0; intros; subst.
  apply H.
  unfold vars_set in H1.
  destruct (string_dec x x0); congruence.

  specialize (IHs1 vs).
  destruct (stmtD vs s1); intuition eauto.

  destruct (exprD vs e); discriminate.
Qed.

(** Let's restate that to be friendlier to [eauto]. *)
Lemma stmtD_monotone : forall x s vs vs',
  vs x <> None
  -> stmtD vs s = Success vs'
  -> vs' x = None -> False.
Proof.
  generalize stmtD_monotone'; eauto.
Qed.

Local Hint Resolve stmtD_monotone.

(** When starting in an unsatisfiable precondition, the postcondition is also unsatisfiable. *)
Lemma preserve_unsat : forall im mn (H : importsGlobal im) ns res specs s stn st pre,
  interp specs (Structured.Postcondition (toCmd (stmtC s) mn H ns res pre) (stn, st))
  -> (forall stn st, interp specs (pre (stn, st)) -> False)
  -> False.
Proof.
  induction s; simpl; post; eauto.
Qed.

(** Use what we know about the result of executing a statement to simplify a [postcond] hyp. *)
Ltac simplify_postcond :=
  match goal with
    | [ H : interp _ (postcond _ _ _ _ _ _ _ _ _) |- _ ] => unfold postcond in H;
      match type of H with
        | context[stmtD ?vs ?s] =>
          match goal with
            | [ H' : stmtD ?vs' s = _ |- _ ] =>
              equate vs vs'; rewrite H' in H; eauto
          end
      end
  end.

(** Use all induction hypotheses cleverly. *)
Ltac Stmt_post_IH' :=
  try match goal with
        | [ IH : forall st : settings * state, _, H : interp _ (Structured.Postcondition _ _) |- _ ] =>
          eapply IH in H; clear IH; try auto;
            try match goal with
                  | [ |- forall specs : codeSpec _ _, _ ] =>
                    intros; Stmt_post_IH'
                end; eauto; try simplify_postcond; post
      end.

Ltac Stmt_post_IH := try solve [ Stmt_post_IH'
  | exfalso; eapply preserve_unsat; eauto;
    intros; Stmt_post_IH'; match goal with
                             | [ H : importsGlobal _ |- _ ] => clear dependent H
                           end; pre_evalu; tauto ].

Lemma Stmt_post : forall post im mn (H : importsGlobal im) ns res,
  ~In "rp" ns
  -> forall s st pre pre0 specs vs,
    (forall specs0 st0,
      interp specs0 (pre0 st0)
      -> interp specs0 (precond vs pre post true (fun x => x) ns res st0))
    -> stmtV ns s
    -> (forall x, In x ns -> vs x <> None)
    -> interp specs (Structured.Postcondition (toCmd (stmtC s) mn H ns res pre0) st)
    -> interp specs (postcond vs pre post s true (fun x => x) ns res st).
Proof.
  induction s; repeat post; intuition; (unfold postcond; post;
    repeat (pre_implies || use_In || case_option || case_outcome); Stmt_post_IH;
      try (pre_evalu; exprC_correct); evalu;
        my_descend; repeat (my_descend; cancl || (step auto_ext; my_descend))).
Qed.

(*
(** Main statement compiler/combinator/macro *)
Definition Stmt
  (xs : list pr_var)
  (* Program variables available to mention *)
  (vs : vars)
  (* Symbolic valuation to those variables *)
  (pre post : pred)
  (* The Depl-level separation-logic specification for this statement *)
  (s : stmt)
  (* The statement to compile *)
  : chunk.
  apply (WrapC (stmtC s)
    (precond vs pre post)
    (postcond vs pre post s)

    (* VERIFICATION CONDITION *)
    (fun _ xs' _ =>
      incl xs xs'
      :: nil)).
*)
