
-- InventoryService.server.lua
-- Core server-side inventory management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

local inventoryStore = DataStoreService:GetDataStore("PlayerInventory_v1")

local ItemConfig = require(
    ReplicatedStorage.Shared.ItemConfig
)

local InventoryService = {}

local MAX_INVENTORY_SLOTS = 30

local PlayerInventories = {}

-- Create a new inventory
local function createInventory()
    return {
        Items = {},
        EquippedItem = nil,
        MaxSlots = MAX_INVENTORY_SLOTS
    }
end

-- Get a player's inventory
function InventoryService:GetInventory(player)
    return PlayerInventories[player.UserId]
end

-- Check whether an item exists
local function isValidItem(itemId)
    return ItemConfig.Items[itemId] ~= nil
end

-- Add an item to a player's inventory
function InventoryService:AddItem(player, itemId, amount)

    amount = amount or 1

    if not isValidItem(itemId) then
        return false, "Invalid item."
    end

    if type(amount) ~= "number"
        or amount ~= amount
        or amount == math.huge
        or amount == -math.huge
        or amount % 1 ~= 0
        or amount < 1
        or amount > 1000 then

        return false, "Invalid amount."
    end

    local inventory = self:GetInventory(player)

    if not inventory then
        return false, "Inventory not found."
    end

    local itemData = ItemConfig.Items[itemId]

    -- Make sure everything fits BEFORE changing anything
    local remaining = amount
    if itemData.MaxStack > 1 then
        for _, item in ipairs(inventory.Items) do
            if item.ItemId == itemId and item.Amount < itemData.MaxStack then
                remaining -= math.min(itemData.MaxStack - item.Amount, remaining)
            end
        end
    end

    local slotsNeeded = math.ceil(remaining / itemData.MaxStack)
    if #inventory.Items + slotsNeeded > inventory.MaxSlots then
        return false, "Inventory is full."
    end

    -- Check for an existing stack
    if itemData.MaxStack > 1 then
        for _, item in ipairs(inventory.Items) do
            if item.ItemId == itemId
                and item.Amount < itemData.MaxStack then

                local space = itemData.MaxStack - item.Amount
                local added = math.min(space, amount)

                item.Amount += added
                amount -= added

                if amount == 0 then
                    return true, "Item added."
                end
            end
        end
    end

    -- Create new item stacks
    while amount > 0 do

        if #inventory.Items >= inventory.MaxSlots then
            return false, "Inventory is full."
        end

        local stackAmount = math.min(
            amount,
            itemData.MaxStack
        )

        local newItem = {
            UID = HttpService:GenerateGUID(false),
            ItemId = itemId,
            Amount = stackAmount
        }

        table.insert(inventory.Items, newItem)

        amount -= stackAmount
    end

    return true, "Item added."
end

-- Remove an item from inventory
function InventoryService:RemoveItem(player, uid, amount)

    amount = amount or 1

    if type(amount) ~= "number"
        or amount ~= amount
        or amount == math.huge
        or amount == -math.huge
        or amount % 1 ~= 0
        or amount < 1
        or amount > 1000 then

        return false, "Invalid amount."
    end

    local inventory = self:GetInventory(player)

    if not inventory then
        return false, "Inventory not found."
    end

    for index, item in ipairs(inventory.Items) do

        if item.UID == uid then

            if item.Amount < amount then
                return false, "Not enough items."
            end

            item.Amount -= amount

            if item.Amount == 0 then
                table.remove(inventory.Items, index)
            end

            if inventory.EquippedItem == uid
                and item.Amount == 0 then

                inventory.EquippedItem = nil
            end

            return true, "Item removed."
        end
    end

    return false, "Item not found."
end

-- Equip an item (weapons only for now)
function InventoryService:EquipItem(player, uid)
    local inventory = self:GetInventory(player)
    if not inventory then
        return false, "Inventory not found."
    end

    for _, item in ipairs(inventory.Items) do
        if item.UID == uid then
            local itemData = ItemConfig.Items[item.ItemId]
            if itemData.Category ~= "Weapon" then
                return false, "Item cannot be equipped."
            end
            inventory.EquippedItem = uid
            return true, "Item equipped."
        end
    end

    return false, "Item not found."
end

-- Unequip whatever is equipped
function InventoryService:UnequipItem(player)
    local inventory = self:GetInventory(player)
    if not inventory then
        return false, "Inventory not found."
    end

    inventory.EquippedItem = nil
    return true, "Item unequipped."
end

-- Retry wrapper for DataStore calls
local function withRetry(fn)
    for attempt = 1, 3 do
        local ok, result = pcall(fn)
        if ok then
            return true, result
        end
        warn("[Inventory] DataStore attempt " .. attempt .. " failed: " .. tostring(result))
        task.wait(2 ^ attempt)
    end
    return false, nil
end

-- Remove saved entries whose item no longer exists in ItemConfig
local function sanitize(saved)
    local inventory = createInventory()

    if type(saved) ~= "table" or type(saved.Items) ~= "table" then
        return inventory
    end

    for _, item in ipairs(saved.Items) do
        if type(item) == "table"
            and type(item.UID) == "string"
            and isValidItem(item.ItemId)
            and type(item.Amount) == "number"
            and item.Amount >= 1 then

            table.insert(inventory.Items, {
                UID = item.UID,
                ItemId = item.ItemId,
                Amount = math.min(item.Amount, ItemConfig.Items[item.ItemId].MaxStack)
            })
        end
    end

    if type(saved.EquippedItem) == "string" then
        for _, item in ipairs(inventory.Items) do
            if item.UID == saved.EquippedItem then
                inventory.EquippedItem = saved.EquippedItem
            end
        end
    end

    return inventory
end

local function saveInventory(player)
    local inventory = PlayerInventories[player.UserId]
    if not inventory or not inventory.Loaded then
        return
    end

    local data = {
        Items = inventory.Items,
        EquippedItem = inventory.EquippedItem
    }

    local ok = withRetry(function()
        inventoryStore:SetAsync(tostring(player.UserId), data)
    end)

    if ok then
        print("[Inventory] Saved", player.Name)
    end
end

-- Initialize player inventory
local function onPlayerAdded(player)
    local ok, saved = withRetry(function()
        return inventoryStore:GetAsync(tostring(player.UserId))
    end)

    if not player.Parent then
        return -- left while loading
    end

    if ok then
        PlayerInventories[player.UserId] = sanitize(saved)
        PlayerInventories[player.UserId].Loaded = true
    else
        -- Load failed: give a temporary inventory that will NOT save,
        -- so we never overwrite real data with an empty one
        PlayerInventories[player.UserId] = createInventory()
    end

    print("[Inventory] Created inventory for", player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Catch players who joined before this script connected
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- Save and clean up player data
Players.PlayerRemoving:Connect(function(player)
    saveInventory(player)
    PlayerInventories[player.UserId] = nil
end)

-- Autosave every 2 minutes
task.spawn(function()
    while true do
        task.wait(120)
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(saveInventory, player)
        end
    end
end)

-- Save everyone when the server shuts down
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, player)
    end
    task.wait(3)
end)

return InventoryService
