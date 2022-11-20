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

    if DevilKeysMod.Data.HasOpenedDevilKeyDoor then
        familiarToCheck = nil
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

    player:CheckFamiliar(
        familiarToCheck,
        1,
        player:GetCollectibleRNG(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
    )
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


---@param wisp EntityFamiliar
function UpdateInvisibleWisp(wisp)
    wisp.Position = Vector(-1000, -1000)
end


---@param player EntityPlayer
function DevilKeyPieces:OnPlayerUpdate(player)
    local playerData = DevilKeysMod.GetPlayerData(player)

    local prevWispNumber = playerData.WispNumber
    local currentWispNumber = player:GetCollectibleNum(Constants.CollectibleType.DEVIL_KEY_PIECE_1) +
    player:GetCollectibleNum(Constants.CollectibleType.DEVIL_KEY_PIECE_2)

    if not prevWispNumber then
        playerData.WispNumber = currentWispNumber
        return
    end

    local wispsList = playerData.WispList

    if not wispsList then
        playerData.WispList = {}
        wispsList = playerData.WispList
    end

    if currentWispNumber > prevWispNumber then
        --Add wisp
        local wisp = player:AddWisp(CollectibleType.COLLECTIBLE_SATANIC_BIBLE, Vector(-1000, -1000), false, true)
        wisp:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        wisp:AddEntityFlags(EntityFlag.FLAG_NO_QUERY | EntityFlag.FLAG_NO_REWARD)
        wisp:RemoveFromOrbit()
        wisp.Visible = false
        wispsList[#wispsList+1] = wisp
    elseif currentWispNumber < prevWispNumber then
        --Remove wisp
        local lastWisp = wispsList[#wispsList]
        lastWisp:Remove()
        lastWisp:Kill()
        wispsList[#wispsList] = nil
    end

    playerData.WispNumber = currentWispNumber

    for _, wisp in ipairs(wispsList) do
        UpdateInvisibleWisp(wisp)
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, DevilKeyPieces.OnPlayerUpdate)


---@param tear EntityTear
function DevilKeyPieces:OnTearUpdate(tear)
    if tear.SpawnerType ~= EntityType.ENTITY_FAMILIAR or tear.SpawnerVariant ~= FamiliarVariant.WISP then return end
    local wisp = tear.SpawnerEntity:ToFamiliar()

    local playerData = DevilKeysMod.GetPlayerData(wisp.Player)

    if not playerData.WispList then return end

    local wispPtr = GetPtrHash(wisp)

    for _, otherWisp in ipairs(playerData.WispList) do
        local otherWispPtr = GetPtrHash(otherWisp)

        if wispPtr == otherWispPtr then
            tear:Remove()
            SFXManager():Stop(SoundEffect.SOUND_TEARS_FIRE)
            return
        end
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, DevilKeyPieces.OnTearUpdate)


function DevilKeyPieces:OnGameExit()
    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        local playerData = DevilKeysMod.GetPlayerData(player)

        if playerData.WispList then
            for _, wisp in ipairs(playerData.WispList) do
                wisp:Remove()
                wisp:Kill()
            end
        end

        if playerData.WispNumber then
            playerData.WispNumber = 0
        end
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DevilKeyPieces.OnGameExit)


---@param player EntityPlayer
function DevilKeyPieces:PreSacrificialAltarUse(_, _, player)
    local playerData = DevilKeysMod.GetPlayerData(player)

    local wispList = playerData.WispList

    if not wispList then return end

    for _, wisp in ipairs(wispList) do
        wisp:RemoveFromOrbit()
		wisp.Player = nil
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, DevilKeyPieces.PreSacrificialAltarUse)


---@param player EntityPlayer
function DevilKeyPieces:OnSacrificialAltarUse(_, _, player)
    local playerData = DevilKeysMod.GetPlayerData(player)

    local wispList = playerData.WispList

    if not wispList then return end

    for _, wisp in ipairs(wispList) do
        wisp:RemoveFromOrbit()
		wisp.Player = player
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_USE_ITEM, DevilKeyPieces.OnSacrificialAltarUse)