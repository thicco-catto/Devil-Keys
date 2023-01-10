if not EID then return end

local Constants = require("devil_keys_scripts.Constants")

-- Devil Key Descriptions
local devilKeyEngDesc = "{{Warning}} Getting both parts of the key opens a big golden door in the dark room" ..
"#{{DevilChance}} 10% higher Devil Room chance" ..
"#{{BlackHeart}} +2% chance for Black Hearts"

EID:addCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1, devilKeyEngDesc, "Devil Key Piece 1")
EID:addCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2, devilKeyEngDesc, "Devil Key Piece 2")

local devilKeyEngDetailedDesc = "Combined with Devil Key Piece 2, this opens the golden door at the start of the Dark Room to fight Mega Satan." ..
"#Adds a 10% chance to spawn a Devil room." ..
"#Adds a 2% chance to replace any Red Heart with a Black Heart" ..
"#Cannot be rerolled by the D4, D100 or Dice Rooms."

EID:addCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1, devilKeyEngDetailedDesc, "Devil Key Piece 1", "en_us_detailed")
EID:addCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2, devilKeyEngDetailedDesc, "Devil Key Piece 2", "en_us_detailed")

local devilKeySpaDesc = "!!! ¡Pieza de llave para la puerta de Mega Satán en el Cuarto Oscuro!" ..
"#{{DevilRoom}} Aparecen más salas del Demonio" ..
"#{{BlackHeart}} +2% de probabilidad de reemplazar corazones rojos por corazones negros"

EID:addCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1, devilKeySpaDesc, "Trozo de Llave del Demonio 1", "spa")
EID:addCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2, devilKeySpaDesc, "Trozo de Llave del Demonio 2", "spa")

-- Angel Key Descriptions
local angelKeyEngDesc = "{{Warning}} Getting both parts of the key opens a big golden door in The Chest" ..
"#{{AngelChance}} 25% higher Angel Room chance" ..
"#{{EternalHeart}} +2% chance for Eternal Hearts"

EID:addCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1, angelKeyEngDesc, "Key Piece 1")
EID:addCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2, angelKeyEngDesc, "Key Piece 2")

local angelKeyDetailedEngDesc = "Combined with Key Piece 2, this opens the golden door at the start of The Chest to fight Mega Satan." ..
"#Adds a second 25% chance (independent of the first 50% chance) to spawn an Angel room instead of a Devil room. "..
"#Cannot be rerolled by the D4, D100 or Dice Rooms."

EID:addCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1, angelKeyDetailedEngDesc, "Key Piece 1", "en_us_detailed")
EID:addCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2, angelKeyDetailedEngDesc, "Key Piece 2", "en_us_detailed")

local angelKeySpaDesc = "!!! ¡Pieza de llave para la puerta de Mega Satán en El Cofre!" ..
"#Aparecen más salas del Ángel{{AngelRoom}}"

EID:addCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1, angelKeySpaDesc, "Key Piece 1", "spa")
EID:addCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2, angelKeySpaDesc, "Key Piece 2", "spa")


-- Polaroid descriptions
EID:addCollectible(
    CollectibleType.COLLECTIBLE_POLAROID,
    "Taking damage at half a Red Heart or none makes isaac temporarily invincible" ..
    "# {{ColorYellow}}Unlocks the angel's door{{CR}}",
    "The Polariod"
)

EID:addCollectible(
    CollectibleType.COLLECTIBLE_POLAROID,
    "Invencible cuando te golpean y estás a medio corazón" ..
    "# {{ColorYellow}}Desbloquea la puerta del angel{{CR}}",
    "La Polariod",
    "spa"
)

-- Negatice descriptions
EID:addCollectible(
    CollectibleType.COLLECTIBLE_NEGATIVE,
    "Taking damage at half a Red Heart or none damages all enemies in the room" ..
    "# {{ColorRed}}Unlocks the devil's door{{CR}}",
    "The Negative"
)

EID:addCollectible(
    CollectibleType.COLLECTIBLE_NEGATIVE,
    "Efecto de Necronomicón cuando te golpean y estás a medio corazón" ..
    "# {{ColorRed}}Desbloquea la puerta del demonio{{CR}}",
    "El negativo",
    "spa"
)

-- Sacrificial room descriptions
EID:addEntity(
    -999,
    -1,
    12,
    "",
    "# 50% chance to teleport to the \"Dark Room\" " ..
    "# The Mega Satan door will be unlockable with an angel key."
)

EID:addEntity(
    -999,
    -1,
    12,
    "",
    "# 50 % de probabilidad de teletransportar al Cuarto Oscuro." ..
    "# La puerta de Mega Satan podra ser abierta con la llave del angel.",
    "spa"
)
