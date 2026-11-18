local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local getInventory = remotes:WaitForChild("GetInventory")

-- (removed: the client now waits for real data below)

local equipItem = remotes:WaitForChild("EquipItem")
local unequipItem = remotes:WaitForChild("UnequipItem")
local inventory = getInventory:InvokeServer()
local waited = 0
while (not inventory or (#inventory.Items == 0 and waited < 3)) and waited < 40 do
    task.wait(0.5)
        waited += 0.5
    inventory = getInventory:InvokeServer()
end

if not inventory then
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ItemConfig = require(ReplicatedStorage.Shared.ItemConfig)

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 400)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.Parent = gui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = frame

local framePadding = Instance.new("UIPadding")
framePadding.PaddingTop = UDim.new(0, 10)
framePadding.PaddingBottom = UDim.new(0, 10)
framePadding.PaddingLeft = UDim.new(0, 10)
framePadding.PaddingRight = UDim.new(0, 10)
framePadding.Parent = frame

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 36)
title.LayoutOrder = -1
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.Text = "Inventory"
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Control"
closeBtn.Size = UDim2.new(1, 0, 0, 30)
closeBtn.LayoutOrder = 0
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "Close (press B to reopen)"
closeBtn.Parent = frame

closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

-- Separate GUI so it stays visible when the inventory is closed
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "InventoryToggleGui"
toggleGui.ResetOnSpawn = false
toggleGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(120, 40)
toggleBtn.Position = UDim2.new(1, -130, 1, -50)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.Text = "Inventory (B)"
toggleBtn.Parent = toggleGui

toggleBtn.MouseButton1Click:Connect(function()
    gui.Enabled = not gui.Enabled
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.B then
        gui.Enabled = not gui.Enabled
    end
end)

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Size = UDim2.new(1, 0, 1, -150)
list.LayoutOrder = 20
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = frame

local listLayout = Instance.new("UIGridLayout")
listLayout.CellSize = UDim2.fromOffset(88, 88)
listLayout.CellPadding = UDim2.fromOffset(8, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local tooltip = Instance.new("TextLabel")
tooltip.Name = "Tooltip"
tooltip.Visible = false
tooltip.ZIndex = 10
tooltip.AutomaticSize = Enum.AutomaticSize.XY
tooltip.Size = UDim2.fromOffset(0, 0)
tooltip.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
tooltip.TextColor3 = Color3.new(1, 1, 1)
tooltip.Font = Enum.Font.Gotham
tooltip.TextSize = 16
tooltip.TextWrapped = true
tooltip.TextXAlignment = Enum.TextXAlignment.Left
tooltip.Parent = gui

local tooltipPadding = Instance.new("UIPadding")
tooltipPadding.PaddingTop = UDim.new(0, 8)
tooltipPadding.PaddingBottom = UDim.new(0, 8)
tooltipPadding.PaddingLeft = UDim.new(0, 10)
tooltipPadding.PaddingRight = UDim.new(0, 10)
tooltipPadding.Parent = tooltip

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 8)
tooltipCorner.Parent = tooltip

local tooltipLimit = Instance.new("UISizeConstraint")
tooltipLimit.MaxSize = Vector2.new(240, 1000)
tooltipLimit.Parent = tooltip

local function moveTooltip()
    local pos = UserInputService:GetMouseLocation()
    tooltip.Position = UDim2.fromOffset(pos.X + 16, pos.Y + 16)
end

local currentFilter = "All"
local currentSort = "Rarity"
local render -- forward declaration

local function makeControl(text, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Name = "Control"
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        onClick(btn)
        render()
    end)
    return btn
end

local filters = { "All", "Weapon", "Consumable", "Material" }
local filterIndex = 1
makeControl("Filter: All", 1, function(btn)
    filterIndex = filterIndex % #filters + 1
    currentFilter = filters[filterIndex]
    btn.Text = "Filter: " .. currentFilter
end)

local sorts = { "Rarity", "Name", "Amount" }
local sortIndex = 1
makeControl("Sort: Rarity", 2, function(btn)
    sortIndex = sortIndex % #sorts + 1
    currentSort = sorts[sortIndex]
    btn.Text = "Sort: " .. currentSort
end)

function render()
    tooltip.Visible = false
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Filter
    local visible = {}
    for _, item in ipairs(inventory.Items) do
        local data = ItemConfig.Items[item.ItemId]
        if currentFilter == "All" or data.Category == currentFilter then
            table.insert(visible, item)
        end
    end

    -- Sort
    table.sort(visible, function(a, b)
        local da, db = ItemConfig.Items[a.ItemId], ItemConfig.Items[b.ItemId]
        if currentSort == "Rarity" then
            local ra = ItemConfig.Rarities[da.Rarity].SortOrder
            local rb = ItemConfig.Rarities[db.Rarity].SortOrder
            if ra ~= rb then
                return ra > rb -- rarest first
            end
        elseif currentSort == "Amount" then
            if a.Amount ~= b.Amount then
                return a.Amount > b.Amount
            end
        end
        if da.DisplayName ~= db.DisplayName then
            return da.DisplayName < db.DisplayName
        end
        return a.UID < b.UID -- stable tiebreak
    end)

    for i, item in ipairs(visible) do
        local data = ItemConfig.Items[item.ItemId]
        local rarity = ItemConfig.Rarities[data.Rarity]
        local isEquipped = inventory.EquippedItem == item.UID

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 40)
        button.BackgroundColor3 = rarity.Color
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.TextWrapped = true
        button.Text = data.DisplayName .. "\nx" .. item.Amount
            .. (isEquipped and "\n[EQUIPPED]" or "")
            button.LayoutOrder = i

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = button

            if isEquipped then
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.new(1, 1, 1)
                stroke.Thickness = 3
                stroke.Parent = button
            end
    
            button.Parent = list

            button.MouseEnter:Connect(function()
                tooltip.Text = data.DisplayName .. " (" .. data.Rarity .. ")\n"
                    .. data.Description .. "\n"
                    .. "Category: " .. data.Category .. "\n"
                    .. "Sell price: " .. data.SellPrice
                moveTooltip()
                tooltip.Visible = true
            end)
    
            button.MouseMoved:Connect(moveTooltip)
    
            button.MouseLeave:Connect(function()
                tooltip.Visible = false
            end)

        button.MouseButton1Click:Connect(function()
            if data.Category ~= "Weapon" then
                return
            end

            if isEquipped then
                unequipItem:InvokeServer()
            else
                equipItem:InvokeServer(item.UID)
            end

            inventory = getInventory:InvokeServer()
            render()
        end)
    end
end

render()