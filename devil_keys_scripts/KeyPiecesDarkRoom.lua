local KeyPiecesDarkRoom = {}
local Helpers = require("devil_keys_scripts.Helpers")
local Constants = require("devil_keys_scripts.Constants")

local CHEST_PICKUP_VARIANTS = {
    PickupVariant.PICKUP_CHEST,
    PickupVariant.PICKUP_BOMBCHEST,
    PickupVariant.PICKUP_SPIKEDCHEST,
    PickupVariant.PICKUP_ETERNALCHEST,
    PickupVariant.PICKUP_MIMICCHEST,
    PickupVariant.PICKUP_OLDCHEST,
    PickupVariant.PICKUP_WOODENCHEST,
    PickupVariant.PICKUP_MEGACHEST,
    PickupVariant.PICKUP_HAUNTEDCHEST,
    PickupVariant.PICKUP_LOCKEDCHEST,
    PickupVariant.PICKUP_REDCHEST,
    PickupVariant.PICKUP_MOMSCHEST,
}


function TryReplaceChests()
    DevilKeysMod.Data.ReplaceChests = false

    local level = Game():GetLevel()
    local stageType = level:GetStageType()

    local newChestVariant

    if stageType == StageType.STAGETYPE_ORIGINAL then
        newChestVariant = PickupVariant.PICKUP_ETERNALCHEST
    elseif stageType ~= StageType.STAGETYPE_ORIGINAL then
        newChestVariant = PickupVariant.PICKUP_REDCHEST
    end

    if not newChestVariant then return end

    for _, chestVariant in ipairs(CHEST_PICKUP_VARIANTS) do
        for _, chest in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, chestVariant)) do
            chest:ToPickup():Morph(EntityType.ENTITY_PICKUP, newChestVariant, ChestSubType.CHEST_CLOSED)
        end
    end
end


---@return GridEntityDoor?
function FindMegaSatanDoor()
    local room = Game():GetRoom()

    for i = 0, DoorSlot.NUM_DOOR_SLOTS-1, 1 do
        local door = room:GetDoor(i)

        if door and door.TargetRoomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
            return door
        end
    end
end


---@param door GridEntityDoor
function ReplaceMegaSatanDoorSprite(door)
    local sprite = door:GetSprite()
    for layer = 0, sprite:GetLayerCount()-1, 1 do
        sprite:ReplaceSpritesheet(layer, "gfx/grid/mega_satan_door_devil_key.png")
    end
    sprite:LoadGraphics()
end


function RemoveRegularKeyPieces()
    local hasRemovedItem = false
    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        while player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) do
            hasRemovedItem = true
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1)
        end

        while player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2) do
            hasRemovedItem = true
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2)
        end
    end
    return hasRemovedItem
end


function RemoveDevilKeyPieces()
    local hasRemovedItem = false
    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        while player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1) do
            hasRemovedItem = true
            player:RemoveCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
        end

        while player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2) do
            hasRemovedItem = true
            player:RemoveCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2)
        end
    end

    return hasRemovedItem
end


function SpawnFullKeyForDevilKey()
    if Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_1) and
    Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_2) and
    not DevilKeysMod.Data.HasOpenedDevilKeyDoor then
        DevilKeysMod.Data.HasOpenedDevilKeyDoor = true

        for i = 0, Game():GetNumPlayers()-1, 1 do
            local player = Game():GetPlayer(i)
            player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            player:EvaluateItems()
        end

        local room = Game():GetRoom()
        local spawningPos = room:GetCenterPos()

        local fullDevilKey = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.KEY_FULL, 0, spawningPos, Vector.Zero, nil)

        fullDevilKey:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

        local sprite = fullDevilKey:GetSprite()
        sprite:ReplaceSpritesheet(0, "gfx/familiars/devil_key_pieces.png")
        sprite:LoadGraphics()
    end
end


