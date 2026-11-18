print("[Main] running")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(script.Parent.InventoryService)

-- Remotes
local remotes = Instance.new("Folder")
remotes.Name = "InventoryRemotes"
remotes.Parent = ReplicatedStorage

local function makeFunction(name)
    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = remotes
    return remote
end

makeFunction("GetInventory").OnServerInvoke = function(player)
    return InventoryService:GetInventory(player)
end

makeFunction("EquipItem").OnServerInvoke = function(player, uid)
    if typeof(uid) ~= "string" then
        return false, "Invalid UID."
    end
    return InventoryService:EquipItem(player, uid)
end

makeFunction("UnequipItem").OnServerInvoke = function(player)
    return InventoryService:UnequipItem(player)
end

-- Starter kit: only given to players with an empty inventory
Players.PlayerAdded:Connect(function(player)
    while not InventoryService:GetInventory(player) do
        task.wait(0.2)
    end
    if #InventoryService:GetInventory(player).Items > 0 then
        return
    end
    InventoryService:AddItem(player, "wood_sword")
    InventoryService:AddItem(player, "iron_sword")
    InventoryService:AddItem(player, "health_potion", 5)
    InventoryService:AddItem(player, "diamond", 3)
    InventoryService:AddItem(player, "magic_crystal", 10)
end)