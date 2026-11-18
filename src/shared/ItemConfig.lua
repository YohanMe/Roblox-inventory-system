
-- ItemConfig.lua
-- Shared item definitions for the inventory system

local ItemConfig = {}

ItemConfig.Rarities = {
    Common = {
        Color = Color3.fromRGB(190, 190, 190),
        SortOrder = 1
    },

    Rare = {
        Color = Color3.fromRGB(65, 150, 255),
        SortOrder = 2
    },

    Epic = {
        Color = Color3.fromRGB(170, 85, 255),
        SortOrder = 3
    },

    Legendary = {
        Color = Color3.fromRGB(255, 190, 45),
        SortOrder = 4
    }
}

ItemConfig.Items = {
    wood_sword = {
        DisplayName = "Wooden Sword",
        Description = "A basic sword for beginners.",
        Rarity = "Common",
        Category = "Weapon",
        MaxStack = 1,
        SellPrice = 10
    },

    iron_sword = {
        DisplayName = "Iron Sword",
        Description = "A reliable sword made of iron.",
        Rarity = "Rare",
        Category = "Weapon",
        MaxStack = 1,
        SellPrice = 75
    },

    health_potion = {
        DisplayName = "Health Potion",
        Description = "Restores a small amount of health.",
        Rarity = "Common",
        Category = "Consumable",
        MaxStack = 20,
        SellPrice = 15
    },

    diamond = {
        DisplayName = "Diamond",
        Description = "A valuable and rare gemstone.",
        Rarity = "Legendary",
        Category = "Material",
        MaxStack = 99,
        SellPrice = 500
    },

    magic_crystal = {
        DisplayName = "Magic Crystal",
        Description = "A mysterious crystal containing magic.",
        Rarity = "Epic",
        Category = "Material",
        MaxStack = 50,
        SellPrice = 200
    }
}

return ItemConfig