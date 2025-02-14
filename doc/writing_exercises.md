# Writing exercises

This page deals in more details with the `Statement` command and all the options you have
to write better exercises/levels.

## Descriptive Text
You can write some text that would appear above the proof state in tactic mode:
```
/-- some descriptive text -/
Statement my_statement ...
```


## Local `let` definitions
If you want to make a local definition/notation which only holds for this exercise (e.g.
a function `f : ℤ → ℤ := fun x ↦ 2 * x`) the recommended way is to use a `let`-statement:

```lean
Statement (a : ℤ) (h : 0 < a) :
    let f : ℤ → ℤ := fun x ↦ 2 * x
    0 < f a := by
  sorry
```

The game automatically `intros` such `let`-statements, such that you and the player will see
the following initial proof state:

```
a: ℤ
h: 0 < a
f: ℤ → ℤ := fun x => 2 * x
⊢ 0 < f a
```

## "Preamble" & non-`Prop`-valued exercises

You can use the following syntax with `(preamble := tac)` where `tac` is a tactic sequence.

```
Statement my_statement (preamble := dsimp) (a : ℤ) (h : 0 < a) :
    0 < f a := by
  sorry
```

This tactic sequence will be executed before the exercise is handed to the player.

For example, if your exercise is to construct a structure, you could use `preamble` to fill
all data fields correctly, leaving all `Prop`-valued fields of the structure as separate goals
for the player to proof.

Note: `(preamble := tac)` always has to be written between the optional name and the first
hypothesis. Nevertheless, you can use all hypotheses in the tactic sequence, because it is
only evaluated at the beginning of the proof.

## Attributes

You can add attributes as you would for a `theorem`. Most notably, you can make your named exercise a `simp` lemma:

```lean
@[simp]
Statement my_simp_lemma ...
```

## Formatting

You can use markdown to format inside quotes like `Hint ""`.
Latex is also supported, see latex.md.

## Adding A Named Statement As A Theorem
This can be done like so:
```
Statement my_statement ...

NewTheorem my_statement
```
To be able to use `my_statement` in future levels, you would have to import the level where `my_statement` was introduced.
`my_statement` will be available to you even before finishing the level, but the game is smart enough to not allow you to use it to trivially solve the level. It's usable after the level but does appear as a theorem in your inventory.

You could also avoid using a named statement, and just make a normal `theorem` and use `NewTheorem` in the next level.
