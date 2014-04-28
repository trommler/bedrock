(** * Logical expression notations *)

Require Import Depl.Logic.

Notation "!" := Dyn.

Definition Var' : string -> expr := Var.
Coercion Var' : string >-> expr.

Notation "|^ fE , e |" := (Lift (fun fE => e)) (fE at level 0) : expr_scope.
Delimit Scope expr_scope with expr.
Bind Scope expr_scope with expr.


(** * Predicate notations *)

Notation "|^ fE , P |" := (Pure (fun fE => P%type)) (fE at level 0) : pred_scope.

Delimit Scope pred_scope with pred.
Bind Scope pred_scope with pred.

Infix "*" := Star : pred_scope.
Notation "'EX' x , p" := (Exists x p%pred) (at level 89) : pred_scope.
Notation "'Emp'" := (Pure (fun _ => True)) : pred_scope.
Notation "e1 = e2" := (Equal e1%expr e2%expr) : pred_scope.
Notation "# X ( e1 , .. , eN )" := (Named X (@cons expr e1%expr (.. (@cons expr eN%expr nil) ..)))
  (X at level 0) : pred_scope.


(** * Program function spec notations *)

Require Import Depl.Statements.

Record fspec := {
  SpecVars_ : list fo_var;
  Formals_ : list pr_var;
  Precondition_ : pred;
  Postcondition_ : pred
}.

Notation "'PRE' pre 'POST' post" := {| SpecVars_ := nil;
  Formals_ := nil;
  Precondition_ := pre%pred;
  Postcondition_ := post%pred
|} (at level 88) : spec_scope.

Notation "'ARGS' () s" := s (at level 89) : spec_scope.

Notation "'ARGS' ( x1 , .. , xN ) s" := {| SpecVars_ := SpecVars_ s;
  Formals_ := cons x1 (.. (cons xN nil) ..);
  Precondition_ := Precondition_ s;
  Postcondition_ := Postcondition_ s
|} (at level 89) : spec_scope.

Notation "'AL' x , s" := {| SpecVars_ := x :: SpecVars_ s;
  Formals_ := Formals_ s;
  Precondition_ := Precondition_ s;
  Postcondition_ := Postcondition_ s
|} (at level 89, x at level 0) : spec_scope.

Delimit Scope spec_scope with spec.
Bind Scope spec_scope with fspec.


(** * Program expression notations *)

Definition Var'' : string -> expr := Var.
Coercion Var'' : string >-> expr.
Coercion Const : W >-> expr.


(** * Program statement notations *)

Infix "<-" := Assign : stmt_scope.
Infix ";;" := Seq : stmt_scope.
Notation "'Return' e" := (Ret e) : stmt_scope.
Notation "x <-- # con ( e1 , .. , eN )" := (Allocate x con (@cons expr e1 (.. (@cons expr eN nil) ..)))
  (no associativity, at level 95, con at level 0) : stmt_scope.

Delimit Scope stmt_scope with stmt.
Bind Scope stmt_scope with stmt.


(** * Program function notations *)

Require Import Depl.AlgebraicDatatypes.

Record func := {
  Name_ : string;
  Spec_ : fspec;
  Locals_ : list pr_var;
  Body_ : stmt
}.

Inductive defn :=
  | Dtype (dt : datatype)
  | Func (fu : func).

Notation "'dfunction' name [ p ] b 'end'" := (Func {|
  Name_ := name;
  Spec_ := p%spec;
  Locals_ := nil;
  Body_ := b%stmt
|}) (no associativity, at level 95, name at level 0, only parsing) : func_scope.

Notation "'dfunction' name [ p ] 'Locals' x1 , .. , xN 'in' b 'end'" := (Func {|
  Name_ := name;
  Spec_ := p%spec;
  Locals_ := cons x1 (.. (cons xN nil) ..);
  Body_ := b%stmt
|}) (no associativity, at level 95, name at level 0, only parsing) : func_scope.

Delimit Scope func_scope with func.


(** * Datatype definition notations *)

Notation "# con ( nr1 , .. , nrN ; r1 , .. , rN ) p" := {|
  Name := con;
  Recursive := cons r1 (.. (cons rN nil) ..);
  Nonrecursive := cons nr1 (.. (cons nrN nil) ..);
  Condition := p%pred
|} (no associativity, at level 95, con at level 0) : con_scope.

Notation "# con ( ; r1 , .. , rN ) p" := {|
  Name := con;
  Recursive := cons r1 (.. (cons rN nil) ..);
  Nonrecursive := nil;
  Condition := p%pred
|} (no associativity, at level 95, con at level 0) : con_scope.

