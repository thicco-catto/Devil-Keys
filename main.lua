DevilKeysMod = RegisterMod("Devil Keys", 1)

DevilKeysMod.HiddenWisps = require("devil_keys_scripts.HiddenItemManager")
DevilKeysMod.HiddenWisps:Init(DevilKeysMod)

require("devil_keys_scripts.SaveData")(DevilKeysMod)

require("devil_keys_scripts.FallenAngelFight")
require("devil_keys_scripts.KeyPiecesDarkRoom")
require("devil_keys_scripts.DevilKeyPieces")
require("devil_keys_scripts.CheckAchievements")

require("devil_keys_scripts.DssMenu")
require("devil_keys_scripts.EIDCompat")