local FallenAngelFight = {}
local Helpers = require("devil_keys_scripts.Helpers")
local Constants = require("devil_keys_scripts.Constants")

local SpecialFallenAngels = {}


local function GetAngelToSpawn()
    local spawnedAngels = DevilKeysMod.Data.SpawnedAngels

    if not spawnedAngels then
        DevilKeysMod.Data.SpawnedAngels = {}
        spawnedAngels = DevilKeysMod.Data.SpawnedAngels
    end

    local chosen

    if not spawnedAngels[tostring(EntityType.ENTITY_URIEL)] then
        chosen = EntityType.ENTITY_URIEL
    elseif not spawnedAngels[tostring(EntityType.ENTITY_GABRIEL)] then
        chosen = EntityType.ENTITY_GABRIEL
    else
        local hasDevilKeyPiece1 = Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
        local hasDevilKeyPiece2 = Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_2)

        if hasDevilKeyPiece1 and not hasDevilKeyPiece2 then
            chosen = EntityType.ENTITY_GABRIEL
        elseif hasDevilKeyPiece2 and not hasDevilKeyPiece1 then
            chosen = EntityType.ENTITY_URIEL
        else
            local level = Game():GetLevel()
            local stage = level:GetStage()

            local rng = RNG()
            rng:SetSeed(Game():GetSeeds():GetStageSeed(stage), 35)

            if rng:RandomInt(2) == 1 then
                chosen = EntityType.ENTITY_URIEL
            else
                chosen = EntityType.ENTITY_GABRIEL
            end
        end
    end

    spawnedAngels[tostring(chosen)] = true

    return chosen
end


---@param gridEntity GridEntity
local function BreakDevilStatue(gridEntity)
    local position = Vector(gridEntity.Position.X, gridEntity.Position.Y)
    Helpers.RemoveGridEntity(gridEntity, true)

    --Spawn decorations so the statue doesn't spawn again
    Isaac.GridSpawn(GridEntityType.GRID_DECORATION, 0, position)

    local angelType = GetAngelToSpawn()

    --Fallen angel variant is 1
    local fallenAngel = Isaac.Spawn(angelType, 1, 0, position, Vector.Zero, nil)
    fallenAngel:Update()
    local entityPtr = GetPtrHash(fallenAngel)

    SpecialFallenAngels[entityPtr] = true

    local room = Game():GetRoom()
    room:SetClear(false)

    DevilKeysMod.Data.ModifyClearAward = true

    if MusicManager():GetCurrentMusicID() ~= Music.MUSIC_SATAN_BOSS then
        ---@diagnostic disable-next-line: param-type-mismatch
        MusicManager():Play(Music.MUSIC_SATAN_BOSS, Options.MusicVolume)
        MusicManager():UpdateVolume()
    end
end


---@param explosion EntityEffect
function FallenAngelFight:OnExplosionInit(explosion)
    if not DevilKeysMod.Data.IsAngelsUnlocked then return end

    local room = Game():GetRoom()

    ---@type GridEntity[]
    local statuesInRadius = {}

    for i = 0, room:GetGridSize(), 1 do
        local gridEntity = room:GetGridEntity(i)

        if gridEntity and
        gridEntity:GetType() == GridEntityType.GRID_STATUE and
        gridEntity:GetVariant() == 0 then --Devil statue is variant 0
            if gridEntity.Position:DistanceSquared(explosion.Position) <= 80^2 then
                table.insert(statuesInRadius, gridEntity)
            end
        end
    end

    if #statuesInRadius == 0 then return end

    for _, statue in ipairs(statuesInRadius) do
        BreakDevilStatue(statue)
    end

    for i = 0, DoorSlot.NUM_DOOR_SLOTS, 1 do
        local door = room:GetDoor(i)

        if door then
            door:Close(true)
        end
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, FallenAngelFight.OnExplosionInit, EffectVariant.BOMB_EXPLOSION)


