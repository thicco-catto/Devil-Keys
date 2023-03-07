local DevilKeyPieces = {}
local Helpers = require("devil_keys_scripts.Helpers")
local Constants = require("devil_keys_scripts.Constants")

local isCheckingOtherPlayersFamiliars = false

---@param player EntityPlayer
function DevilKeyPieces:OnFamiliarCache(player)
    local playerIndex = player:GetCollectibleRNG(1):GetSeed()

    if not isCheckingOtherPlayersFamiliars then
        isCheckingOtherPlayersFamiliars = true

        for i = 0, Game():GetNumPlayers()-1, 1 do
            local otherPlayer = Game():GetPlayer(i)
            local otherIndex = otherPlayer:GetCollectibleRNG(1):GetSeed()

            if otherIndex ~= playerIndex then
                otherPlayer:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
                otherPlayer:EvaluateItems()
            end
        end

        isCheckingOtherPlayersFamiliars = false
    end

    local familiarToCheck

    if Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_2) and
    player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1) then
        familiarToCheck = Constants.FamiliarVariant.DEVIL_KEY_PIECE_FULL
    elseif not Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_1) and
    player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2) then
        familiarToCheck = Constants.FamiliarVariant.DEVIL_KEY_PIECE_2
    elseif player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1) then
        familiarToCheck = Constants.FamiliarVariant.DEVIL_KEY_PIECE_1
    end

    for _, familiarVariant in pairs(Constants.FamiliarVariant) do
        if familiarVariant ~= familiarToCheck then
            player:CheckFamiliar(
                familiarVariant,
                0,
                player:GetCollectibleRNG(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
            )
        end
    end

    if not familiarToCheck then return end

    if DevilKeysMod.Data.SpawnFullNormalKey and
    familiarToCheck == Constants.FamiliarVariant.DEVIL_KEY_PIECE_FULL then
        DevilKeysMod.Data.HasSpawnedFullKey = true

        player:CheckFamiliar(
            Constants.FamiliarVariant.DEVIL_KEY_PIECE_FULL,
            0,
            player:GetCollectibleRNG(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
        )

        player:CheckFamiliar(
            FamiliarVariant.KEY_FULL,
            1,
            player:GetCollectibleRNG(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
        )
    else
        player:CheckFamiliar(
            familiarToCheck,
            1,
            player:GetCollectibleRNG(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
        )
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, DevilKeyPieces.OnFamiliarCache, CacheFlag.CACHE_FAMILIARS)


---@param familiar EntityFamiliar
function DevilKeyPieces:OnDevilKeyPieceInit(familiar)
    familiar:AddToFollowers()

    familiar:GetSprite():Play("Float", true)
end
DevilKeysMod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, DevilKeyPieces.OnDevilKeyPieceInit, Constants.FamiliarVariant.DEVIL_KEY_PIECE_1)
DevilKeysMod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, DevilKeyPieces.OnDevilKeyPieceInit, Constants.FamiliarVariant.DEVIL_KEY_PIECE_2)
DevilKeysMod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, DevilKeyPieces.OnDevilKeyPieceInit, Constants.FamiliarVariant.DEVIL_KEY_PIECE_FULL)


---@param familiar EntityFamiliar
function DevilKeyPieces:OnDevilKeyPieceUpdate(familiar)
    familiar:FollowParent()
end
DevilKeysMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DevilKeyPieces.OnDevilKeyPieceUpdate, Constants.FamiliarVariant.DEVIL_KEY_PIECE_1)
DevilKeysMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DevilKeyPieces.OnDevilKeyPieceUpdate, Constants.FamiliarVariant.DEVIL_KEY_PIECE_2)
DevilKeysMod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DevilKeyPieces.OnDevilKeyPieceUpdate, Constants.FamiliarVariant.DEVIL_KEY_PIECE_FULL)