function KeyPiecesDarkRoom:OnNewRoom()
    --Find mega satan door
    local megaSatanDoor = FindMegaSatanDoor()

    if not megaSatanDoor then return end

    if DevilKeysMod.Data.ReplaceChests then
        TryReplaceChests()
    end

    local level = Game():GetLevel()
    local stageType = level:GetStageType()
    local room = Game():GetRoom()

    if stageType == StageType.STAGETYPE_ORIGINAL then
        --We're in the dark room
        ReplaceMegaSatanDoorSprite(megaSatanDoor)
        SpawnFullKeyForDevilKey()

        local keyAnimFile = ""

        for _, keyPiece1 in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.KEY_PIECE_1)) do
            keyAnimFile = keyPiece1:GetSprite():GetFilename()
        end

        for _, keyPiece2 in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.KEY_PIECE_2)) do
            keyAnimFile = keyPiece2:GetSprite():GetFilename()
        end

        for _, fullKey in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.KEY_FULL)) do
            keyAnimFile = fullKey:GetSprite():GetFilename()
        end

        local hasRemovedItem = RemoveRegularKeyPieces()

        if hasRemovedItem then
            local specialLightBeam = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0, room:GetCenterPos(), Vector.Zero, nil)
            specialLightBeam:GetData().DontDealDamageToPlayers = true
            specialLightBeam:GetSprite():Play("SpotlightDelayed2", true)

            print(keyAnimFile)

            local fakeKey = Isaac.Spawn(EntityType.ENTITY_EFFECT, Constants.EffectVariant.FAKE_BREAKING_KEY, 0, room:GetCenterPos(), Vector.Zero, nil)
            fakeKey:GetSprite():Load(keyAnimFile, true)
            fakeKey:GetSprite():ReplaceSpritesheet(0, "gfx/characters/costumes/costume_rebirth_44_keysfloating.png")
            fakeKey:GetSprite():LoadGraphics()
            fakeKey:GetSprite():Play("Idle", true)
            specialLightBeam:GetData().FakeBreakingKey = fakeKey

            DevilKeysMod.Data.ReplaceChests = true
        end
    else
        --We're in the chest
        local keyAnimFile = ""

        for _, keyPiece1 in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Constants.FamiliarVariant.DEVIL_KEY_PIECE_1)) do
            keyAnimFile = keyPiece1:GetSprite():GetFilename()
        end

        for _, keyPiece2 in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Constants.FamiliarVariant.DEVIL_KEY_PIECE_2)) do
            keyAnimFile = keyPiece2:GetSprite():GetFilename()
        end

        for _, fullKey in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Constants.FamiliarVariant.DEVIL_KEY_PIECE_FULL)) do
            keyAnimFile = fullKey:GetSprite():GetFilename()
        end

        local hasRemovedItem = RemoveDevilKeyPieces()

        if hasRemovedItem then
            local bigHand = Isaac.Spawn(EntityType.ENTITY_EFFECT, Constants.EffectVariant.DEVIL_BIG_HAND, 0, room:GetCenterPos(), Vector.Zero, nil)
            bigHand:GetSprite():Play("SmallHoleOpen", true)

            local fakeKey = Isaac.Spawn(EntityType.ENTITY_EFFECT, Constants.EffectVariant.FAKE_BREAKING_KEY, 0, room:GetCenterPos() + Vector(0, -16), Vector.Zero, nil)
            fakeKey:GetSprite():Load(keyAnimFile, true)
            fakeKey:GetSprite():ReplaceSpritesheet(0, "gfx/familiars/devil_key_pieces.png")
            fakeKey:GetSprite():LoadGraphics()
            fakeKey:GetSprite():Play("Idle", true)
            fakeKey.DepthOffset = 30
            bigHand:GetData().FakeBreakingKey = fakeKey

            DevilKeysMod.Data.ReplaceChests = true
        end
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, KeyPiecesDarkRoom.OnNewRoom)


---@param effect EntityEffect
function KeyPiecesDarkRoom:OnCrackTheSkyUpdate(effect)
    if not effect:GetData().DontDealDamageToPlayers then return end

    local sprite = effect:GetSprite()

    if not sprite:IsPlaying("SpotlightDelayed2") then
        sprite:Play("SpotlightDelayed2", true)
    end

    if sprite:IsEventTriggered("Hit") then
        SFXManager():Play(SoundEffect.SOUND_SCYTHE_BREAK)
        Game():ShakeScreen(12)
        Game():Darken(1, 60)

        effect:GetData().FakeBreakingKey:Remove()

        for _ = 1, 7 + math.random(6), 1 do
            local velocity = Vector(math.random() * 4, 0):Rotated(math.random(360))

            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GOLD_PARTICLE, 0, effect.Position, velocity, nil)
        end

        TryReplaceChests()
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, KeyPiecesDarkRoom.OnCrackTheSkyUpdate, EffectVariant.CRACK_THE_SKY)


---@param source EntityRef
function KeyPiecesDarkRoom:OnEntityDamage(_, _, _, source)
    if source.Entity and source.Entity:GetData().DontDealDamageToPlayers then
        return false
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, KeyPiecesDarkRoom.OnEntityDamage)


---@param effect EntityEffect
function KeyPiecesDarkRoom:OnBigHandUpdate(effect)
    local sprite = effect:GetSprite()

    if sprite:IsFinished("SmallHoleOpen") then
        sprite:Play("HandGrab", true)
    elseif sprite:IsEventTriggered("Slam") then
        SFXManager():Play(SoundEffect.SOUND_SCYTHE_BREAK)
        Game():ShakeScreen(12)
        Game():Darken(1, 60)

        effect:GetData().FakeBreakingKey:Remove()

        for _ = 1, 7 + math.random(6), 1 do
            local velocity = Vector(math.random() * 4, 0):Rotated(math.random(360))

            local particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GOLD_PARTICLE, 0, effect.Position, velocity, nil)
            local color = Color(1, 0.2, 0.2, 1, 0, 0, 0)
            particle.Color = color
        end

        TryReplaceChests()
    elseif sprite:IsFinished("HandGrab") then
        sprite:Play("SmallHoleClose", true)
    elseif sprite:IsFinished("SmallHoleClose") then
        effect:Remove()
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, KeyPiecesDarkRoom.OnBigHandUpdate, Constants.EffectVariant.DEVIL_BIG_HAND)