---@param angel EntityNPC
---@return CollectibleType?
local function GetFallenAngelReward(angel)
    if Helpers.DoesAnyPlayerHaveTrinket(TrinketType.TRINKET_BLACK_FEATHER) then
        local itemPool = Game():GetItemPool()

        return itemPool:GetCollectible(ItemPoolType.POOL_DEVIL, true, angel.InitSeed, CollectibleType.COLLECTIBLE_NULL)
    else
        local keyToSpawn = Constants.AngelTypeToKeyPiece[angel.Type]

        if Helpers.DoesAnyPlayerHaveItem(keyToSpawn) then
            return nil
        else
            return keyToSpawn
        end
    end
end


---@param angel EntityNPC
function FallenAngelFight:OnFallenAngelDeath(angel)
    --Fallen angel variant is 1
    if angel.Variant ~= 1 then return end

    local entityPtr = GetPtrHash(angel)

    if not SpecialFallenAngels[entityPtr] then return end

    local itemToSpawn = GetFallenAngelReward(angel)
    if itemToSpawn then
        local itemReward = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemToSpawn, angel.Position, Vector.Zero, nil)
        itemReward = itemReward:ToPickup()

        local allPlayersKeeper = true
        for i = 0, Game():GetNumPlayers()-1, 1 do
            local player = Game():GetPlayer(i)

            if player:GetPlayerType() ~= PlayerType.PLAYER_KEEPER and
            player:GetPlayerType() ~= PlayerType.PLAYER_KEEPER_B then
                allPlayersKeeper = false
                break
            end
        end

        if not (DevilKeysMod.Config.DevilKeysPrice == 3 or
        (itemToSpawn == Constants.CollectibleType.DEVIL_KEY_PIECE_1 and
        DevilKeysMod.Config.DevilKeysPrice == 2)) then
            if allPlayersKeeper then
                itemReward.Price = 15

                if itemToSpawn == Constants.CollectibleType.DEVIL_KEY_PIECE_2 and
                DevilKeysMod.Config.DevilKeysPrice == 2 then
                    itemReward.Price = 30
                end
            else
                itemReward.Price = PickupPrice.PRICE_ONE_HEART

                if itemToSpawn == Constants.CollectibleType.DEVIL_KEY_PIECE_2 and
                DevilKeysMod.Config.DevilKeysPrice == 2 then
                    itemReward.Price = PickupPrice.PRICE_TWO_HEARTS

                    local noPlayerHasMoreThanOneHeart = true
                    for i = 0, Game():GetNumPlayers()-1, 1 do
                        local player = Game():GetPlayer(i)

                        local heartContainers = player:GetMaxHearts() * 2 + player:GetBoneHearts()

                        if heartContainers > 1 then
                            noPlayerHasMoreThanOneHeart = false
                            break
                        end
                    end
                    if noPlayerHasMoreThanOneHeart then
                        itemReward.Price = PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS
                    end
                end

                local noPlayerHasRedHearts = true
                for i = 0, Game():GetNumPlayers()-1, 1 do
                    local player = Game():GetPlayer(i)

                    local heartContainers = player:GetMaxHearts() * 2 + player:GetBoneHearts()

                    if heartContainers > 0 then
                        noPlayerHasRedHearts = false
                        break
                    end
                end
                if noPlayerHasRedHearts then
                    if itemReward.Price == PickupPrice.PRICE_ONE_HEART then
                        itemReward.Price = PickupPrice.PRICE_ONE_SOUL_HEART
                    else
                        itemReward.Price = PickupPrice.PRICE_TWO_SOUL_HEARTS
                    end
                end
            end

            itemReward.AutoUpdatePrice = false
        end
    end
    SpecialFallenAngels[entityPtr] = nil

    for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_GABRIEL, 1)) do
        local entityPtr = GetPtrHash(entity)

        if SpecialFallenAngels[entityPtr] then
            return
        end
    end

    for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_URIEL, 1)) do
        local entityPtr = GetPtrHash(entity)

        if SpecialFallenAngels[entityPtr] then
            return
        end
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    MusicManager():Play(Music.MUSIC_JINGLE_BOSS_OVER2, Options.MusicVolume)
    MusicManager():UpdateVolume()

    ---@diagnostic disable-next-line: param-type-mismatch
    MusicManager():Queue(Music.MUSIC_BOSS_OVER)
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, FallenAngelFight.OnFallenAngelDeath, EntityType.ENTITY_GABRIEL)
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, FallenAngelFight.OnFallenAngelDeath, EntityType.ENTITY_URIEL)


