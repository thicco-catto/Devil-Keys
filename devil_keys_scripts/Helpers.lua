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


return Helpers