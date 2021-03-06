Require Export FcEtt.tactics.
Require Export FcEtt.ett_inf.

Require Import FcEtt.utils.
Require Import FcEtt.imports.

Require Import FcEtt.ett_ind.
Require Import FcEtt.toplevel.

Set Bullet Behavior "Strict Subproofs".
Set Implicit Arguments.


(* --------------------------------------------------------------------------- *)
(* --------------------------------------------------------------------------- *)
(* --------------------------------------------------------------------------- *)

Ltac solve_binds :=
  match goal with
    | [ b : binds ?v _ ?G
      , H : forall v' _, binds v' _ ?G -> _ [<=] dom ?G ∧ _ [<=] dom ?G
      |- _ ] =>
      apply H in b; simpl in b; split_hyp; (done || fsetdec)
  end.


Import AtomSetImpl.

Lemma in_singleton_subset : forall x (G : context), x `in` dom G -> singleton x [<=] dom G.
Proof.
  unfold Subset.
  intros.
  apply singleton_1 in H0.
  subst.
  done.
Qed.

Hint Unfold AtomSetImpl.Subset.
Hint Resolve binds_In AtomSetImpl.singleton_1 in_singleton_subset.


(*
*)

Theorem context_fv_mutual :
  (forall G (a : tm) A (H: Typing G a A),
      fv_tm_tm_tm a [<=] dom G /\ fv_co_co_tm a [<=] dom G /\
      fv_tm_tm_tm A [<=] dom G /\ fv_co_co_tm A [<=] dom G)
  /\
  (forall G phi (H : PropWff G phi),
      fv_tm_tm_constraint phi [<=] dom G /\ fv_co_co_constraint phi [<=] dom G)
  /\
  (forall G D p1 p2 (H : Iso G D p1 p2),
      fv_tm_tm_constraint p1 [<=] dom G /\ fv_co_co_constraint p1 [<=] dom G /\
      fv_tm_tm_constraint p2 [<=] dom G /\ fv_co_co_constraint p2 [<=] dom G)
  /\
  (forall G D A B T (H : DefEq G D A B T),
      (fv_tm_tm_tm A [<=] dom G /\ fv_co_co_tm A [<=] dom G /\
      fv_tm_tm_tm B [<=] dom G /\ fv_co_co_tm B [<=] dom G /\
      fv_tm_tm_tm T [<=] dom G /\ fv_co_co_tm T [<=] dom G))

  /\
  (forall G (H : Ctx G),
      (forall x A,
          binds x (Tm A)   G ->
          fv_tm_tm_tm         A   [<=] dom G /\ fv_co_co_tm         A   [<=] dom G) /\
      (forall c phi,
          binds c (Co phi) G ->
          fv_tm_tm_constraint phi [<=] dom G /\ fv_co_co_constraint phi [<=] dom G)).

