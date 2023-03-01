import GameServer.Commands

-- Wird im Level "Implication 11" ohne Beweis angenommen.
LemmaDoc not_not as not_not in "Logic"
"
### Aussage

`¬¬A ↔ A`

### Annahmen

`(A : Prop)`
"

-- Wird im Level "Implication 10" ohne Beweis angenommen.
LemmaDoc not_or_of_imp as not_or_of_imp in "Logic"
"
### Aussage

`¬A ∨ B`

### Annahmen

`(A B : Prop)`\\
`(h : A → B)`
"

-- Wird im Level "Implication 12" bewiesen.
LemmaDoc imp_iff_not_or as imp_iff_not_or in "Logic"
"
### Aussage

`(A → B) ↔ ¬A ∨ B`

### Annahmen

`(A B : Prop)`
"


LemmaDoc Nat.succ_pos as Nat.succ_pos in "Nat"
"
"

LemmaDoc Nat.pos_iff_ne_zero as Nat.pos_iff_ne_zero in "Nat"
"
"

LemmaDoc zero_add as zero_add in "Addition"
"This lemma says `∀ a : ℕ, 0 + a = a`."

LemmaDoc add_zero as add_zero in "Addition"
"This lemma says `∀ a : ℕ, a + 0 = a`."

LemmaDoc add_succ as add_succ in "Addition"
"This lemma says `∀ a b : ℕ, a + succ b = succ (a + b)`."

LemmaDoc not_forall as not_forall in "Logic"
"`∀ (A : Prop), ¬(∀ x, A) ↔ ∃x, (¬A)`."

LemmaDoc not_exists as not_exists in "Logic"
"`∀ (A : Prop), ¬(∃ x, A) ↔ ∀x, (¬A)`."

LemmaDoc Even as Even in "Nat"
"
`even n` ist definiert als `∃ r, a = 2 * r`.
Die Definition kann man mit `unfold even at *` einsetzen.
"

LemmaDoc Odd as Odd in "Nat"
"
`odd n` ist definiert als `∃ r, a = 2 * r + 1`.
Die Definition kann man mit `unfold odd at *` einsetzen.
"

LemmaDoc not_odd as not_odd in "Nat"
"`¬ (odd n) ↔ even n`"

LemmaDoc not_even as not_even in "Nat"
"`¬ (even n) ↔ odd n`"

LemmaDoc even_square as even_square in "Nat"
"`∀ (n : ℕ), even n → even (n ^ 2)`"




LemmaDoc mem_univ as mem_univ in "Set"
"x ∈ @univ α"

LemmaDoc not_mem_empty as not_mem_empty in "Set"
""

LemmaDoc empty_subset as empty_subset in "Set"
""

LemmaDoc Subset.antisymm_iff as Subset.antisymm_iff in "Set"
""



LemmaDoc Nat.prime_def_lt'' as Nat.prime_def_lt'' in "Nat"
""


LemmaDoc Finset.sum_add_distrib as Finset.sum_add_distrib in "Sum"
""

LemmaDoc Fin.sum_univ_castSucc as Fin.sum_univ_castSucc in "Sum"
""

LemmaDoc Nat.succ_eq_add_one as Nat.succ_eq_add_one in "Sum"
""

LemmaDoc add_comm as add_comm in "Nat"
""

LemmaDoc mul_add as mul_add in "Nat"
""

LemmaDoc add_mul as add_mul in "Nat"
""

LemmaDoc arithmetic_sum as arithmetic_sum in "Sum"
""

LemmaDoc add_pow_two as add_pow_two in "Nat"
""
