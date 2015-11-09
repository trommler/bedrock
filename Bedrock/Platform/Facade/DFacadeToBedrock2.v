Set Implicit Arguments.

Require Import Bedrock.Platform.Cito.MakeWrapper.
Require Import Bedrock.Platform.Cito.ADT Bedrock.Platform.Cito.RepInv.

Module Make (Import E : ADT) (Import M : RepInv E).

  Module Import MakeWrapperMake := MakeWrapper.Make E M.
  Export MakeWrapperMake.

  Import LinkSpecMake.
  Require Import Bedrock.Platform.Cito.LinkSpecFacts.

  Require Import Bedrock.Platform.Cito.Inv.
  Module Import InvMake := Make E.
  Module Import InvMake2 := Make M.

  Import LinkSpecMake2.
  Require Import Bedrock.Platform.Cito.StringMap Bedrock.Platform.Cito.WordMap Bedrock.Platform.Cito.GLabelMap.

  Require Import Bedrock.Platform.Cito.LinkFacts.
  Module Import LinkFactsMake := Make E.

  Require Import Bedrock.Platform.Cito.CompileModule2.
  Module CM2 := CompileModule2.Make E M.

  Section TopSection.

    Notation AxiomaticSpec := (@AxiomaticSpec ADTValue).
    Variable exports : StringMap.t AxiomaticSpec.

    Require Import Bedrock.Platform.Facade.DFModule.
    Variable module : DFModule ADTValue.
    Require Import Bedrock.Platform.Cito.StringMapFacts.
    Hypothesis exports_in_domain : is_sub_domain exports (Funs module) = true.
    (* the name of the module that contains axiomatic export specs *)
    Variable ax_mod_name : string.
    (* the name of the module that contains operational export specs *)
    Variable op_mod_name : string.
    Hypothesis op_mod_name_ok : is_good_module_name op_mod_name = true.
    Require Import Bedrock.Platform.Cito.ListFacts3.
    Notation imports := (Imports module).
    Hypothesis op_mod_name_not_in_imports :
      let imported_module_names := List.map (fun x => fst (fst x)) (GLabelMap.elements imports) in
      List.forallb (fun x => negb (string_bool op_mod_name x)) imported_module_names = true.
    Hypothesis name_neq : negb (string_bool ax_mod_name op_mod_name) = true.

    Notation Value := (@Value ADTValue).
    Require Import Bedrock.Platform.Facade.DFacade.
    Require Import Bedrock.Platform.Facade.CompileDFModule.
    Require Import Bedrock.Platform.Facade.NameDecoration.
    Require Import Bedrock.Platform.Cito.StringMap.
    Import StringMap.
    Require Import Bedrock.Platform.Cito.StringMapFacts.
    Import FMapNotations.
    Local Open Scope fmap_scope.
    Require Import Bedrock.Platform.Facade.Listy.
    Import Notations Instances.
    Local Open Scope listy_scope.

    Definition good_module := compile_to_gmodule module op_mod_name op_mod_name_ok.
    Definition gmodules := good_module :: nil.
    Require Import Bedrock.Platform.Cito.GoodModuleDec.
    Require Import Bedrock.Platform.Cito.GoodModuleDecFacts.
    Require Import Bedrock.Platform.Cito.Semantics.
    Require Import Bedrock.Platform.Facade.CompileDFacadeToCito.
    Import WordMapFacts.FMapNotations.
    Local Open Scope fmap_scope.

    Require Import Bedrock.Platform.Facade.CompileRunsTo.
    Import StringMapFacts.FMapNotations.
    Require Import Coq.Setoids.Setoid.
    Import WordMapFacts.FMapNotations.
    Require Import Bedrock.Platform.Cito.StringMapFacts.
    Require Import Bedrock.Platform.Cito.GeneralTactics4.
    Arguments empty {_}.
    Require Import Bedrock.Platform.Cito.SemanticsUtil.
    Require Import Bedrock.Platform.Cito.SemanticsFacts9.
    Arguments store_pair {_} _ _.
    Import StringMapFacts StringMap.StringMap.
    Import StringMapFacts.FMapNotations.
    Import WordMapFacts.FMapNotations.
    Require Import Bedrock.Platform.Cito.GeneralTactics5.
    Arguments empty {_}.

    Import Made.

    Arguments CM2.make_module_ok : clear implicits. 

    Definition cito_module := compile_to_cmodule module.

    Import StringMapFacts.

    Lemma is_sub_domain_complete : forall elt1 elt2 (m1 : t elt1) (m2 : t elt2), sub_domain m1 m2 -> is_sub_domain m1 m2 = true.
    Proof.
      intros.
      unfold is_sub_domain, sub_domain in *.
      eapply forallb_forall.
      intros k Hin.
      eapply mem_in_iff; eauto.
      eapply H.
      Require Import SetoidListFacts.
      eapply In_InA in Hin.
      eapply In_In_keys; eauto.     
    Qed.

    Require Import CModule.

    Lemma exports_in_domain_cmodule : is_sub_domain exports (CModule.Funs cito_module) = true.
    Proof.
      simpl.
      eapply is_sub_domain_complete.
      eapply is_sub_domain_sound in exports_in_domain.
      intros k Hin.
      do 2 eapply StringMapFacts.map_in_iff.
      eauto.
    Qed.

    Import ChangeSpec.
    Import ProgramLogic2.
    Import SemanticsFacts4.
    Notation Internal := (@Internal ADTValue).
    Require Import Bedrock.Platform.Cito.GLabel.
    Require Import Bedrock.Platform.Cito.GLabelMap.
    Import GLabelMap.
    Require Import Bedrock.Platform.Cito.GLabelMapFacts.
    Import FMapNotations.
    Lemma strengthen_diff_intro : forall specs_diff env_ax specs, (forall lbl ax, find lbl specs_diff = Some ax -> find lbl specs = Some (Foreign ax) \/ exists op, find lbl specs = Some (Internal op) /\ strengthen_op_ax op ax env_ax) -> strengthen_diff specs specs_diff env_ax.
    Proof.
      do 3 intro.
      (* intros Hforall. *)
      (* unfold strengthen_diff. *)
      eapply fold_rec_bis with (P := fun specs_diff (H : Prop) => (forall lbl ax, find lbl specs_diff = Some ax -> find lbl specs = Some (Foreign ax) \/ exists op, find lbl specs = Some (Internal op) /\ strengthen_op_ax op ax env_ax) -> H); simpl.
      intros m m' a Heqm Ha Hforall.
      { 
        eapply Ha.
        intros lbl ax Hfind.
        rewrite Heqm in Hfind.
        eauto.
      }
      { eauto. }
      intros k e a m' Hmapsto Hnin Ha Hforall.
      unfold strengthen_diff_f.
      split.
      {
        eapply Ha.
        intros lbl ax Hfind.
        eapply Hforall.
        eapply find_mapsto_iff.
        eapply add_mapsto_iff.
        right.
        split.
        {
          intro Heq; subst.
          contradict Hnin.
          eapply MapsTo_In.
          eapply find_mapsto_iff.
          eauto.
        }
        eapply find_mapsto_iff.
        eauto.
      }
      eapply Hforall.
      eapply find_mapsto_iff.
      eapply add_mapsto_iff.
      left.
      eauto.
    Qed.

    Require Import Bedrock.Platform.Cito.StringMap.
    Import StringMap.
    Require Import Bedrock.Platform.Cito.StringMapFacts.
    Import FMapNotations.

    Lemma find_DFModule_find_CModule k m f :
      find k (DFModule.Funs (ADTValue := ADTValue) m) = Some f ->
      find k (Funs (compile_to_cmodule m)) = Some (CompileModule.compile_func (compile_func f)).
    Proof.
      intros Hfind.
      simpl.
      eapply find_mapsto_iff.
      rewrite map_mapsto_iff.
      eexists.
      split; eauto.
      rewrite map_mapsto_iff.
      eexists.
      split; eauto.
      eapply find_mapsto_iff.
      eauto.
    Qed.

    Import Transit.
    Import DFacade.
    Notation CEnv := ((glabel -> option W) * (W -> option (Callee _)))%type.
    Import ListFacts4.

    Require Import Bedrock.Platform.Cito.WordMap.
    Import WordMap.
    Require Import Bedrock.Platform.Cito.WordMapFacts.
    Import FMapNotations.

    Hint Extern 0 (_ == _) => reflexivity.

    Lemma good_inputs_make_heap_submap h pairs :
      good_inputs (ADTValue := ADTValue) h pairs ->
      make_heap pairs <= h.
    Proof.
      Require Import DFacadeToBedrock2Util.
      intros Hgi.
      destruct Hgi as [Hforall Hdisj].
      unfold good_inputs in *.
      intros k1 v Hk1.
      rewrite make_heap_make_heap' in * by eauto.
      Lemma mapsto_make_heap'_elim pairs :
        disjoint_ptrs pairs ->
        forall k (v : ADTValue),
          find k (make_heap' pairs) = Some v ->
          List.In (k, ADT v) pairs.
      Proof.
        induction pairs; intros Hdisj k v Hk; simpl in *.
        {
          rewrite empty_o in *.
          intuition.
        }
        eapply disjoint_ptrs_cons_elim in Hdisj.
        destruct Hdisj as [Hnc Hdisj].
        destruct a as [k' v']; simpl in *.
        unfold store_pair in *; simpl in *.
        destruct v' as [w | v']; simpl in *.
        {
          unfold store_pair in *; simpl in *.
          right.
          eapply IHpairs; eauto.
        }
        destruct (weq k k') as [? | Hne]; subst.
        {
          rewrite add_eq_o in * by eauto.
          inject Hk.
          left; eauto.
        }
        rewrite add_neq_o in * by eauto.
        eapply IHpairs in Hk; eauto.
      Qed.
      Lemma mapsto_make_heap'_intro pairs :
        disjoint_ptrs pairs ->
        forall k (v : ADTValue),
          List.In (k, ADT v) pairs ->
          find k (make_heap' pairs) = Some v.
      Proof.
        induction pairs; intros Hdisj k v Hk; simpl in *.
        {
          intuition.
        }
        eapply disjoint_ptrs_cons_elim in Hdisj.
        destruct Hdisj as [Hnc Hdisj].
        destruct a as [k' v']; simpl in *.
        unfold store_pair in *; simpl in *.
        destruct Hk as [Hk | Hk].
        {
          inject Hk.
          rewrite add_eq_o in * by eauto.
          eauto.
        }
        destruct v' as [w | v']; simpl in *.
        {
          eapply IHpairs; eauto.
        }
        destruct (weq k k') as [? | Hne]; subst.
        {
          eapply no_clash_ls_not_in_heap in Hnc.
          unfold not_in_heap in *.
          eapply IHpairs in Hk; eauto.
          contradict Hnc.
          eapply find_Some_in; eauto.
        }
        rewrite add_neq_o in * by eauto.
        eapply IHpairs in Hk; eauto.
      Qed.
      Lemma mapsto_make_heap'_iff pairs :
        disjoint_ptrs pairs ->
        forall k (v : ADTValue),
          List.In (k, ADT v) pairs <->
          find k (make_heap' pairs) = Some v.
      Proof.
        intros Hdisj k v; split; intros H.
        - eapply mapsto_make_heap'_intro; eauto.
        - eapply mapsto_make_heap'_elim; eauto.
      Qed.
      eapply mapsto_make_heap'_iff in Hk1; eauto.
      eapply Forall_forall in Hforall; eauto.
      unfold word_adt_match in *.
      simpl in *.
      eauto.
    Qed.

    Lemma forall_word_adt_match_good_scalars : forall h pairs, List.Forall (word_adt_match h) pairs -> List.Forall (@word_scalar_match ADTValue) pairs.
      intros.
      eapply Forall_weaken.
      2 : eassumption.
      intros.
      destruct x.
      unfold word_adt_match, Semantics.word_adt_match, word_scalar_match in *; simpl in *.
      destruct v; simpl in *; intuition.
    Qed.

    Import List.

    Require Import Bedrock.Platform.Cito.StringMap.
    Import StringMap.
    Require Import Bedrock.Platform.Cito.StringMapFacts.
    Import FMapNotations.

    Hint Extern 0 (_ == _) => reflexivity.

    Definition AxSafe spec args (st : State ADTValue) :=
      exists input,
        length input = length args /\
        st == make_map args input /\
        PreCond spec input.

    Arguments ADT {_} _ .
    Arguments SCA {_} _ .

    Definition get_output st2 (arg_input : string * Value ADTValue) : option ADTValue :=
      let (x, i) := arg_input in
      match i with 
          ADT _ =>
          match find x st2 with
              Some (ADT a) => Some a
            | _ => None
          end
        | SCA _ => None 
      end.
      
    (* st1 : pre-call state *)
    (* st2 : post-call state *)
    Definition AxRunsTo spec args rvar (st st' : State ADTValue) :=
      exists inputs ret,
        length inputs = length args /\
        st == make_map args inputs /\
        let outputs := List.map (get_output st') (combine args inputs) in
        let inputs_outputs := combine inputs outputs in
        PostCond spec inputs_outputs ret /\
        find rvar st' = Some ret /\
        no_adt_leak inputs args rvar st'.

    Definition op_refines_ax (ax_env : Env _) (op_spec : OperationalSpec) (ax_spec : AxiomaticSpec _) :=
      let args := ArgVars op_spec in
      let rvar := RetVar op_spec in
      let s := Body op_spec in
      (exists (is_ret_scalar : bool),
         forall in_out ret,
           PostCond ax_spec in_out ret -> 
           if is_ret_scalar then exists w, ret = SCA w
           else exists a : ADTValue, ret = ADT a) /\
      (forall ins,
         PreCond ax_spec ins ->
         length args = length ins) /\
      (forall st,
         AxSafe ax_spec args st ->
         Safe ax_env s st) /\
      forall st st',
        AxSafe ax_spec args st ->
        RunsTo ax_env s st st' ->
        AxRunsTo ax_spec args rvar st st'.

    Import StringMap.

    Definition ops_refines_axs ax_env (op_specs : StringMap.t OperationalSpec) (ax_specs : StringMap.t (AxiomaticSpec _)) :=
      forall x ax_spec,
        find x ax_specs = Some ax_spec ->
        exists op_spec,
          find x op_specs = Some op_spec /\
          op_refines_ax ax_env op_spec ax_spec.
    
    Require Import Bedrock.Platform.Cito.GLabelMap.
    Import GLabelMap.
    Require Import Bedrock.Platform.Cito.GLabelMapFacts.
    Import FMapNotations.

    Import DFModule.

    Arguments Operational {_} _ .
    Arguments Axiomatic {_} _ .

    (* the whole environment of callable functions with their specs, including 
         (1) functions defined in 'module' with op. specs
         (2) functions defined in 'module' with ax. specs given by 'exports'
         (3) imports of 'module'
     *)
    Definition get_env op_mod_name exports module := 
      map (fun (f : DFFun) => Operational f) (map_aug_mod_name op_mod_name (Funs (ADTValue := ADTValue) module)) + 
      map Axiomatic (map_aug_mod_name op_mod_name exports + 
                     Imports module).

    Require Import Bedrock.Platform.Cito.StringMap.
    Import StringMap.
    Require Import Bedrock.Platform.Cito.StringMapFacts.
    Import FMapNotations.

    Definition whole_env := get_env op_mod_name exports module.
    Hypothesis Hrefine : ops_refines_axs whole_env (map Core (Funs module)) exports.

    Import CompileDFacadeToCito.
    Lemma env_ok ax_cenv : 
      specs_env_agree (specs cito_module imports exports op_mod_name) ax_cenv ->
      cenv_impls_env ax_cenv whole_env.
    Proof.
      admit.
    Qed.

    Lemma Hewi_cmodule : exports_weakens_impl cito_module imports exports op_mod_name.
    Proof.
      unfold exports_weakens_impl.
      intros ax_cenv Hax_cenv.
      eapply strengthen_diff_intro.
      intros lbl ax Hfind.
      right.
      eapply map_aug_mod_name_elim in Hfind.
      destruct Hfind as [k [? Hfind] ].
      subst; simpl in *.
      eapply is_sub_domain_sound in exports_in_domain.
      unfold sub_domain in *.
      copy_as Hfind Hin.
      eapply find_Some_in in Hin.
      eapply exports_in_domain in Hin.
      eapply in_find_Some in Hin.
      destruct Hin as [f Hf].
      eexists.
      split.
      {
        eapply specs_op_intro.
        unfold cito_module.
        eapply find_DFModule_find_CModule.
        eauto.
      }
      simpl.
      destruct f; simpl in *.
      assert (Hrefines : op_refines_ax whole_env Core ax).
      {
        unfold ops_refines_axs in *.
        eapply Hrefine in Hfind.
        destruct Hfind as [op_spec [Hfind Hrefines] ].
        rewrite map_o in Hfind.
        rewrite Hf in Hfind.
        simpl in *.
        inject Hfind.
        eauto.
      }
      destruct Core; simpl in *.
      assert (Hnd : NoDup ArgVars) by (eapply is_no_dup_sound; eauto).
      unfold compile_func; simpl.
      unfold CompileModule.compile_func; simpl.
      unfold strengthen_op_ax; simpl.
      unfold strengthen_op_ax'; simpl.
      destruct ax; simpl in *.
      unfold op_refines_ax in Hrefines; simpl in *.
      destruct Hrefines as [ [is_ret_scalar Hirs] Hrefines].
      Import List.
      unfold TransitTo; simpl.
      Import Bool.
      Definition output_gen (is_ret_scalar : bool) h ret_w (w_input : W * Value ADTValue) :=
        let (w, input) := w_input in
        match input with
            SCA _ => None
          | ADT _ =>
            if negb is_ret_scalar && weqb w ret_w then
              None
            else                                      
              heap_sel h w
        end.
      Definition outputs_gen is_ret_scalar ret_w words inputs h :=
        map (output_gen is_ret_scalar h ret_w) (combine words inputs).
      Definition ret_a_gen (is_ret_scalar : bool) w h :=
        if is_ret_scalar then None else heap_sel h w.
      exists (outputs_gen is_ret_scalar); simpl in *.
      exists (ret_a_gen is_ret_scalar); simpl in *.
      repeat try_split.
      {
        unfold outputs_gen_ok.
        simpl.
        intros ret_w words inputs h Hpre Hlen.
        unfold outputs_gen.
        rewrite map_length.
        rewrite combine_length.
        rewrite Hlen.
        intuition.
      }
      {
        intros ins Hpre.
        eapply Hrefines.
        eauto.
      }
      Lemma TransitSafe_AxSafe vs h args inputs ax_spec :
        TransitSafe ax_spec (map (Locals.sel vs) args) inputs h ->
        AxSafe ax_spec args (make_map args inputs).
      Proof.
        intros Htsafe.
        unfold TransitSafe in Htsafe; simpl in *.
        destruct Htsafe as [Hlen [Hgi Hpre] ].
        unfold AxSafe.
        exists inputs.
        repeat try_split.
        {
          rewrite map_length in *.
          eauto.
        }
        {
          eauto.
        }
        eauto.
      Qed.
      {
        intros v inputs Htsafe.
        destruct v as [vs h]; simpl in *.
        copy_as Htsafe Haxsafe.
        eapply TransitSafe_AxSafe in Haxsafe.
        unfold TransitSafe in Htsafe; simpl in *.
        destruct Htsafe as [Hlen [Hgi Hpre] ].
        set (words_inputs := combine (map (Locals.sel vs) ArgVars) inputs) in *.
        set (h1 := make_heap words_inputs).
        copy_as Hgi Hgi'.
        destruct Hgi' as [Hforall Hdisj].
        eapply compile_safe.
        {
          eapply Hrefines; eauto.
        }
        {
          eauto.
        }
        {
          eapply not_find_in_iff.
          eapply make_map_not_in.
          intros Hin.
          copy_as args_name_ok Hgn.
          eapply forallb_forall in Hgn; eauto.
          intuition.
        }
        {
          instantiate (1 := h).
          instantiate (1 := h1).
          subst h1.
          eapply good_inputs_make_heap_submap; eauto.
        }
        {
          subst h1.
          instantiate (1 := vs).
          eapply make_map_make_heap_related with (ks := ArgVars) (pairs := words_inputs); simpl; eauto.
          {
            eapply forall_word_adt_match_good_scalars; eauto.
          }
          {
            subst words_inputs.
            rewrite map_fst_combine; eauto.
          }            
          {
            subst words_inputs.
            rewrite map_snd_combine; eauto.
          }            
        }
        {
          eapply env_ok; eauto.
        }
        { 
          eauto.
        }
        { 
          eauto.
        }
      }
      Lemma make_map_Equal_elim A :
        forall ks (vs vs' : list A),
          NoDup ks ->
          length vs = length ks ->
          length vs' = length ks ->
          make_map ks vs == make_map ks vs' ->
          vs = vs'.
      Proof.
        induction ks; destruct vs; destruct vs'; simpl; try solve [intros; intuition].
        intros Hnd Hlen Hlen' Heqv.
        inversion Hnd; subst.
        inject Hlen.
        inject Hlen'.
        rename a into k.
        f_equal.
        {
          unfold Equal in *.
          specialize (Heqv k).
          repeat rewrite add_eq_o in * by eauto.
          inject Heqv.
          eauto.
        }
        eapply IHks; eauto.
        unfold Equal in *.
        intros k'.
        destruct (string_dec k' k) as [? | Hne]; subst.
        {
          Import StringMap.
          Lemma make_map_find_None A k ks (vs : list A) :
            ~ List.In k ks ->
            find k (make_map ks vs) = None.
          Proof.
            intros H.
            eapply make_map_not_in in H.
            eapply not_find_in_iff; eauto.
          Qed.
          repeat rewrite make_map_find_None by eauto.
          eauto.
        }
        specialize (Heqv k').
        repeat rewrite add_neq_o in * by eauto.
        eauto.
      Qed.
      {
        intros [vs h] [vs' h'] Hrt inputs Htsafe.
        copy_as Htsafe Haxsafe.
        eapply TransitSafe_AxSafe in Haxsafe.
        unfold TransitSafe in *; simpl in *.
        destruct Htsafe as [Hlen [Hgi Hpre] ].
        set (words_inputs := combine (List.map (Locals.sel vs) ArgVars) inputs) in *.
        set (h1 := make_heap words_inputs).
        set (st := make_map ArgVars inputs) in *.
        copy_as Hgi Hgi'.
        destruct Hgi' as [Hforall Hdisj].
        unfold TransitTo; simpl in *.
        rewrite map_length in *.
        eapply compile_runsto with (h1 := h1) (s_st := st) in Hrt; simpl in *.
        {
          simpl in *.
          destruct Hrt as [s_st'[Hrt [Hhle [ Hselqv Hr] ] ] ].
          eapply Hrefines in Hrt; eauto.
          unfold AxRunsTo in Hrt.
          destruct Hrt as [inputs' [ret [Hlen' [Hinputs' [Hpost [Hret Hnl] ] ] ] ] ].
          eapply make_map_Equal_elim in Hinputs'; eauto.
          symmetry in Hinputs'.
          subst.
          simpl in *.
          set (retw := Locals.sel vs' RetVar) in *.
          assert (Hreteq : combine_ret retw (ret_a_gen is_ret_scalar retw h') = ret).
          {
            unfold related in Hr.
            unfold outputs_gen.
            unfold combine_ret.
            simpl in *.
            copy_as Hret Hret'.
            eapply Hr in Hret.
            unfold represent in Hret.
            destruct ret as [w | a]; simpl in *.
            {
              subst.
              unfold ret_a_gen; simpl.
              destruct is_ret_scalar; eauto.
              eapply Hirs in Hpost.
              openhyp; intuition.
            }
            destruct is_ret_scalar; simpl in *.
            {
              eapply Hirs in Hpost.
              openhyp; intuition.
            }
            Require Import Bedrock.Platform.Cito.WordMap.
            Import WordMap.
            Require Import Bedrock.Platform.Cito.WordMapFacts.
            Import FMapNotations.
            eapply find_mapsto_iff in Hret.
            eapply diff_mapsto_iff in Hret.
            destruct Hret as [Hret Hni].
            eapply find_mapsto_iff in Hret.
            unfold heap_sel.
            subst retw.
            rewrite Hret.
            eauto.
          }
          assert (Hrnia : ~ List.In RetVar ArgVars).
          {
            eapply negb_is_in_iff; eauto.
          }
          set (outputs := List.map (get_output s_st') (combine ArgVars inputs)) in *.
          set (words := List.map (Locals.sel vs) ArgVars) in *.
          set (words' := List.map (Locals.sel vs') ArgVars).
          assert (Hwords' : words' = words).
          {
            Lemma In_map_ext A B (f g : A -> B) : forall ls, (forall x, List.In x ls -> f x = g x) -> List.map f ls = List.map g ls.
            Proof.
              induction ls; simpl; intros Hfg; trivial.
              f_equal.
              {
                eapply Hfg.
                eauto.
              }
              eapply IHls.
              intuition.
            Qed.
            eapply In_map_ext.
            intros x Hin.
            symmetry.
            eapply Hselqv.
            {
              copy_as no_assign_to_args Hnata.
              eapply is_disjoint_iff in Hnata.
              intros Hin2.
              eapply Hnata; split; eauto.
              Import StringSetFacts.
              eapply of_list_spec; eauto.
            }
            {
              copy_as args_name_ok Hargsok.
              eapply forallb_forall in Hargsok; eauto.
            }
          }
          assert (Houtputs : outputs_gen is_ret_scalar retw words inputs h' = outputs).
          {
            Definition no_adt_leak' input argvars retvar st vs :=
              forall var (a : ADTValue),
                sel st var = Some (ADT a) ->
                (~ exists i x' ai, nth_error argvars i = Some x' /\ nth_error input i = Some (ADT ai) /\ Locals.sel vs x' = Locals.sel  vs var) \/
                var = retvar \/
                exists i (ai : ADTValue), nth_error argvars i = Some var /\
                                          nth_error input i = Some (ADT ai).

              Lemma outputs_gen_outputs :
                forall args inputs vs h h' st (is_ret_scalar : bool) rvar ret,
                  length inputs = length args ->
                  let words := List.map (Locals.sel vs) args in
                  let args_inputs := combine args inputs in
                  let outputs := List.map (get_output st) args_inputs in
                  related st (vs, h) ->
                  h <= h' ->
                  (forall k a, List.In (k, ADT a) args_inputs ->
                               find (Locals.sel vs k) h = None -> 
                               find (Locals.sel vs k) h' = None) ->
                  disjoint_ptrs (combine words inputs) ->
                  no_adt_leak' inputs args rvar st vs ->
                  StringMap.find rvar st = Some ret ->
                  (if is_ret_scalar then
                     (exists w, ret = SCA w)
                   else
                     (exists a, ret = ADT a)) ->
                  negb (is_in rvar args) = true ->
                  outputs_gen is_ret_scalar (Locals.sel vs rvar) words inputs h' = outputs.
              Proof.
                simpl.
                induction args; destruct inputs; simpl; try solve [intros; intuition].
                intros vs h h' st is_ret_scalar rvar ret.
                intros Hlen Hr Hle Hhh' Hdisj Hnl Hret Hirs Hrnin.
                simpl.
                rename a into k.
                inject Hlen.
                eapply disjoint_ptrs_cons_elim in Hdisj.
                destruct Hdisj as [Hnc Hdisj].
                unfold outputs_gen; simpl in *.
                f_equal.
                {
                  destruct v as [w | a]; eauto.
                  Import Option.
                  Definition dec_Some_ADT (x : option (Value ADTValue)) : (exists a, x = Some (ADT a)) \/ ((exists w, x = Some (SCA w)) \/ x = None).
                    destruct x as [v | ].
                    {
                      destruct v; eauto.
                    }
                    eauto.
                  Defined.
                  destruct (dec_Some_ADT (StringMap.find (elt:=TopSection.Value) k st)) as [ [a' Hfindk] | Hfindk].
                  {
                    rewrite Hfindk.
                    copy_as Hfindk Hfindk'.
                    eapply Hr in Hfindk; simpl in *.
                    eapply Hle in Hfindk.
                    unfold heap_sel.
                    rewrite Hfindk.
                    Notation boolcase := Sumbool.sumbool_of_bool.
                    destruct (boolcase (negb is_ret_scalar && weqb (Locals.sel vs k) (Locals.sel vs rvar))) as [Heq | Heq]; rewrite Heq in *; trivial.
                    eapply andb_true_iff in Heq.
                    destruct Heq as [Hirseq Hkr].
                    eapply negb_true_iff in Hirseq; subst.
                    unfold weqb in *.
                    eapply weqb_true_iff in Hkr.
                    destruct Hirs as [a'' Hirs]; subst.
                    assert (Hkreq : k = rvar).
                    {
                      eapply related_no_alias; eauto.
                    }
                    subst.
                    eapply negb_is_in_iff in Hrnin.
                    contradict Hrnin.
                    simpl; eauto.
                  }
                  assert (Hfindk' : match StringMap.find (elt:=TopSection.Value) k st with
                                      | Some (SCA _) => None
                                      | Some (ADT a0) => Some a0
                                      | None => None
                                    end = None).
                  {
                    destruct Hfindk as [ [w Hfindk] | Hfindk ]; rewrite Hfindk; eauto.
                  }
                  rewrite Hfindk'; clear Hfindk'.
                  destruct (boolcase (negb is_ret_scalar && weqb (Locals.sel vs k) (Locals.sel vs rvar))) as [Hcond | Hcond]; rewrite Hcond in *; trivial.
                  eapply andb_false_iff in Hcond.
                  eapply Hhh'; eauto.
                  destruct (option_dec (find (elt:=ADTValue) (Locals.sel vs k) h)) as [ [a' Heq] | Hne]; eauto.
                  copy_as Heq Heq'.
                  eapply Hr in Heq; simpl in *.
                  destruct Heq as [x [ [Hsel Hx] Hu] ].
                  destruct (string_dec x k) as [? | Hnex]; subst.
                  {
                    rewrite Hx in Hfindk.
                    openhyp; intuition.
                  }
                  copy_as Hx Hx'.
                  eapply Hnl in Hx.
                  destruct Hx as [Hx | [? | [i [ai [Hki Hai] ] ] ] ]; subst.
                  {
                    contradict Hx.
                    exists 0; simpl in *.
                    exists k; eexists; eauto.
                  }
                  {
                    rewrite Hret in Hx'.
                    inject Hx'.
                    destruct Hcond as [Hcond | Hcond].
                    {
                      eapply negb_false_iff in Hcond; subst.
                      openhyp; intuition.
                    }
                    eapply eq_true_false_abs in Hcond; try contradiction.
                    eapply weqb_true_iff; eauto.
                  }
                  destruct i as [ | i]; simpl in *.
                  {
                    inject Hki.
                    intuition.
                  }
                  unfold no_clash_ls, no_clash in Hnc; simpl in *.
                  Lemma Forall_forall_1 A P (ls : list A) : Forall P ls -> (forall x, List.In x ls -> P x).
                    intros; eapply Forall_forall; eauto.
                  Qed.
                  eapply Forall_forall_1 with (x := (Locals.sel vs x, ADT ai)) in Hnc; simpl in *.
                  {
                    intuition.
                  }
                  eapply nth_error_In.
                  eapply nth_error_combine; eauto.
                  erewrite map_nth_error; eauto.
                }
                unfold outputs_gen in *.
                eapply IHargs; eauto.
                Focus 2.
                {
                  eapply negb_is_in_iff.
                  eapply negb_is_in_iff in Hrnin.
                  intuition.
                }
                Unfocus.
                intros x a Hx.
                eapply Hnl in Hx.
                destruct Hx as [Hx | [Hx | Hx ] ].
                {
                  left.
                  intros Hex.
                  contradict Hx.
                  destruct Hex as [i Hex].
                  openhyp.
                  exists (S i); simpl.
                  repeat try_eexists; repeat try_split; eauto.
                }
                {
                  subst.
                  right; left; eauto.
                }
                destruct Hx as [i [ai [Hki Hvi] ] ].
                destruct i as [ | i ]; simpl in *.
                {
                  inject Hki.
                  inject Hvi.
                  left.
                  intros Hex.
                  destruct Hex as [i [x' [ai' [Hix' [Hiai' Heq] ] ] ] ].
                  unfold no_clash_ls, no_clash in Hnc; simpl in *.
                  eapply Forall_forall_1 with (x := (Locals.sel vs x', ADT ai')) in Hnc; simpl in *.
                  {
                    intuition.
                  }                    
                  eapply nth_error_In.
                  eapply nth_error_combine; eauto.
                  erewrite map_nth_error; eauto.
                }
                {
                  right; right.
                  repeat try_eexists; repeat try_split; eauto.
                }
              Qed.
              rewrite <- Hwords'.
              eapply outputs_gen_outputs; auto; eauto.
              {
                intros x v Hx.
                eapply find_mapsto_iff in Hx.
                eapply find_mapsto_iff.
                eapply diff_mapsto_iff in Hx.
                openhyp; eauto.
              }
              {
                intros x v Hin Hx.
                eapply None_not_Some in Hx.
                eapply None_not_Some.
                intros Hx'.
                contradict Hx.
                destruct Hx' as [v' Hx].
                exists v'.
                eapply find_mapsto_iff in Hx.
                eapply find_mapsto_iff.
                eapply diff_mapsto_iff.
                split; eauto.
                intro Hindiff.
                eapply In_MapsTo in Hindiff.
                destruct Hindiff as [v'' Hindiff].
                eapply diff_mapsto_iff in Hindiff.
                destruct Hindiff as [? Hnin].
                contradict Hnin.
                subst h1.
                rewrite make_heap_make_heap'; eauto.
                eapply find_Some_in.
                eapply mapsto_make_heap'_intro; eauto.
                eapply in_nth_error in Hin.
                destruct Hin as [i Hin].
                eapply nth_error_combine_elim in Hin.
                destruct Hin as [Hin1 Hin2].
                eapply nth_error_In with (n := i).
                eapply nth_error_combine; eauto.
                rewrite <- Hwords'.
                subst words'.
                erewrite map_nth_error; eauto.
              }
              {
                subst words'.
                rewrite Hwords'.
                eauto.
              }
              {
                intros x a Hx.
                eapply Hnl in Hx.
                destruct Hx as [? | [i [ai [Hxi Hai] ] ] ]; subst.
                {
                  right; left; eauto.
                }
                right; right.
                repeat try_eexists; repeat try_split; eauto.
              }
              {
                eapply Hirs; eauto.
              }
          }
          repeat try_split; eauto.
          {
            unfold outputs_gen.
            rewrite map_length in *.
            subst words.
            rewrite combine_length_eq; rewrite map_length in *; eauto.
          }
          {
            rewrite Hreteq.
            rewrite Houtputs.
            eauto.
          }
          {
            unfold separated.
            destruct (option_dec (ret_a_gen is_ret_scalar retw h')) as [ [a Heq] | ]; try solve [left; trivial].
            rewrite Heq in *.
            unfold combine_ret in *.
            subst.
            right.
            intros Hin.
            copy_as Hpost Hirs'.
            eapply Hirs in Hirs'.
            destruct is_ret_scalar; destruct Hirs' as [a' Hirs']; try discriminate.
            symmetry in Hirs'; inject Hirs'.
            eapply In_MapsTo in Hin.
            destruct Hin as [a' Hretw].
            eapply SemanticsFacts5.fold_fwd' in Hretw.
            copy_as Hret Hrvar.
            eapply Hr in Hrvar.
            unfold represent in *; simpl in *.
            copy_as Hrvar Hrvar'.
            eapply find_mapsto_iff in Hrvar.
            eapply diff_mapsto_iff in Hrvar.
            destruct Hrvar as [Hrvar Hnin].
            subst retw.
            set (retw := Locals.sel vs' RetVar) in *.
            set (outputs := List.map (get_output s_st') (combine ArgVars inputs)) in *.
            set (outputs' := outputs_gen false retw (List.map (Locals.sel vs) ArgVars) inputs h') in *.
            assert (Hlen1 : length words_inputs = length outputs).
            {
              subst words_inputs.
              subst outputs.
              rewrite combine_length_eq; repeat rewrite map_length; eauto.
              rewrite combine_length_eq; repeat rewrite map_length; eauto.
            }
            assert (Hlen2 : length words_inputs = length outputs').
            {
              rewrite Houtputs; eauto.
            }
            destruct Hretw as [ [Hretw Hnin'] | Hretw ].
            {
              destruct (option_dec (find retw h1)) as [ [a'' Hh1] | Hh1 ].
              {
                subst h1.
                rewrite make_heap_make_heap' in Hh1 by eauto.
                eapply mapsto_make_heap'_iff in Hh1; eauto.
                eapply in_nth_error in Hh1.
                destruct Hh1 as [i Hh1].
                copy_as Hh1 Hh1'.
                eapply length_eq_nth_error with (ls2 := outputs) in Hh1'; eauto.
                destruct Hh1' as [o Hh1'].
                eapply (Hnin' a'' o).
                Definition make_triple (w_input_output : (W * Value ADTValue) * option ADTValue) :=
                  let '((w, i), o) := w_input_output in
                  {| Word := w; ADTIn := i; ADTOut := o |}.
                Definition make_triples' words_inputs outputs := List.map make_triple (combine words_inputs outputs).
                Lemma make_triples_make_triples' :
                  forall words_inputs outputs,
                    length words_inputs = length outputs ->
                    make_triples words_inputs outputs = make_triples' words_inputs outputs.
                Proof.
                  induction words_inputs; destruct outputs; simpl; intros Hlen; try solve [intuition].
                  unfold make_triples'.
                  simpl.
                  destruct a as [w i]; simpl in *.
                  f_equal; eauto.
                Qed.
                rewrite Houtputs.
                rewrite make_triples_make_triples'; eauto.
                eapply nth_error_In with (n := i).
                unfold make_triples'.
                erewrite map_nth_error.
                {
                  instantiate (1 := ((retw, ADT a''), o)).
                  eauto.
                }
                eapply nth_error_combine; eauto.
              }
              contradict Hnin.
              eapply diff_in_iff.
              split.
              {
                eapply MapsTo_In; eauto.
              }
              eapply not_find_in_iff; eauto.
            }
            destruct Hretw as [a'' HH].
            rewrite make_triples_make_triples' in HH by eauto.
            unfold make_triples' in HH.
            eapply in_nth_error in HH.
            destruct HH as [i HH].
            eapply nth_error_map_elim in HH.
            destruct HH as [ [ [w' a'''] o' ] [HH Hinj] ].
            inject Hinj.
            eapply nth_error_combine_elim in HH.
            destruct HH as [HH1 HH].
            eapply nth_error_combine_elim in HH1.
            destruct HH1 as [HH1 HH2].
            eapply nth_error_map_elim in HH1.
            destruct HH1 as [x HH1].
            destruct HH1 as [HH1 HH3].
            rewrite <- HH3 in *.
            unfold outputs_gen in HH.
            eapply nth_error_map_elim in HH.
            destruct HH as [ [w v] [HH HH4] ].
            eapply nth_error_combine_elim in HH.
            destruct HH as [HH HH5].
            rewrite HH2 in HH5.
            inject HH5.
            eapply nth_error_map_elim in HH.
            destruct HH as [ x' [HH HH5] ].
            rewrite HH in HH1.
            inject HH1.
            unfold output_gen in HH4; simpl in *.
            unfold weqb in *.
            Lemma weqb_complete (x y : W) : x = y -> Word.weqb x y = true.
            Proof.
              intros; subst.
              eapply weqb_true_iff; eauto.
            Qed.
            rewrite weqb_complete in HH4; eauto.
            intuition.
          }
        }
      }
    Qed.

    Definition output_module : XCAP.module := 
      CM2.make_module cito_module imports exports ax_mod_name op_mod_name op_mod_name_ok.

    Definition output_module_ok : moduleOk output_module.
      refine (CM2.make_module_ok cito_module imports exports _ ax_mod_name op_mod_name op_mod_name_ok op_mod_name_not_in_imports name_neq _).
      {
        eapply exports_in_domain_cmodule.
      }
      {
        eapply Hewi_cmodule.
      }
    Defined.

    Notation compile_cito_to_bedrock := compile_to_bedrock.

    Definition output_module_impl := (compile_cito_to_bedrock gmodules imports).

    Open Scope bool_scope.

    Require Import Coq.Bool.Bool.

    Import MakeWrapperMake.LinkMake.
    Import MakeWrapperMake.LinkMake.LinkModuleImplsMake.

    Lemma import_module_names_good : 
      let imported_module_names := List.map (fun x => fst (fst x)) (GLabelMap.elements imports) in
      forallb Cito.NameDecoration.is_good_module_name imported_module_names = true.
    Proof.
      generalize module; clear.
      destruct module.
      eapply import_module_names_good.
    Qed.

    Theorem output_module_impl_ok : moduleOk output_module_impl.
    Proof.

      clear ax_mod_name name_neq.
      unfold output_module_impl.

      match goal with
        | |- moduleOk (compile_to_bedrock ?Modules ?Imports ) =>
          let H := fresh in
          assert (GoodToLink_bool Modules Imports = true);
            [ unfold GoodToLink_bool(*; simpl*) |
              eapply GoodToLink_bool_sound in H; openhyp; simpl in *; eapply result_ok; simpl in * ]
            ; eauto
      end.

      eapply andb_true_iff.
      split.
      eapply andb_true_iff.
      split.
      {
        reflexivity.
      }
      {
        eapply forallb_forall.
        intros x Hin.
        rename op_mod_name_not_in_imports into Himn.
        eapply forallb_forall in Himn.
        2 : solve [eapply Hin].
        destruct (in_dec string_dec x (List.map GName gmodules)); simpl in *; trivial.
        intuition.
        subst; simpl in *; intuition.
        eapply negb_true_iff in Himn.
        Definition is_string_eq := string_bool.
        Lemma is_string_eq_iff a b : is_string_eq a b = true <-> a = b.
          unfold is_string_eq, string_bool.
          destruct (string_dec a b); intuition.
        Qed.
        Require Import Bedrock.Platform.Cito.StringSetFacts.
        Lemma is_string_eq_iff_conv a b : is_string_eq a b = false <-> a <> b.
        Proof.
          etransitivity.
          { symmetry; eapply not_true_iff_false. }
          eapply iff_not_iff.
          eapply is_string_eq_iff.
        Qed.
        eapply is_string_eq_iff_conv in Himn.
        intuition.
      }
      {
        simpl in *.
        eapply import_module_names_good.
      }
    Qed.

  End TopSection.

  Require Import Bedrock.Platform.Facade.DFModule.
  Require Import Bedrock.Platform.Cito.StringMapFacts.
  Notation AxiomaticSpec := (@AxiomaticSpec ADTValue).

  Require Import CompileUnit2.
  
  Variable exports : StringMap.t AxiomaticSpec.
  (* input of the this compiler *)
  Variable compile_unit : CompileUnit exports.

  Definition module := module compile_unit.
  Definition exports_in_domain := exports_in_domain compile_unit.
  Definition ax_mod_name := ax_mod_name compile_unit.
  Definition op_mod_name := op_mod_name compile_unit.
  Definition op_mod_name_ok := op_mod_name_ok compile_unit.
  Definition op_mod_name_not_in_imports := op_mod_name_not_in_imports compile_unit.
  Definition name_neq := name_neq compile_unit.

  Notation imports := (Imports module).
  Definition output_module' := output_module exports module ax_mod_name op_mod_name op_mod_name_ok.
  Definition output_module_ok' : moduleOk output_module' :=
    output_module_ok exports module exports_in_domain ax_mod_name op_mod_name op_mod_name_ok op_mod_name_not_in_imports name_neq.
  Definition output_module_impl' := output_module_impl module op_mod_name op_mod_name_ok.
  Definition output_module_impl_ok' : moduleOk output_module_impl' :=
    output_module_impl_ok module op_mod_name op_mod_name_ok op_mod_name_not_in_imports.

  Require Import CompileOut2.
  Definition compile : CompileOut exports :=
    Build_CompileOut exports output_module_ok' output_module_impl_ok'.

  (* In case Bedrock's tactic 'link' doesn't work well with simpl and unfold. Isn't needed in my test case *)
  Module LinkUnfoldHelp.

    Import MakeWrapperMake.LinkMake.LinkModuleImplsMake.

    Arguments Imports /.
              Arguments Exports /.
              Arguments CompileModuleMake.mod_name /.
              Arguments impl_module_name /.
              Arguments GName /.
              Arguments append /.
              Arguments CompileModuleMake.imports /.
              Arguments LinkMake.StubsMake.StubMake.bimports_diff_bexports /.
              Arguments LinkMake.StubsMake.StubMake.bimports_diff_bexports /.
              Arguments diff_map /.
              Arguments GLabelMapFacts.diff_map /.
              Arguments List.filter /.
              Arguments LinkMake.StubsMake.StubMake.LinkSpecMake2.func_impl_export /.
              Arguments LinkMake.StubsMake.StubMake.LinkSpecMake2.impl_label /.
              Arguments LinkMake.StubsMake.StubMake.LinkSpecMake2.impl_label /.
              Arguments GName /.
              Arguments impl_module_name /.
              Arguments append /.
              Arguments IsGoodModule.FName /.
              Arguments CompileModuleMake.mod_name /.
              Arguments impl_module_name /.
              Arguments LinkMake.StubsMake.StubMake.bimports_diff_bexports /.
              Arguments LinkMake.StubsMake.StubMake.LinkSpecMake2.func_impl_export /.
              Arguments LinkMake.StubsMake.StubMake.LinkSpecMake2.impl_label /.
              Arguments impl_module_name /.
              Arguments CompileModuleMake.imports /.

              Ltac link_simp2 :=
                simpl Imports;
                simpl Exports;
                unfold CompileModuleMake.mod_name;
                unfold impl_module_name;
                simpl GName;
                simpl append;
                unfold CompileModuleMake.imports;
                unfold LinkMake.StubsMake.StubMake.bimports_diff_bexports, LinkMake.StubsMake.StubMake.bimports_diff_bexports;
                unfold diff_map, GLabelMapFacts.diff_map;
                simpl List.filter;
                unfold LinkMake.StubsMake.StubMake.LinkSpecMake2.func_impl_export, LinkMake.StubsMake.StubMake.LinkSpecMake2.func_impl_export;
                unfold LinkMake.StubsMake.StubMake.LinkSpecMake2.impl_label, LinkMake.StubsMake.StubMake.LinkSpecMake2.impl_label;
                simpl GName;
                unfold impl_module_name;
                simpl append;
                simpl IsGoodModule.FName;
                unfold CompileModuleMake.mod_name;
                unfold impl_module_name;
                unfold LinkMake.StubsMake.StubMake.bimports_diff_bexports;
                unfold LinkMake.StubsMake.StubMake.LinkSpecMake2.func_impl_export;
                unfold LinkMake.StubsMake.StubMake.LinkSpecMake2.impl_label;
                unfold impl_module_name;
                unfold CompileModuleMake.imports.

    Ltac link2 ok1 ok2 :=
      eapply linkOk; [ eapply ok1 | eapply ok2
                       | reflexivity
                       | link_simp2; link_simp; eauto ..
                     ].

  End LinkUnfoldHelp.

End Make.