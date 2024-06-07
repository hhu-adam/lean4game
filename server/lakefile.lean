import Lake
open Lake DSL

package GameServer

-- Using this assumes that each dependency has a tag of the form `v4.X.0`.
def leanVersion : String := s!"v{Lean.versionString}"

require batteries from git "https://github.com/leanprover-community/batteries.git" @ leanVersion
require i18n from git "https://github.com/hhu-adam/lean-i18n.git" @ leanVersion

require importGraph from git "https://github.com/leanprover-community/import-graph" @ leanVersion


lean_lib GameServer

@[default_target]
lean_exe gameserver {
  root := `GameServer
  supportInterpreter := true
}

/--
When a package depending on GameServer updates its dependencies,
build the `gameserver` executable.
-/
post_update pkg do
  let rootPkg ← getRootPackage
  if rootPkg.name = pkg.name then
    return -- do not run in GameServer itself
  discard <| runBuild gameserver.fetch