local function TryChangeDevilKeysPrices()
    local keys = Isaac.FindByType(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        Constants.CollectibleType.DEVIL_KEY_PIECE_1
    )

    local keys2 = Isaac.FindByType(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        Constants.CollectibleType.DEVIL_KEY_PIECE_2
    )

    for _, key in ipairs(keys2) do
        keys[#keys+1] = key
    end

    ---@type EntityPickup[]
    local keysWithPrice = {}

    for _, key in ipairs(keys) do
        local collectible = key:ToPickup()

        if collectible.Price < 0 and not collectible.AutoUpdatePrice then
            keysWithPrice[#keysWithPrice+1] = collectible
        end
    end

    local noPlayerHasRedHearts = true
    local noPlayerHasMoreThanOneHeart = true
    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        local heartContainers = player:GetMaxHearts() * 2 + player:GetBoneHearts()

        if heartContainers > 1 then
            noPlayerHasMoreThanOneHeart = false
            noPlayerHasRedHearts = false
            break
        elseif heartContainers > 0 then
            noPlayerHasRedHearts = false
            break
        end
    end

    for _, collectible in ipairs(keysWithPrice) do
        collectible.Price = PickupPrice.PRICE_ONE_HEART

        if collectible.SubType == Constants.CollectibleType.DEVIL_KEY_PIECE_2 and DevilKeysMod.Config.DevilKeysPrice == 2 then
            if noPlayerHasMoreThanOneHeart then
                collectible.Price = PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS
            else
                collectible.Price = PickupPrice.PRICE_TWO_HEARTS
            end
        end

        if noPlayerHasRedHearts then
            if collectible.Price == PickupPrice.PRICE_ONE_HEART then
                collectible.Price = PickupPrice.PRICE_ONE_SOUL_HEART
            else
                collectible.Price = PickupPrice.PRICE_TWO_SOUL_HEARTS
            end
        end
    end
end


---@param player EntityPlayer
function FallenAngelFight:OnPeffectUpdate(player)
    local playerData = DevilKeysMod.GetPlayerData(player)

    local prevPlayerType = playerData.prevPlayerType
    local currentPlayerType = player:GetPlayerType()

    if prevPlayerType == nil then
        prevPlayerType = currentPlayerType
    end

    if currentPlayerType == PlayerType.PLAYER_THEFORGOTTEN or
    currentPlayerType == PlayerType.PLAYER_THESOUL then
        if prevPlayerType ~= currentPlayerType then
            TryChangeDevilKeysPrices()
        end
    end

    playerData.prevPlayerType = currentPlayerType
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, FallenAngelFight.OnPeffectUpdate)


function FallenAngelFight:OnNewRoom()
    SpecialFallenAngels = {}
    DevilKeysMod.Data.ModifyClearAward = false
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, FallenAngelFight.OnNewRoom)


---@param rng RNG
---@param spawnPos Vector
function FallenAngelFight:PreClearAward(rng, spawnPos)
    if not DevilKeysMod.Data.ModifyClearAward then return end
    if not spawnPos then return end

    if rng:RandomInt(100) > 90 then return end

    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_REDCHEST, ChestSubType.CHEST_CLOSED, spawnPos, Vector.Zero, nil)

    return true
end
DevilKeysMod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, FallenAngelFight.PreClearAward)