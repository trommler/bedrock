Require Import List.

Section ListLexOrder.
  Variable T : Type.
  Variable cmp : T -> T -> comparison.

  Fixpoint list_lex_cmp (ls rs : list T) : comparison :=
    match ls , rs with
      | nil , nil => Eq
      | nil , _ => Lt
      | _ , nil => Gt
      | l :: ls , r :: rs =>
        match cmp l r with
          | Eq => list_lex_cmp ls rs
          | x => x
        end
    end.
End ListLexOrder.

Section Sorting.
  Variable T : Type.
  Variable cmp : T -> T -> comparison.

  Section insert. 
    Variable val : T.

    Fixpoint insert_in_order (ls : list T) : list T :=
      match ls with
        | nil => val :: nil
        | l :: ls' =>
          match cmp val l with
            | Gt => l :: insert_in_order ls' 
            | _ => val :: ls 
          end
      end.
  End insert.

  Fixpoint sort (ls : list T) : list T :=
    match ls with
      | nil => nil 
      | l :: ls => 
        insert_in_order l (sort ls)
    end.

End Sorting.
