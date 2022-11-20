local Constants = {}

Constants.CollectibleType = {
    DEVIL_KEY_PIECE_1 = Isaac.GetItemIdByName("Devil Key Piece 1"),
    DEVIL_KEY_PIECE_2 = Isaac.GetItemIdByName("Devil Key Piece 2"),

    ANGELS_ACHIEVEMENT_TRACKER = Isaac.GetItemIdByName("##ANGELS_ACHIEVEMENT_TRACKER"),
    NUMBER_MAGNET_ACHIEVEMENT_TRACKER = Isaac.GetItemIdByName("##NUMBER_MAGNET_ACHIEVEMENT_TRACKER")
}

Constants.FamiliarVariant = {
    DEVIL_KEY_PIECE_1 = Isaac.GetEntityVariantByName("Devil Key Piece 1"),
    DEVIL_KEY_PIECE_2 = Isaac.GetEntityVariantByName("Devil Key Piece 2"),
    DEVIL_KEY_PIECE_FULL = Isaac.GetEntityVariantByName("Devil Key Piece Full"),
}

Constants.AngelTypeToKeyPiece = {
    [EntityType.ENTITY_URIEL] = Constants.CollectibleType.DEVIL_KEY_PIECE_1,
    [EntityType.ENTITY_GABRIEL] = Constants.CollectibleType.DEVIL_KEY_PIECE_2
}

return Constants