Notation "# con ( nr1 , .. , nrN ; ) p" := {|
  Name := con;
  Recursive := nil;
  Nonrecursive := cons nr1 (.. (cons nrN nil) ..);
  Condition := p%pred
|} (no associativity, at level 95, con at level 0) : con_scope.

Delimit Scope con_scope with con.
Bind Scope con_scope with con.

Notation "{{ x 'with' .. 'with' y }}" := (cons x%con .. (cons y%con nil) ..) (only parsing) : cons_scope.
Delimit Scope cons_scope with cons.

Notation "'dtype' name = cs" := (Dtype (name, cs%cons))
  (no associativity, at level 95, name at level 0, cs at level 0) : func_scope.


(** * Program module notations *)

Fixpoint separate (ds : list defn) : list datatype * list func :=
  match ds with
    | nil => (nil, nil)
    | Dtype dt :: ds =>
      let (dts, fs) := separate ds in
        (dt :: dts, fs)
    | Func fu :: ds =>
      let (dts, fs) := separate ds in
        (dts, fu :: fs)
  end.

Require Import Depl.CompileModule.

Definition funcOut (f : func) : function := {|
  Name := Name_ f;
  SpecVars := SpecVars_ (Spec_ f);
  Formals := Formals_ (Spec_ f);
  Locals := Locals_ f;
  Precondition := Precondition_ (Spec_ f);
  Postcondition := Postcondition_ (Spec_ f);
  Body := Body_ f
|}.

Notation "{{ x 'with' .. 'with' y }}" := (cons x%func .. (cons y%func nil) ..) (only parsing) : funcs_scope.
Delimit Scope funcs_scope with funcs.

Notation "'dmodule' name ds" := (let (dts, fs) := separate ds%funcs in
                                 compileModule dts {| MName := name;
                                                      Functions := map funcOut fs |})
  (no associativity, at level 95, name at level 0, only parsing).


(** * Tactics *)

(* There is a somewhat intricate little dance here to get good reduction behavior.
 * First, we normalize enough to expose potentially worrying uses of [in_dec string_dec],
 * where delta-expanding those identifiers would lead to unpleasantly large terms. *)
Ltac depl_cbv1 := cbv beta iota zeta
   delta [CompileModule.makeVcs CompileModule.Functions map funcOut
         CompileModule.functionVc CompileModule.Postcondition
         CompileModule.Formals SpecVars_ Formals_ Precondition_
         Postcondition_ Name_ Spec_ Locals_ Body_ Logic.wellScoped
         CompileModule.Body app CompileModule.Locals
         CompileModule.Precondition CompileModule.SpecVars Logic.normalize
         Statements.stmtD Statements.exprD Statements.sentail Cancel.cancel
         Cancel.findMatchings Logic.NQuants Logic.NImpure Logic.NPure
         Logic.nsubst Statements.lookupCon Statements.lookupCon'
         AlgebraicDatatypes.normalizeDatatype fst snd
         AlgebraicDatatypes.NName AlgebraicDatatypes.normalizeCon
         AlgebraicDatatypes.Name AlgebraicDatatypes.Nonrecursive
         AlgebraicDatatypes.Recursive AlgebraicDatatypes.Condition
         AlgebraicDatatypes.NRecursive AlgebraicDatatypes.NNonrecursive
         AlgebraicDatatypes.NCondition plus sumbool_rec sumbool_rect
         Logic.notsInList Logic.notInList string_rec string_rect
         append Ascii.ascii_dec Ascii.ascii_rec Ascii.ascii_rect
         Bool.bool_dec bool_rec bool_rect eq_rec_r eq_rec eq_rect eq_sym
         Statements.exprsD
         AlgebraicDatatypes.allocatePre AlgebraicDatatypes.nsubsts
         Peano_dec.eq_nat_dec string_eq ascii_eq Bool.eqb andb nat_rec nat_rect length
         AlgebraicDatatypes.recursives Cancel.findMatching Logic.psubst
         Logic.esubst Var' Cancel.sub_expr Cancel.findMatching'
         Cancel.unify_pred Cancel.unify_expr Cancel.fos_set Cancel.unify_args Var''
         Statements.vars_set].

(** Now we [destruct] string comparisons. *)
Ltac streq :=
  repeat match goal with
           | [ |- context[string_dec ?X ?Y] ] =>
             destruct (string_dec X Y); try congruence; [ clear ]
           | [ |- context[in_dec string_dec ?X ?Y] ] =>
             destruct (in_dec string_dec X Y);
               try (exfalso; simpl in *; intuition congruence); [ clear ]
         end.

(* Next, we find the little marker predicates we used in Cancel to indicate where the
 * troubling [in_dec]s are, and we hide them inside this guy here. *)
