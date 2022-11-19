local KeyPiecesDarkRoom = {}
local Helpers = require("devil_keys_scripts.Helpers")
local Constants = require("devil_keys_scripts.Constants")


function TryReplaceChests()
    local room = Game():GetRoom()

    if not room:IsFirstVisit() then return end

    local level = Game():GetLevel()
    local stageType = level:GetStageType()

    local newChestVariant

    if stageType == StageType.STAGETYPE_ORIGINAL and
    Helpers.DoesAnyPlayerHaveItem(CollectibleType.COLLECTIBLE_KEY_PIECE_1) and
    Helpers.DoesAnyPlayerHaveItem(CollectibleType.COLLECTIBLE_KEY_PIECE_2) then
        newChestVariant = PickupVariant.PICKUP_ETERNALCHEST
    elseif stageType ~= StageType.STAGETYPE_ORIGINAL and
    Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_1) and
    Helpers.DoesAnyPlayerHaveItem(Constants.CollectibleType.DEVIL_KEY_PIECE_2) then
        newChestVariant = PickupVariant.PICKUP_REDCHEST
    end

    if not newChestVariant then return end

    for _, chest in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LOCKEDCHEST)) do
       chest:ToPickup():Morph(EntityType.ENTITY_PICKUP, newChestVariant, ChestSubType.CHEST_CLOSED)
    end

    for _, chest in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_REDCHEST)) do
        chest:ToPickup():Morph(EntityType.ENTITY_PICKUP, newChestVariant, ChestSubType.CHEST_CLOSED)
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
    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        while player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) do
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1)
        end

        while player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2) do
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2)
        end
    end
end


function RemoveDevilKeyPieces(spawnBreakEffect)
    if spawnBreakEffect then
        --Find keys and spawn the breaking effect
    end

    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        while player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1) do
            player:RemoveCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_1)
        end

        while player:HasCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2) do
            player:RemoveCollectible(Constants.CollectibleType.DEVIL_KEY_PIECE_2)
        end
    end
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

    TryReplaceChests()

    local level = Game():GetLevel()
    local stageType = level:GetStageType()

    if stageType == StageType.STAGETYPE_ORIGINAL then
        --We're in the dark room
        ReplaceMegaSatanDoorSprite(megaSatanDoor)

        RemoveRegularKeyPieces()

        SpawnFullKeyForDevilKey()
    else
        --We're in the chest
        RemoveDevilKeyPieces(true)
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, KeyPiecesDarkRoom.OnNewRoom)