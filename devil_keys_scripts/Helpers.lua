local Helpers = {}


--- Helper function to get a map containing the positions of every entity in the current room.
--- @param entities Entity[] @Optional. If provided, will only get the positions of the given entities, instead of calling `Isaac.GetRoomEntities`.
--- @return table<EntityPtr, Vector>
function Helpers.GetEntityPositions(entities)
    if entities == nil then
        entities = Isaac.GetRoomEntities()
    end

    local entityPositions = {}

    for _, entity in ipairs(entities) do
        local ptr = EntityPtr(entity)
        entityPositions[ptr] = entity.Position
    end

    return entityPositions
end


--- Helper function to get a map containing the velocities of every entity in the current room.
--- @param entities Entity[] @Optional. If provided, will only get the velocities of the given entities, instead of calling `Isaac.GetRoomEntities`.
--- @return table<EntityPtr, Vector>
function Helpers.GetEntityVelocities(entities)
    if entities == nil then
        entities = Isaac.GetRoomEntities()
    end

    local entityPositions = {}

    for _, entity in ipairs(entities) do
        local ptr = EntityPtr(entity)
        entityPositions[ptr] = entity.Velocity
    end

    return entityPositions
end


--- Helper function to set the positions of all the entities in the room.
--- 
--- Useful for rewinding entity positions.
--- @param positions table<EntityPtr, Vector>
--- @param entities Entity[] @Optional If provided, will only set the positions of the given entities, instead of calling `Isaac.GetRoomEntities`.
function Helpers.SetEntityPositions(positions, entities)
    if entities == nil then
        entities = Isaac.GetRoomEntities()
    end

    for _, entity in ipairs(entities) do
        local ptr = EntityPtr(entity)
        local position = positions[ptr]

        if position then
            entity.Position = position
        end
    end
end


--- Helper function to set the velocities of all the entities in the room.
--- 
--- Useful for rewinding entity velocities.
--- @param velocities table<EntityPtr, Vector>
--- @param entities Entity[] @Optional If provided, will only set the velocities of the given entities, instead of calling `Isaac.GetRoomEntities`.
function Helpers.SetEntityVelocities(velocities, entities)
    if entities == nil then
        entities = Isaac.GetRoomEntities()
    end

    for _, entity in ipairs(entities) do
        local ptr = EntityPtr(entity)
        local velocity = velocities[ptr]

        if velocity then
            entity.Velocity = velocity
        end
    end
end


--- Helper function to trigger a room update without affecting entity positions or velocities.
function Helpers.UpdateRoom()
    local room = Game():GetRoom()
    local entities = Isaac.GetRoomEntities()

    local positions = Helpers.GetEntityPositions(entities)
    local velocities = Helpers.GetEntityVelocities(entities)

    room:Update()

    Helpers.SetEntityPositions(positions, entities)
    Helpers.SetEntityVelocities(velocities, entities)
end


--- Helper function to remove a grid entity by providing the GridEntity or the grid index.
---
--- If removing a Devil or Angel Statue it'll also remove the associated effect.
--- @param gridEntityOrGridIndex GridEntity | integer
--- @param updateRoom boolean Whether or not to update the room after the grid entity is removed. If not, you won't be able to place another one until next frame. However doing so is expensive, so set this to false if you need to run this multiple times.
function Helpers.RemoveGridEntity(gridEntityOrGridIndex, updateRoom)
    local room = Game():GetRoom()

    ---@type GridEntity
    local gridEntity

    if type(gridEntityOrGridIndex) == "number" then
        gridEntity = room:GetGridEntity(gridEntityOrGridIndex)

        if not gridEntity then
            error("Couldn't find a grid entity at the given grid index: " .. gridEntityOrGridIndex)
        end
    else
        ---@cast gridEntityOrGridIndex GridEntity
        gridEntity = gridEntityOrGridIndex
    end

    local gridEntityType = gridEntity:GetType()
    local gridEntityVariant = gridEntity:GetVariant()
    local gridEntityPosition = gridEntity.Position

    room:RemoveGridEntity(gridEntity:GetGridIndex(), 0, false)

    if updateRoom then
        Helpers.UpdateRoom()
    end

    --Remove statue decoration
    if gridEntityType == GridEntityType.GRID_STATUE then
        local effectVariant = EffectVariant.DEVIL

        if gridEntityVariant == 1 then
            effectVariant = EffectVariant.ANGEL
        end

        local effects = Isaac.FindByType(EntityType.ENTITY_EFFECT, effectVariant)

        table.sort(effects, function (a, b)
            return a.Position:DistanceSquared(gridEntityPosition) <= b.Position:DistanceSquared(gridEntityPosition)
        end)

        effects[1]:Remove()
    end