Proof.
  eapply typing_wff_iso_defeq_mutual.
  all: autounfold.

  (* We can't just use `repeat split` because we don't want to split under foralls *)
  all: intros; repeat match goal with |- _ ∧ _ => split end; split_hyp; simpl.
  all: eauto 1.
  (* split all asummptions about unions *)

  (* Do the cases about the context at the end. *)
  all: try (intros x0 A0 BI).
  all: try solve [inversion BI].
  all: try (match goal with |- _ ∧ _ => split end).


  all: try (intros y h1; inversion BI; [
              match goal with
                [ H5 : (_,_) = (_,_) |- _ ] =>
                inversion H5; subst; clear H5; eauto end|
              match goal with
                [ H5 : List.In (?x0, ?s ?a) ?G,
                  H : forall x A, binds x (?s A) ?G -> _ |- _ ] =>
                destruct (H x0 _ H5); eauto end]).

  (* rest of the cases *)
  all: intros y IN.

  (* more splitting, assumption has a union type *)
  all: try match goal with
    [ H7 : ?y `in` union ?A ?B |- _ ] =>
    apply F.union_iff in H7; destruct H7; eauto end.

  all: try solve [ apply notin_empty_1 in IN; contradiction].
  all: try solve [ assert (x = y) by auto; subst; eapply binds_In; eauto ].
  all: try solve [ destruct (H _ _ b); eauto ].

  all: try solve [apply H1; eauto; simpl; auto].
  all: try solve [apply H2; eauto; simpl; auto].
  all: try solve [apply H3; eauto; simpl; auto].
  all: try solve [apply H4; eauto; simpl; auto].


  all: try match goal with
    [ H5 : forall x : atom, (x `in` ?L -> False) -> ( _ /\ _ ) |- _ ] =>
    pick fresh x; destruct (H5 x); eauto; split_hyp
           end.

  all: try match goal with
    [ H4 : ?y `in` fv_tm_tm_tm ?B,
      H5 : ∀ a : atom,
       a `in` fv_tm_tm_tm (open_tm_wrt_tm ?B (a_Var_f ?x))
            → a `in` dom ([(?x, ?s)] ++ ?G) |- _ ] =>
    assert (h0: y `in` dom ([(x,s)] ++ G)) by
    (eapply H5; eauto;
    eapply fv_tm_tm_tm_open_tm_wrt_tm_lower; auto);
      simpl in h0; apply F.add_neq_iff in h0; auto
           end.
  all: try match goal with
    [ H4 : ?y `in` fv_co_co_tm ?B,
      H5 : ∀ a : atom,
       a `in` fv_co_co_tm (open_tm_wrt_tm ?B (a_Var_f ?x))
            → a `in` dom ([(?x, ?s)] ++ ?G) |- _ ] =>
    assert (h0: y `in` dom ([(x,s)] ++ G)) by
    (eapply H5; eauto;
    eapply fv_co_co_tm_open_tm_wrt_tm_lower; auto);
      simpl in h0; apply F.add_neq_iff in h0; auto
           end.
  all: try match goal with
    [ H4 : ?y `in` fv_tm_tm_tm ?B,
      H5 : ∀ a : atom,
       a `in` fv_tm_tm_tm (open_tm_wrt_co ?B (g_Var_f ?x))
            → a `in` dom ([(?x, ?s)] ++ ?G) |- _ ] =>
    assert (h0: y `in` dom ([(x,s)] ++ G)) by
    (eapply H5; eauto;
    eapply fv_tm_tm_tm_open_tm_wrt_co_lower; auto);
    simpl in h0; apply F.add_neq_iff in h0; auto
           end.
  all: try match goal with
    [ H4 : ?y `in` fv_co_co_tm ?B,
      H5 : ∀ a : atom,
       a `in` fv_co_co_tm (open_tm_wrt_co ?B (g_Var_f ?x))
            → a `in` dom ([(?x, ?s)] ++ ?G) |- _ ] =>
    assert (h0: y `in` dom ([(x,s)] ++ G)) by
    (eapply H5; eauto;
    eapply fv_co_co_tm_open_tm_wrt_co_lower; auto);
      simpl in h0; apply F.add_neq_iff in h0; auto
           end.

  all: try (simpl in *; eapply fv_tm_tm_tm_open_tm_wrt_tm_upper in IN;
    apply F.union_iff in IN; destruct IN; eauto).
  all: try (simpl in *; eapply fv_co_co_tm_open_tm_wrt_tm_upper in IN;
    apply F.union_iff in IN; destruct IN; eauto).
  all: try (simpl in *; eapply fv_tm_tm_tm_open_tm_wrt_co_upper in IN;
    apply F.union_iff in IN; destruct IN; eauto).
  all: try (simpl in *; eapply fv_co_co_tm_open_tm_wrt_co_upper in IN;
    apply F.union_iff in IN; destruct IN; eauto).

  all: try (apply H0 in IN; apply notin_empty_1 in IN; contradiction).
  all: try (apply H1 in IN; apply notin_empty_1 in IN; contradiction).

  all: try match goal with
    [ H7 : ?y `in` union ?A ?B |- _ ] =>
    apply F.union_iff in H7; destruct H7; eauto end.

  all: try (simpl in *; match goal with [ H : ?y `in` Metatheory.empty |- _ ] => apply notin_empty_1 in H; done end).

  all: try solve [destruct phi1; simpl in *; eauto].

  all: try solve [ simpl in *; eauto].

  (* all: try solve [ assert (c = y) by auto; subst; eapply binds_In; eauto ]. *)
  all: try solve [ destruct (H0 _ _ b0); simpl in *; eauto].

Qed.


Definition Typing_context_fv  := first context_fv_mutual.
Definition ProfWff_context_fv := second context_fv_mutual.
Definition Iso_context_fv     := third context_fv_mutual.
Definition DefEq_context_fv   := fourth context_fv_mutual.
