# Setup for every lean file/level
In the example given in the template, `Metadata.lean` would contain the setup that is common to all files/levels and should be imported at the beginning of each lean file.

`Metadata.lean` can include `Mathlib`/`Lean` imports, `theorem`,`axiom`. 
Moreover, `Metadata.lean` can be divided up into multiple files with a similar setup where `Metadata.lean` would just import those. This can be used to organize and isolate related things. For example, one file would contain mathlib imports and another would contain theorems, axioms etc..

# Axioms
Having an axiom in `Metadata.lean`, it can be made available in the lean file by doing `open namespace` where `namespace` was where the axiom was declared. However, you would need to do `NewTheorem namespace.axiom` to be able to introduce it as a theorem.

## example
Say you have the following in `Metadata.lean`,
```
import Mathlib
namespace setup
axiom important_theorem : 2=2 
end setup
```

In the corresponding lean file for a level, you would have
```
...
-- allowing usage within the lean file
open setup

-- adding it to the game
NewTheorem setup.important_theorem
```
