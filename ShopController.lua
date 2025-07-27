-------------------------------------------------------------------------------
-- ShopController.lua · (Corrected and Restructured)
-- • FIX: Updated to use "Upgrades" and "Perks" categories from ShopItems.
-- • FIX: Removed outdated logic that caused script errors and prevented the shop from opening.
-- • FIX: Robux purchases are correctly handled entirely on the client.
-------------------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

local player = Players.LocalPlayer

-- Config & Remotes
local ShopItems         = require(ReplicatedStorage.Config.ShopItems)
local Remotes           = ReplicatedStorage.Remotes
local BuyItemRF         = Remotes.BuyItem
local OpenShopEvt       = ReplicatedStorage.OpenShop
local ModalState        = ReplicatedStorage.UIEvents.ModalState
local RequestCosmetics  = Remotes.RequestCosmetics
local ReceiveCosmetics  = Remotes.ReceiveCosmetics

-- UI References
local panel      = script.Parent
local gui        = panel.Parent
local content    = panel.ContentArea
local rowTpl     = content.ItemTemplate
local closeBtn   = panel.CloseButton
local coinsLabel = panel.CurrencyBar.CoinsLabel
-- IMPORTANT: Make sure your UI has an "UpgradesTab" button, not "BoostsTab"
local tabs = {
	Upgrades  = panel.TabsBar.UpgradesTab,
	Cosmetics = panel.TabsBar.CosmeticsTab,
	Robux     = panel.TabsBar.RobuxTab,
}

-------------------------------------------------------------------------------
-- State & Caching
-------------------------------------------------------------------------------
local SELECTED_COLOR   = Color3.fromRGB(0, 180, 255)
local UNSELECTED_COLOR = Color3.fromRGB(0, 110, 185)
local currentTab       = "Upgrades" -- Default to the new tab
local hasInitialized   = false
local itemRows         = { Upgrades = {}, Cosmetics = {}, Robux = {} }

-------------------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------------------
local function comma(n: number): string
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

local function updateCoins(value)
	coinsLabel.Text = comma(value)
end

local function styleButton(btn: TextButton, state: string, isRobux: boolean)
	btn:SetAttribute("State", state)
	if state == "Buy" then
		btn.Text = "BUY"
		btn.BackgroundColor3 = isRobux and Color3.fromRGB(0, 80, 255) or Color3.fromRGB(0, 170, 0)
		btn.Active = true
		btn.AutoButtonColor = true
	elseif state == "Owned" then
		btn.Text = "OWNED"
		btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		btn.Active = false
		btn.AutoButtonColor = false
	else -- "Loading" or other states
		btn.Text = "..."
		btn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		btn.Active = false
		btn.AutoButtonColor = false
	end
end

-------------------------------------------------------------------------------
-- UI Population & Management
-------------------------------------------------------------------------------
local function createRow(tabName, item)
	local row = rowTpl:Clone()
	row.Name = item.Name
	row.Icon.Image = item.Icon or "rbxassetid://3926305904"
	row.NameLabel.Text = item.Name
	row.DescLabel.Text = item.Desc or ""

	local isRobux = item.ProductId ~= nil and not item.Price
	row.PriceLabel.Visible = not isRobux and item.Price and item.Price > 0
	if row.PriceLabel.Visible then
		row.PriceLabel.Text = " Coins: " .. comma(item.Price)
	end

	local btn = row.BuyButton
	btn.MouseButton1Click:Connect(function()
		if btn:GetAttribute("State") ~= "Buy" then return end
		styleButton(btn, "...", isRobux)

		if isRobux then
			MarketplaceService:PromptProductPurchase(player, item.ProductId)
			task.wait(0.5)
			if btn:GetAttribute("State") == "..." then
				styleButton(btn, "Buy", isRobux) -- Reset if purchase is cancelled
			end
		else
			-- All coin purchases go through the server
			local success = BuyItemRF:InvokeServer(tabName, item.Name)
			styleButton(btn, success and "Owned" or "Buy", isRobux)
		end
	end)

	row.Parent = content
	itemRows[tabName][item.Name] = row
	return row
end

local function setTab(tabName: string)
	currentTab = tabName
	for name, btn in pairs(tabs) do
		btn.BackgroundColor3 = (name == tabName) and SELECTED_COLOR or UNSELECTED_COLOR
	end

	for tab, rows in pairs(itemRows) do
		for _, row in pairs(rows) do
			row.Visible = (tab == tabName)
		end
	end
end

local function initializeShop()
	if hasInitialized then return end

	-- Correctly populate from the new categories
	for _, item in ipairs(ShopItems.Upgrades) do createRow("Upgrades", item) end
	for _, item in ipairs(ShopItems.Perks) do createRow("Upgrades", item) end
	for _, item in ipairs(ShopItems.Cosmetics) do createRow("Cosmetics", item) end
	for _, item in ipairs(ShopItems.Robux) do createRow("Robux", item) end

	hasInitialized = true
	content.CanvasSize = UDim2.fromOffset(0, content.UIListLayout.AbsoluteContentSize.Y)
end

local function updateAllButtonStates()
	-- Request cosmetic ownership data from the server
	for _, row in pairs(itemRows.Cosmetics) do styleButton(row.BuyButton, "...", false) end
	RequestCosmetics:FireServer()

	-- Set Upgrades and Perks to "Buy" state. You can add more complex
	-- logic here later to check for ownership from player data if needed.
	for _, row in pairs(itemRows.Upgrades) do
		styleButton(row.BuyButton, "Buy", false)
	end

	-- Robux items are always buyable
	for _, row in pairs(itemRows.Robux) do
		styleButton(row.BuyButton, "Buy", true)
	end
end

-------------------------------------------------------------------------------
-- Open / Close Logic & Event Connections
-------------------------------------------------------------------------------
local function openShop()
	initializeShop()
	ModalState:Fire(true)
	gui.Enabled, panel.Visible = true, true
	setTab(currentTab)
	task.spawn(updateAllButtonStates)
end

local function closeShop()
	gui.Enabled, panel.Visible = false, false
	ModalState:Fire(false)
end

for name, button in pairs(tabs) do
	button.MouseButton1Click:Connect(function() setTab(name) end)
end

closeBtn.MouseButton1Click:Connect(closeShop)
UserInputService.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.Escape and gui.Enabled then closeShop() end
end)
OpenShopEvt.Event:Connect(openShop)

ReceiveCosmetics.OnClientEvent:Connect(function(cosmeticsData)
	if not cosmeticsData or not cosmeticsData.OwnedCosmetics then return end

	for _, row in pairs(itemRows.Cosmetics) do styleButton(row.BuyButton, "Buy", false) end
	local ownedTrails = cosmeticsData.OwnedCosmetics.Trails or {}
	for _, trailName in ipairs(ownedTrails) do
		if itemRows.Cosmetics[trailName] then
			styleButton(itemRows.Cosmetics[trailName].BuyButton, "Owned", false)
		end
	end
end)

local leaderstats = player:WaitForChild("leaderstats")
leaderstats:WaitForChild("Coins").Changed:Connect(updateCoins)
updateCoins(leaderstats.Coins.Value)

if not RunService:IsRunning() then openShop() end