---@param player EntityPlayer
function DevilKeyPieces:OnPlayerUpdate(player)
    --Found soul doesnt get the key
    if player.Variant == 1 then return end

    local playerData = DevilKeysMod.GetPlayerData(player)

    if player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2) and
    not playerData.HasSpawnedSpecialTrinket then
        playerData.HasSpawnedSpecialTrinket = true

        local room = Game():GetRoom()
        local spawningPos = room:FindFreePickupSpawnPosition(player.Position, 1, true)

        local trinketToSpawn = TrinketType.TRINKET_BLACK_FEATHER

        if (DevilKeysMod.Config.TrinketToSpawn == 1 and DevilKeysMod.Data.IsNumberMagnetUnlocked) or
        DevilKeysMod.Config.TrinketToSpawn == 3 then
            trinketToSpawn = TrinketType.TRINKET_NUMBER_MAGNET
        end

        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinketToSpawn, spawningPos, Vector.Zero, nil)
    end

    local targetWispCount = 0
    if player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1) then
        targetWispCount = targetWispCount + 1
    end
    if player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2) then
        targetWispCount = targetWispCount + 1
    end

    DevilKeysMod.HiddenWisps:CheckStack(player, CollectibleType.COLLECTIBLE_SATANIC_BIBLE, targetWispCount)
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, DevilKeyPieces.OnPlayerUpdate)


---@param heart EntityPickup
function DevilKeyPieces:OnRedHeartInit(heart)
    if heart.SubType ~= HeartSubType.HEART_DOUBLEPACK and
    heart.SubType ~= HeartSubType.HEART_FULL and
    heart.SubType ~= HeartSubType.HEART_HALF and
    heart.SubType ~= HeartSubType.HEART_SCARED then return end

    local chance = 0

    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        if player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1) then
            chance = chance + 25
        end
    end

    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        if player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2) then
            chance = chance + 25
        end
    end

    local rng = RNG()
    rng:SetSeed(heart.InitSeed, 35)

    if rng:RandomInt(1000) < chance then
        heart:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, true)
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, DevilKeyPieces.OnRedHeartInit, PickupVariant.PICKUP_HEART)


---@param itemsToTransform EntityPickup[]
---@param itemToTransformInto CollectibleType
local function TransformItemsIntoAnother(itemsToTransform, itemToTransformInto)
    for _, entity in ipairs(itemsToTransform) do
        local collectible = entity:ToPickup()

        collectible:Morph(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_COLLECTIBLE,
            itemToTransformInto,
            true
        )

        Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.POOF01,
            0,
            collectible.Position,
            Vector.Zero,
            nil
        )
    end
end


function DevilKeyPieces:OnFlipUse()
    local keyPieces1 = Isaac.FindByType(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        Constants.CollectibleType.DEVIL_KEY_PIECE_1
    )

    local keyPieces2 = Isaac.FindByType(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        Constants.CollectibleType.DEVIL_KEY_PIECE_2
    )

    TransformItemsIntoAnother(keyPieces1, Constants.CollectibleType.DEVIL_KEY_PIECE_2)
    TransformItemsIntoAnother(keyPieces2, Constants.CollectibleType.DEVIL_KEY_PIECE_1)
end
DevilKeysMod:AddCallback(ModCallbacks.MC_USE_ITEM, DevilKeyPieces.OnFlipUse, CollectibleType.COLLECTIBLE_FLIP)


local KEY_TYPE_PER_COLLECTIBLE_TYPE = {
    [CollectibleType.COLLECTIBLE_POLAROID] = {
        CollectibleType.COLLECTIBLE_KEY_PIECE_1,
        CollectibleType.COLLECTIBLE_KEY_PIECE_2
    },

    [CollectibleType.COLLECTIBLE_NEGATIVE] = {
        Constants.CollectibleType.DEVIL_KEY_PIECE_1,
        Constants.CollectibleType.DEVIL_KEY_PIECE_2
    }
}

---@param collectible EntityPickup
function DevilKeyPieces:OnCollectibleUpdate(collectible)
    local level = Game():GetLevel()
    local curses = level:GetCurses()

    if curses & LevelCurse.CURSE_OF_BLIND ~= 0 then return end

    local collectiblesToShine = KEY_TYPE_PER_COLLECTIBLE_TYPE[collectible.SubType]

    if not collectiblesToShine then return end

    local atLeastOnePlayerWithKey = false

    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)
        local hasItem = false

        for _, collectibleToShine in ipairs(collectiblesToShine) do
            if player:HasCollectible(collectibleToShine) then
                hasItem = true
                break
            end
        end

        if hasItem then
            atLeastOnePlayerWithKey = true
            break
        end
    end

    if not atLeastOnePlayerWithKey then return end

    local colorAmount = 1 + math.abs(math.sin(collectible.FrameCount * 0.1) * 0.6)
    local newColor = Color(colorAmount, colorAmount, colorAmount)

    collectible.Color = newColor
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, DevilKeyPieces.OnCollectibleUpdate, PickupVariant.PICKUP_COLLECTIBLE)