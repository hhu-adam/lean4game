import GameServer.RpcHandlers

open Lean

structure GameServerState :=
(env : Lean.Environment)
(game : Name)
(gameDir : String)
(inventory : Array String)
(difficulty : Nat)

abbrev GameServerM := StateT GameServerState Server.Watchdog.ServerM

instance : MonadEnv GameServerM := {
  getEnv := do return (← get).env
  modifyEnv := fun f => do
    let s ← get
    set {s with env := f s.env}
}

namespace Game
open Server
open Watchdog
open Lsp
open JsonRpc
open IO

structure DidOpenLevelParams where
  uri : String
  gameDir : String
  levelModule : Name
  tactics : Array InventoryTile
  lemmas : Array InventoryTile
  definitions : Array InventoryTile
  inventory : Array String
  /--
  Check for tactics/theorems that are not unlocked.
  0: no check
  1: give warnings
  2: give errors
  -/
  difficulty : Nat
  /-- The name of the theorem to be proven in this level. -/
  statementName : Name
  deriving ToJson, FromJson

structure SetInventoryParams where
  inventory : Array String
  difficulty : Nat
deriving ToJson, FromJson

def handleDidOpenLevel (params : Json) : GameServerM Unit := do
  let p ← parseParams _ params
  let m := p.textDocument
  -- Execute the regular handling of the `didOpen` event
  handleDidOpen p
  let fw ← findFileWorker! m.uri
  -- let s ← get
  let c ← read
  let some lvl ← GameServer.getLevelByFileName? c.initParams ((System.Uri.fileUriToPath? m.uri).getD m.uri |>.toString)
    | do
      c.hLog.putStr s!"Level not found: {m.uri} {c.initParams.rootUri?}"
      c.hLog.flush
  -- Send an extra notification to the file worker to inform it about the level data
  let s ← get
  fw.stdin.writeLspNotification {
    method := "$/game/didOpenLevel"
    param  := {
      uri := m.uri
      gameDir := s.gameDir
      levelModule := lvl.module
      tactics := lvl.tactics.tiles
      lemmas := lvl.lemmas.tiles
      definitions := lvl.definitions.tiles
      inventory := s.inventory
      difficulty := s.difficulty
      statementName := lvl.statementName
      : DidOpenLevelParams
    }
  }

partial def handleServerEvent (ev : ServerEvent) : GameServerM Bool := do
  match ev with
  | ServerEvent.clientMsg msg =>
    match msg with
    | Message.notification "$/game/setInventory" params =>
      let p := (← parseParams SetInventoryParams (toJson params))
      let s ← get
      set {s with inventory := p.inventory, difficulty := p.difficulty}
      let st ← read
      let workers ← st.fileWorkersRef.get
      for (_, fw) in workers do
        fw.stdin.writeLspMessage msg

      return true
    | Message.request id "loadInventoryOverview" _ =>
      let s ← get
      let some game ← getGame? s.game
        | return false

      let mut overview : Array WorldOverview := #[]
      for ⟨worldId, world⟩ in game.worlds.nodes.toList do
        let mut tactics : Array InventoryTile := #[]
        let mut theorems : Array InventoryTile := #[]
        let mut definitions : Array InventoryTile := #[]
        for ⟨_levelId, lvl⟩ in world.levels.toList do
          tactics := tactics ++ lvl.tactics.tiles.filterMap (fun tile => match tile.new with
            | true => some {tile with new := false, locked := true, disabled := false}
            | false => none)
          theorems := theorems ++ lvl.lemmas.tiles.filterMap (fun tile => match tile.new with
            | true => some {tile with new := false, locked := true, disabled := false}
            | false => none)
          definitions := definitions ++ lvl.definitions.tiles.filterMap (fun tile => match tile.new with
            | true => some {tile with new := false, locked := true, disabled := false}
            | false => none)
        overview := overview.push {
          world := worldId,
          tactics := tactics,
          lemmas := theorems,
          definitions := definitions }
      let c ← read
      c.hOut.writeLspResponse ⟨id, ToJson.toJson overview⟩
      return true
      -- -- All Levels have the same tiles, so we just load them from level 1 of an arbitrary world
      -- -- and reset `new`, `disabled` and `unlocked`.
      -- -- Note: as we allow worlds without any levels (for developing), we might need
      -- -- to try until we find the first world with levels.
      -- for ⟨worldId, _⟩ in game.worlds.nodes.toList do
      --   let some lvl ← getLevel? {game := s.game, world := worldId, level := 1}
      --     | do continue
      --   let inventory : InventoryOverview := {
      --     tactics := lvl.tactics.tiles.map
      --       ({ · with locked := true, disabled := false, new := false }),
      --     lemmas := lvl.lemmas.tiles.map
      --       ({ · with locked := true, disabled := false, new := false }),
      --     definitions := lvl.definitions.tiles.map
      --       ({ · with locked := true, disabled := false, new := false }),
      --     lemmaTab := none
      --   }
      --   let c ← read
      --   c.hOut.writeLspResponse ⟨id, ToJson.toJson inventory⟩
      --   return true
      -- return false
    | _ => return false
  | _ => return false

end Game
