-- [fix] Buys weapons for the shop windows (see ShopClient in each ShopGui). Checks the price on the server.
local remote = game:GetService("ReplicatedStorage"):WaitForChild("ShopBuy")
local SHOPS = {"Automatic weapon shop", "Semi Automatic and Melee weapon shop", "Unique weapon shop", "Weapon skin shop"}

local function findItem(itemName)
	local map = workspace:FindFirstChild("Map")
	if not map then return nil end
	for _, shopName in ipairs(SHOPS) do
		local shop = map:FindFirstChild(shopName)
		local frame = shop and shop:FindFirstChild("Head") and shop.Head:FindFirstChild("Dialog")
			and shop.Head.Dialog:FindFirstChild("ShopGui") and shop.Head.Dialog.ShopGui.TextLabel:FindFirstChild("Frame")
		if frame then
			for _, item in ipairs(frame:GetChildren()) do
				if item:FindFirstChild("ItemName") and item.ItemName.Value == itemName then
					return item
				end
			end
		end
	end
end

local lastBuy = {}
remote.OnServerEvent:connect(function(player, itemName)
	if type(itemName) ~= "string" then return end
	if lastBuy[player] and tick() - lastBuy[player] < 0.25 then return end
	lastBuy[player] = tick()
	local item = findItem(itemName)
	if not item then return end
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild(item.Currency.Value)
	if not cash then
		remote:FireClient(player, "You don't have any " .. item.Currency.Value .. "!")
		return
	end
	if cash.Value < item.Cost.Value then
		remote:FireClient(player, "You don't have enough " .. item.Currency.Value .. "!")
		return
	end
	local tool = game.Lighting:FindFirstChild(itemName)
	if not tool then
		remote:FireClient(player, itemName .. " is missing from Lighting!")
		return
	end
	cash.Value = cash.Value - item.Cost.Value
	tool:Clone().Parent = player:FindFirstChild("Backpack")
	local gear = player:FindFirstChild("StarterGear")
	if gear then tool:Clone().Parent = gear end
	remote:FireClient(player, "You have bought " .. itemName .. "!")
end)
game:GetService("Players").PlayerRemoving:connect(function(p) lastBuy[p] = nil end)