end


---@param trinketType TrinketType
---@return boolean
function Helpers.DoesAnyPlayerHaveTrinket(trinketType)
    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        if player:HasTrinket(trinketType) then
            return true
        end
    end

    return false
end


---@param itemType CollectibleType
---@return boolean
function Helpers.DoesAnyPlayerHaveItem(itemType)
    for i = 0, Game():GetNumPlayers()-1, 1 do
        local player = Game():GetPlayer(i)

        if player:HasCollectible(itemType) then
            return true
        end
    end

    return false
end


--- Returns a list of all players.
--- @param ignoreCoopBabies? boolean @default: true
--- @return EntityPlayer[]
function Helpers.GetPlayers(ignoreCoopBabies)
	if ignoreCoopBabies == nil then
		ignoreCoopBabies = true
	end

	local players = {}

	for i = 0, Game():GetNumPlayers() - 1, 1 do
		local player = Game():GetPlayer(i)

		if not ignoreCoopBabies or player.Variant ~= 1 then
			table.insert(players, player)
		end
	end

	return players
end


---@class PlayerIndex : number

--- Returns a given player's index. Useful for storing unique data per player.
--- @param player EntityPlayer
--- @return PlayerIndex
function Helpers.GetPlayerIndex(player)
	---@diagnostic disable-next-line: return-type-mismatch
	return player:GetCollectibleRNG(1):GetSeed()
end


