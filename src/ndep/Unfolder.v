Require Import EqdepClass List.

Require Import Heaps Reflect.
Require Import Bedrock.ndep.SepExpr.
Require Import Bedrock.ndep.Expr Bedrock.ndep.ExprUnify.

Set Implicit Arguments.

Require Bedrock.ndep.NatMap.

Module FM := Bedrock.ndep.NatMap.IntMap.    

Module Make (B : Heap) (ST : SepTheoryX.SepTheoryXType B).

  Module SE := SepExpr(B)(ST).
  Import SE.

  Section env.
    Variable types : list type.
    Variable funcs : functions types.
    
    Variable pcType : tvar.
    Variable stateType : tvar.
    Variable stateMem : tvarD types stateType -> B.mem.

    Variable sfuncs : sfunctions types pcType stateType.

    (** The type of one unfolding lemma *)

    Record lemma := {
      Foralls : variables;
      (* The lemma statement begins with this sequence of [forall] quantifiers over these types. *)
      Hyps : list (expr types);
      (* Next, we have this sequence of pure hypotheses. *)
      Lhs : sexpr types pcType stateType;
      Rhs : sexpr types pcType stateType
      (* Finally, we have this separation implication, with lefthand and righthand sides. *)
    }.

    (** Helper function to add a sequence of implications in front of a [Prop] *)

    Definition hypD (H : expr types) (env : env types) : Prop :=
      match exprD funcs nil env H tvProp with
        | None => False
        | Some P => P
      end.

    Fixpoint implyEach (Hs : list (expr types)) (env : env types) (P : Prop) : Prop :=
      match Hs with
        | nil => P
        | H :: Hs' => hypD H env -> implyEach Hs' env P
      end.

    (** The meaning of a lemma statement *)

    (* Redefine to use the opposite quantifier order *)
    Fixpoint forallEachR (ls : variables) : (env types -> Prop) -> Prop :=
      match ls with
        | nil => fun cc => cc nil
        | a :: b => fun cc =>
          forallEachR b (fun r => forall x : tvarD types a, cc (existT _ a x :: r))
      end.

    Definition lemmaD (lem : lemma) : Prop :=
      forallEachR (Foralls lem) (fun env =>
        implyEach (Hyps lem) env
        (forall specs, himp funcs sfuncs nil nil env specs (Lhs lem) (Rhs lem))).

    (** Preprocessed databases of hints *)

    Definition hintSide := list lemma.
    (* A complete set of unfolding hints of a single sidedness (see below) *)

    Definition hintSideD := Forall lemmaD.

    Record hintsPayload := {
      Forward : hintSide;
      (* Apply on the lefthand side of an implication *)
      Backward : hintSide
      (* Apply on the righthand side *);
      ForwardOk : hintSideD Forward;
      BackwardOk : hintSideD Backward
    }.

    (** Applying up to a single hint to a hashed separation formula *)

    Definition fmFind A B (f : nat -> A -> option B) (m : FM.t A) : option B :=
      FM.fold (fun k v res =>
        match res with
          | Some _ => res
          | None => f k v
        end) m None.

    Fixpoint find A B (f : A -> option B) (ls : list A) : option B :=
      match ls with
        | nil => None
        | x :: ls' => match f x with
                        | None => find f ls'
                        | v => v
                      end
      end.

    Fixpoint findWithRest' A B (f : A -> list A -> option B) (ls acc : list A) : option B :=
      match ls with
        | nil => None
        | x :: ls' => match f x (rev_append acc ls') with
                        | None => findWithRest' f ls' (x :: acc)
                        | v => v
                      end
      end.

    Definition findWithRest A B (f : A -> list A -> option B) (ls : list A) : option B :=
      findWithRest' f ls nil.

    (* As we iterate through unfolding, we modify this sort of state. *)
    Record unfoldingState := {
      Vars : variables;
      UVars : variables;
      Heap : SHeap types pcType stateType;
      Subs : Subst types
    }.

    Section unfoldOne.
      Variable hs : hintSide.

      (* Returns [None] if no unfolding opportunities are found.
       * Otherwise, return state after one unfolding. *)
      Definition unfoldForward (s : unfoldingState) : option unfoldingState :=
        (* Iterate through all the entries for impure functions. *)
        fmFind (fun f =>
          (* Iterate through all the arguments passed to the current function. *)
          findWithRest (fun args argss =>
            (* Iterate through all hints. *)
            find (fun h =>
              (* Check if the hint's head symbol matches the impure call we are considering. *)
              match Lhs h with
                | Func f' args' =>
                  if equiv_dec f' f then
                    (* We must tweak the arguments by substituting unification variables for [forall]-quantified variables from the lemma statement. *)
                    let args' := map (exprSubstU O (length (Foralls h)) (length (UVars s))) args' in

                    (* Unify the respective function arguments. *)
                    match exprUnifyArgs args' args (Subs s) (empty_Subst types) with
                      | None => None
                      | Some (subs, _) =>
                        (* Remove the current call from the state, as we are about to replace it with a simplified set of pieces. *)
                        let impures' := FM.add f argss (impures (Heap s)) in
                        let sh := {| impures := impures';
                          pures := pures (Heap s);
                          other := other (Heap s) |} in

                        (* Time to hash the hint RHS, to (among other things) get the new existential variables it creates. *)
                        let (exs, sh') := hash (Rhs h) in

                        (* The final result is obtained by joining the hint RHS with the original symbolic heap. *)
                        Some {| Vars := Vars s ++ exs;
                          UVars := UVars s;
                          Heap := star_SHeap sh sh';
                          Subs := subs |}
                    end
                  else
                    None
                | _ => None
              end) hs)) (impures (Heap s)).
    End unfoldOne.

  End env.

  (** Package hints together with their environment/parameters. *)
  Record hints := {
    Types : list type;
    Functions : functions Types;
    PcType : tvar;
    StateType : tvar;
    SFunctions : sfunctions Types PcType StateType;
    Hints : hintsPayload Functions SFunctions
  }.


  (** * Reflecting hints *)

  (* This tactic processes the part of a lemma statement after the quantifiers. *)
  Ltac collectTypes_hint' P types k :=
    match P with
      | fun x => @?H x -> @?P x =>
        let types := collectTypes_expr H types in
          collectTypes_hint' P types k
      | fun x => forall cs, @ST.himp ?pcT ?stT cs (@?L x) (@?R x) =>
        collectTypes_sexpr L types ltac:(fun types =>
          collectTypes_sexpr R types k)
    end.

  (* This tactic adds quantifier processing. *)
  Ltac collectTypes_hint P types k :=
    match P with
      | fun xs : ?T => forall x : ?T', @?f xs x =>
        match T' with
          | PropX.codeSpec _ _ => fail 1
          | _ => match type of T' with
                   | Prop => fail 1
                   | _ => let P := eval simpl in (fun x : VarType (T * T') =>
                     f (@openUp _ T (@fst _ _) x) (@openUp _ T' (@snd _ _) x)) in
                   let types := cons_uniq T' types in
                     collectTypes_hint P types k
                 end
        end
      | _ => collectTypes_hint' P types k
    end.

  (* Finally, this tactic adds a loop over all hints. *)
  Ltac collectTypes_hints Ps types k :=
    match Ps with
      | tt => k types
      | (?P1, ?P2) =>
        collectTypes_hints P1 types ltac:(fun types =>
          collectTypes_hints P2 types k)
      | _ =>
        let T := type of Ps in
          collectTypes_hint (fun _ : VarType unit => T) types k
    end.

  (* Now we repeat this sequence of tactics for reflection itself. *)

  Ltac reflect_hint' pcType stateType isConst P types funcs sfuncs vars k :=
    match P with
      | fun x => @?H x -> @?P x =>
        reflect_expr isConst H types funcs (@nil type) vars ltac:(fun funcs H =>
          reflect_hint' pcType stateType isConst P types funcs sfuncs vars ltac:(fun funcs sfuncs P =>
            let lem := eval simpl in (Build_lemma (types := types) (pcType := pcType) (stateType := stateType)
              vars (H :: Hyps P) (Lhs P) (Rhs P)) in
            k funcs sfuncs lem))
      | fun x => forall cs, @ST.himp _ _ cs (@?L x) (@?R x) =>
        reflect_sexpr isConst L types funcs pcType stateType sfuncs (@nil type) vars ltac:(fun funcs sfuncs L =>
          reflect_sexpr isConst R types funcs pcType stateType sfuncs (@nil type) vars ltac:(fun funcs sfuncs R =>
            let lem := constr:(Build_lemma (types := types) (pcType := pcType) (stateType := stateType)
              vars nil L R) in
            k funcs sfuncs lem))
    end.

  Ltac reflect_hint pcType stateType isConst P types funcs sfuncs vars k :=
    match P with
      | fun xs : ?T => forall x : ?T', @?f xs x =>
        match T' with
          | PropX.codeSpec _ _ => fail 1
          | _ => match type of T' with
                   | Prop => fail 1
                   | _ =>
                     let P := eval simpl in (fun x : VarType (T' * T) =>
                       f (@openUp _ T (@snd _ _) x) (@openUp _ T' (@fst _ _) x)) in
                     let T' := reflectType types T' in
                       reflect_hint pcType stateType isConst P types funcs sfuncs (T' :: vars) k
                   | _ => fail 3
                 end
          | _ => fail 2
        end
      | _ => reflect_hint' pcType stateType isConst P types funcs sfuncs vars k
    end.

  Ltac reflect_hints pcType stateType isConst Ps types funcs sfuncs k :=
    match Ps with
      | tt => k funcs sfuncs (@nil (lemma types pcType stateType)) || fail 2
      | (?P1, ?P2) =>
        reflect_hints pcType stateType isConst P1 types funcs sfuncs ltac:(fun funcs sfuncs P1 =>
          reflect_hints pcType stateType isConst P2 types funcs sfuncs ltac:(fun funcs sfuncs P2 =>
            k funcs sfuncs (P1 ++ P2)))
        || fail 2
      | _ =>
        let T := type of Ps in
          reflect_hint pcType stateType isConst (fun _ : VarType unit => T) types funcs sfuncs (@nil tvar) ltac:(fun funcs sfuncs P =>
            k funcs sfuncs (P :: nil))
    end.

  Lemma Forall_app : forall A (P : A -> Prop) ls1 ls2,
    Forall P ls1
    -> Forall P ls2
    -> Forall P (ls1 ++ ls2).
    induction 1; simpl; intuition.
  Qed.

  (* Build proofs of combined lemma statements *)
  Ltac prove Ps :=
    match Ps with
      | tt => constructor
      | (?P1, ?P2) => apply Forall_app; [ prove P1 | prove P2 ]
      | _ => constructor; [ exact Ps | constructor ]
    end.

  (* Main entry point tactic, to generate a hint database *)
  Ltac prepareHints pcType stateType isConst types fwd bwd :=
    collectTypes_hints fwd (@nil Type) ltac:(fun rt =>
      collectTypes_hints bwd rt ltac:(fun rt =>
        let rt := constr:((pcType : Type) :: (stateType : Type) :: rt) in
        let types := extend_all_types rt types in
        let pcT := reflectType types pcType in
        let stateT := reflectType types stateType in
          reflect_hints pcT stateT isConst fwd types (@nil (signature types)) (@nil (ssignature types pcT stateT)) ltac:(fun funcs sfuncs fwd' =>
            reflect_hints pcT stateT isConst bwd types funcs sfuncs ltac:(fun funcs sfuncs bwd' =>
              refine {| Types := types;
                Functions := funcs;
                SFunctions := sfuncs;
                Hints := {| Forward := fwd';
                  Backward := bwd' |} |}; [ abstract prove fwd | abstract prove bwd ])))).

End Make.