Definition sin_dec := in_dec string_dec.
Ltac switch_to_sin_dec :=
  repeat match goal with
           | [ |- appcontext[Cancel.hide_sub ?s] ] =>
             let s' := fresh "s'" in pose (s' := s);
               change (in_dec string_dec) with sin_dec in s';
                 let s'' := eval unfold s' in s' in
                   change (Cancel.hide_sub s) with s''; clear s'
         end.

(* Finally, we can do a proper full evaluation, including unfolding of [in_dec] and [string_dec],
 * but not [sin_dec]. *)
Ltac depl_cbv2 := cbv beta iota zeta delta [CompileModule.makeVcs CompileModule.Functions map funcOut
  CompileModule.functionVc CompileModule.Postcondition Statements.stmtV
  CompileModule.Formals
  SpecVars_ Formals_ Precondition_ Postcondition_
  Name_ Spec_ Locals_ Body_ Logic.wellScoped CompileModule.Body
  Logic.normalize Statements.stmtD CompileModule.Precondition app
  CompileModule.Locals Statements.sentail Statements.exprV Statements.exprD
  Cancel.cancel Cancel.findMatchings Logic.NQuants Logic.NImpure Logic.NPure
  Logic.nsubst CompileModule.SpecVars Cancel.findMatching Cancel.findMatching' Logic.predExt Var' Var''
  CompileModule.vars0 Logic.exprD Statements.vars_set Logic.fo_set
  in_dec list_rec list_rect
  string_dec string_rec string_rect
  Ascii.ascii_dec Ascii.ascii_rec Ascii.ascii_rect sumbool_rec sumbool_rect
  Bool.bool_dec bool_rec bool_rect eq_rec_r eq_rec eq_rect eq_sym append
  allocatePre nsubsts recursives
  lookupCon lookupCon' normalizeDatatype fst snd].

(* Put them all together. *)
Ltac depl_cbv := depl_cbv1; streq; switch_to_sin_dec.

Ltac isConst E :=
  match E with
    | Ascii.Ascii _ _ _ _ _ _ _ _ => idtac
    | "" => idtac
    | String ?a ?ls => isConst a; isConst ls
    | @nil _ => idtac
    | ?a :: ?ls => isConst a; isConst ls
  end.

(* Simplify one of the syntactic well-formedness side conditions generated by [compileModule_ok]. *)
Ltac depl_wf :=
  match goal with
    | [ |- stmtV _ _ _ ] => simpl; tauto
    | [ |- Compile.datatypesWf _ ] =>
      repeat (econstructor; simpl in *; intros); simpl in *; intuition (try congruence);
        match goal with
          | [ H : forall x : Logic.fo_var, _ -> _ = _ |- _ ] =>
            repeat rewrite H by tauto; reflexivity
        end
    | [ |- forall fE fE' : Logic.fo_var -> Logic.dyn, (forall x, In x _ -> fE x = fE' x) -> _ = _ ] =>
      simpl; intros fE fE' Heq;
        repeat rewrite Heq by tauto; reflexivity
    | [ |- forall x : Logic.fo_var, In x _ -> _ <> None ] => simpl In; intuition subst; congruence
    | [ |- forall fE : Logic.fo_env, List.Forall _ _ ] => intro;
      repeat match goal with
               | [ |- List.Forall _ _ ] => constructor
             end
    | [ |- forall fE fE' : Logic.fo_var -> Logic.dyn, (forall x, (if _ then _ else None) <> None -> fE x = fE' x)  -> _ = _ ] =>
      intros fE fE' Heq;
        repeat rewrite Heq by (simpl; congruence); reflexivity
    | [ |- In ?x ?ls ] => isConst x; isConst ls; simpl; tauto
    | [ |- forall x : Logic.fo_var, In x _ -> exists e : Logic.expr, _ ] =>
      simpl; intuition (subst; simpl; eauto)
    | [ |- forall fE fE' : Logic.fo_var -> Logic.dyn, _ -> forall e : Logic.expr, In _ _ -> _ ] =>
      simpl; intuition (subst; auto)
  end;
  try match goal with
        | [ |- Logic.exprD _ _ = Logic.exprD _ _ ] =>
          simpl; match goal with
                   | [ H : forall x : Logic.fo_var, _ |- _ ] => repeat rewrite H by tauto
                 end; reflexivity
      end.

Ltac depl := apply CompileModule.compileModule_ok; [ constructor
  | hnf; NoDup
  | reflexivity
  | depl_wf
  | reflexivity
  | depl_cbv;
    match goal with
      | [ |- vcs ?Ps ] => apply (vcsImp_correct Ps)
    end;
    repeat match goal with
             | [ |- _ /\ _ ] => split
           end; repeat depl_wf
  | simpl; discriminate ].