--- Returns all the players of a given type.
---@param playerType PlayerType
---@return EntityPlayer[]
function Helpers.GetPlayersOfType(playerType)
	local players = Helpers.GetPlayers()

    local playersOfType = {}
    for _, player in ipairs(players) do
        if player:GetPlayerType() == playerType then
            playersOfType[#playersOfType+1] = player
        end
    end

    return playersOfType
end


---Helper function to check if a collectible type has a given flag
---@param collectibleType CollectibleType
---@param flag integer
---@return boolean
function Helpers.CollectibleHasFlag(collectibleType, flag)
    local itemConfig = Isaac.GetItemConfig()
    local itemConfigItem = itemConfig:GetCollectible(collectibleType)
    return itemConfigItem.Tags & flag ~= 0
end


--- Returns a list with all items currently loaded.
---
--- Use only inside a callback or not all modded items may be loaded.
--- @return ItemConfig_Item[]
function Helpers.GetCollectibles()
	local collectibles = {}

	local itemConfig = Isaac.GetItemConfig()
	local itemList = itemConfig:GetCollectibles()

	--itemList.Size actually returns the last item id, not the actual size
	for id = 1, itemList.Size - 1, 1 do
		local item = itemConfig:GetCollectible(id)
		if item then
			table.insert(collectibles, item)
		end
	end

	return collectibles
end



local COLLECTIBLE_TYPE_THAT_IS_NOT_IN_ANY_POOLS = CollectibleType.COLLECTIBLE_KEY_PIECE_1
local COLLECTIBLES_THAT_AFFECT_ITEM_POOLS = {
    CollectibleType.COLLECTIBLE_CHAOS,
    CollectibleType.COLLECTIBLE_SACRED_ORB,
    CollectibleType.COLLECTIBLE_TMTRAINER
}

local TRINKETS_THAT_AFFECT_ITEM_POOLS = {
    TrinketType.TRINKET_NO
}


---@return table
---@return table
local function RemoveItemsAndTrinketsThatAffectItemPools()
    local removedItemsMap = {}
    local removedTrinketsMap = {}

    for _, player in ipairs(Helpers.GetPlayers()) do
        local playerIndex = Helpers.GetPlayerIndex(player)

        local removedItems = {}

        for _, itemToRemove in ipairs(COLLECTIBLES_THAT_AFFECT_ITEM_POOLS) do
            local numCollectibles = player:GetCollectibleNum(itemToRemove)

            for i = 1, numCollectibles, 1 do
                player:RemoveCollectible(itemToRemove)
                removedItems[#removedItems+1] = itemToRemove
            end
        end

        removedItemsMap[playerIndex] = removedItems

        local removedTrinkets = {}

        for _, trinketToRemove in ipairs(TRINKETS_THAT_AFFECT_ITEM_POOLS) do
            if player:HasTrinket(trinketToRemove) then
                local numTrinkets = player:GetTrinketMultiplier(trinketToRemove)

                for i = 1, numTrinkets, 1 do
                    player:TryRemoveTrinket(trinketToRemove)
                    removedTrinkets[#removedTrinkets+1] = trinketToRemove
                end
            end
        end

        removedTrinketsMap[playerIndex] = removedTrinkets
    end

    return removedItemsMap, removedTrinketsMap
end


---@param removedItemsMap table
---@param removedTrinketsMap table
local function RestoreItemsAndTrinketsThatAffectItemPools(removedItemsMap, removedTrinketsMap)
    for _, player in ipairs(Helpers.GetPlayers()) do
        local playerIndex = Helpers.GetPlayerIndex(player)

        local removedItems = removedItemsMap[playerIndex]
        if removedItems ~= nil then
            for _, collectibleType in ipairs(removedItems) do
                player:AddCollectible(collectibleType, 0, false)
            end
        end

        local removedTrinkets = removedTrinketsMap[playerIndex]
        if removedTrinkets ~= nil then
            for _, trinketType in ipairs(removedTrinkets) do
                player:AddTrinket(trinketType)
            end
        end
    end
end


---Helper function to see if the given collectible is still present in the given item pool.
---
---If the collectible is non-offensive, any Tainted Losts will be temporarily changed to Isaac 
---and then changed back. (This is because Tainted Lost is not able to retrieve non-offensive 
---collectibles from item pools).
---
---Under the hood, this function works by using the ItemPool.AddRoomBlacklist method to blacklist
---every collectible except for the one provided.
---@param collectibleType CollectibleType
---@param itemPoolType ItemPoolType
---@return boolean
function Helpers.IsCollectibleInItemPool(collectibleType, itemPoolType)
    --We use a specific collectible which is known to not be in any pools as a default value. Thus,
    --we must explicitly handle this case.
    if collectibleType == COLLECTIBLE_TYPE_THAT_IS_NOT_IN_ANY_POOLS then
      return false
    end

    --On Tainted Lost, it is impossible to retrieve non-offensive collectibles from pools, so we
    --temporarily change the character to Isaac.
    local taintedLosts = Helpers.GetPlayersOfType(PlayerType.PLAYER_THELOST_B)
    local isOffensive = Helpers.CollectibleHasFlag(
      collectibleType,
      1 << 20
    )

    local changedPlayerTypes = false;
    if not isOffensive then
        changedPlayerTypes = true;
        for _, player in ipairs(taintedLosts) do
            player:ChangePlayerType(PlayerType.PLAYER_ISAAC);
        end
    end

    local removedItemsMap, removedTrinketsMap = RemoveItemsAndTrinketsThatAffectItemPools()

    --Blacklist every collectible in the game except for the provided collectible.
    local itemPool = Game():GetItemPool();
    itemPool:ResetRoomBlacklist();
    for _, itemConfigItem in ipairs(Helpers.GetCollectibles()) do
        if itemConfigItem.ID ~= collectibleType then
            ---@diagnostic disable-next-line: param-type-mismatch
            itemPool:AddRoomBlacklist(itemConfigItem.ID)
        end
    end

    --Get a collectible from the pool and see if it is the intended collectible. (We can use any
    --arbitrary value as the seed since it should not influence the result.)
    local seed = 1
    local retrievedCollectibleType = itemPool:GetCollectible(
      itemPoolType,
      false,
      seed,
      COLLECTIBLE_TYPE_THAT_IS_NOT_IN_ANY_POOLS
    )
    local collectibleUnlocked = retrievedCollectibleType == collectibleType

    --Reset the blacklist
    itemPool:ResetRoomBlacklist()

    RestoreItemsAndTrinketsThatAffectItemPools(removedItemsMap, removedTrinketsMap)

    --Change any players back to Tainted Lost, if necessary.
    if changedPlayerTypes then
        for _, player in ipairs(taintedLosts) do
            player:ChangePlayerType(PlayerType.PLAYER_THELOST_B);
        end
    end

    return collectibleUnlocked;
end


return Helpers