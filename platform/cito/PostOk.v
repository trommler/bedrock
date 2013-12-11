Require Import CompileStmtSpec CompileStmtImpl.

Set Implicit Arguments.

Section TopSection.

  Require Import Inv.

  Variable layout : Layout.

  Variable vars : list string.

  Variable temp_size : nat.

  Variable imports : LabelMap.t assert.

  Variable imports_global : importsGlobal imports.

  Variable modName : string.

  Require Import Syntax.
  Require Import Wrap.

  Definition compile := compile layout vars temp_size imports_global modName.

  Lemma post_ok : 
    forall (s k : Stmt) (pre : assert) (specs : codeSpec W (settings * state))
           (x : settings * state),
      vcs (verifCond layout vars temp_size s k pre) ->
      interp specs
             (Postcondition
                (compile s k pre) x) ->
      interp specs (postcond layout vars temp_size k x).
  Proof.

    Require Import Semantics.
    Require Import Safe.
    Require Import Notations.
    Require Import SemanticsFacts.
    Require Import ScopeFacts.
    Require Import ListFacts.
    Require Import StringSet.
    Require Import SetFacts.
    Require Import CompileStmtTactics.
    Require Import GeneralTactics.

    Open Scope stmt.

    Opaque funcs_ok.
    Opaque mult.
    Opaque star. (* necessary to use eapply_cancel *)

    Hint Resolve Subset_in_scope_In.
    Hint Extern 0 (Subset _ _) => progress (simpl; subset_solver).

    Set Printing Coercions.

    unfold verifCond, imply; induction s.

    Focus 5.
    (* call *)
    wrap0.
    post.
    destruct_state.
    hiding ltac:(evaluate auto_ext).
    unfold is_state in *.
    unfold frame_len_w in *.
    unfold frame_len in *.
    unfold temp_start in *.
    unfold var_slot in *.
    unfold vars_start in *.
    unfold SaveRet.runs_to in *.
    unfold SaveRet.is_state in *.
    simpl in *.
    transit.
    openhyp.
    descend.
    eauto.
    instantiate (5 := (_, _)); simpl.
    rewrite <- H in *.
    rewrite <- H1 in *.
    instantiate (5 := heap_upd_option h x8 x9).
    set (upd_option _ _ _) in H11.

    repeat hiding ltac:(step auto_ext).
    instantiate (1 := x3).
    hiding ltac:(step auto_ext).
    Require Import SepLemmas.
    eapply is_heap_upd_option_bwd.

    rewrite H5 in *.
    eapply H6.
    set (is_heap _) in *.
    set (layout_option _) in *.
    rearrange_stars (h0 h * h1 x8 x9)%Sep.
    eapply star_separated; eauto.
    eauto.
    eauto.
    eauto.

    repeat hiding ltac:(step auto_ext).

    descend.
    set (is_heap _) in *.
    set (layout_option _) in *.
    rearrange_stars (h0 h * h1 x8 x9)%Sep.
    eapply star_separated; eauto.

    (* skip *)

    intros.
    wrap0.
    eapply H3 in H0.
    unfold precond in *.
    unfold inv in *.
    unfold inv_template in *.
    post.
    descend.
    eauto.
    eauto.

    eapply Safe_Seq_Skip; eauto.
    eauto.
    eauto.
    eauto.

    repeat hiding ltac:(step auto_ext).
    descend.
    eapply RunsTo_Seq_Skip; eauto.

    (* seq *)
    wrap0.
    eapply IHs2 in H0.
    unfold postcond in *.
    unfold inv in *.
    unfold inv_template in *.
    post.

    wrap0.
    eapply IHs1 in H.
    unfold postcond in *.
    unfold inv in *.
    unfold inv_template in *.
    post.

    wrap0.
    eapply H3 in H1.
    unfold precond in *.
    unfold inv in *.
    unfold inv_template in *.
    post.
    descend.
    eauto.
    eauto.
    eapply Safe_Seq_assoc; eauto.

    eauto.
    eauto.
    eauto.
    repeat hiding ltac:(step auto_ext).
    descend.
    eapply RunsTo_Seq_assoc; eauto.
    eapply in_scope_Seq_Seq; eauto.
    eapply in_scope_Seq; eauto.

    (* if - true *)
    wrap0.
    eapply IHs1 in H.
    unfold postcond in *.
    unfold inv in *.
    unfold inv_template in *.
    post.

    wrap0.
    eapply H3 in H1.
    unfold precond in *.
    unfold inv in *.
    unfold inv_template in *.
    unfold CompileExpr.runs_to in *.
    unfold is_state in *.
    unfold CompileExpr.is_state in *.
    post.

    transit.

    destruct x4; simpl in *.
    post.
    descend.
    eauto.
    instantiate (5 := (_, _)).
    simpl.
    destruct x0; simpl in *.
    instantiate (6 := upd_sublist x5 0 x4).
    repeat rewrite length_upd_sublist.
    repeat hiding ltac:(step auto_ext).

    find_cond.
    eapply Safe_Seq_If_true; eauto.
    rewrite length_upd_sublist; eauto.
    eauto.
    eauto.

    repeat hiding ltac:(step auto_ext).

    descend.
    find_cond.
    eapply RunsTo_Seq_If_true; eauto.
    eapply in_scope_If_true; eauto.

    (* if - false *)
    wrap0.
    eapply IHs2 in H.
    unfold postcond in *.
    unfold inv in *.
    unfold inv_template in *.
    post.

    wrap0.
    eapply H3 in H1.
    unfold precond in *.
    unfold inv in *.
    unfold inv_template in *.
    unfold CompileExpr.runs_to in *.
    unfold is_state in *.
    unfold CompileExpr.is_state in *.
    post.

    transit.

    destruct x4; simpl in *.
    post.
    descend.
    eauto.
    instantiate (5 := (_, _)).
    simpl.
    destruct x0; simpl in *.
    instantiate (6 := upd_sublist x5 0 x4).
    repeat rewrite length_upd_sublist.
    repeat hiding ltac:(step auto_ext).

    find_cond.
    eapply Safe_Seq_If_false; eauto.
    rewrite length_upd_sublist; eauto.
    eauto.
    eauto.

    repeat hiding ltac:(step auto_ext).

    descend.
    find_cond.
    eapply RunsTo_Seq_If_false; eauto.
    eapply in_scope_If_false; eauto.

    (* while *)
    wrap0.
    post.
    descend.
    eauto.
    eauto.
    find_cond.
    eapply Safe_Seq_While_false; eauto.
    eauto.
    eauto.
    eauto.
    repeat hiding ltac:(step auto_ext).
    descend.
    find_cond.
    eapply RunsTo_Seq_While_false; eauto.

  Qed.

End TopSection.