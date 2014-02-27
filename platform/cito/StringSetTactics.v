Set Implicit Arguments.

Require Import StringSet.
Require Import StringSetFacts.
Import StringSet.
Import FSetNotations.

Local Open Scope fset_scope.

Ltac subset_solver :=
  repeat
    match goal with
      | |- ?A <= ?A => eapply subset_refl
      | |- empty <= _ => eapply subset_empty
      | |- _ + _ <= _ => eapply union_subset_3
      | |- ?S <= ?A + _ =>
        match A with
            context [ S ] => eapply subset_trans; [ | eapply union_subset_1]
        end
      | |- ?S <= _ + ?B =>
        match B with
            context [ S ] => eapply subset_trans; [ .. | eapply union_subset_2]
        end
    end.

Local Close Scope fset_scope.