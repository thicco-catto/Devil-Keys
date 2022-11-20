local CheckAchievements = {}
local Helpers = require("devil_keys_scripts.Helpers")
local Constants = require("devil_keys_scripts.Constants")


function CheckAchievements:OnGameStart(isContinue)
    if isContinue then return end

    DevilKeysMod.Data.IsAngelsUnlocked = Helpers.IsCollectibleInItemPool(Constants.CollectibleType.ANGELS_ACHIEVEMENT_TRACKER, ItemPoolType.POOL_WOODEN_CHEST)
    DevilKeysMod.Data.IsNumberMagnedUnlocked = Helpers.IsCollectibleInItemPool(Constants.CollectibleType.NUMBER_MAGNET_ACHIEVEMENT_TRACKER, ItemPoolType.POOL_WOODEN_CHEST)

    local itemPool = Game():GetItemPool()

    local wasAngelsTrackerInItemPool = itemPool:RemoveCollectible(Constants.CollectibleType.ANGELS_ACHIEVEMENT_TRACKER)

    while wasAngelsTrackerInItemPool do
        wasAngelsTrackerInItemPool = itemPool:RemoveCollectible(Constants.CollectibleType.ANGELS_ACHIEVEMENT_TRACKER)
    end

    local wasMagnetTrackerInItemPool = itemPool:RemoveCollectible(Constants.CollectibleType.NUMBER_MAGNET_ACHIEVEMENT_TRACKER)

    while wasMagnetTrackerInItemPool do
        wasMagnetTrackerInItemPool = itemPool:RemoveCollectible(Constants.CollectibleType.NUMBER_MAGNET_ACHIEVEMENT_TRACKER)
    end
end
DevilKeysMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, CheckAchievements.OnGameStart)