-- [fix] Shop window (client side). The old shop used server scripts inside the window, which can't see
-- clicks when FilteringEnabled is on. Now the buttons are handled here and the server does the buying
-- (ServerScriptService.ShopBuyServer), so it works on old and new servers.
local gui = script.Parent
local box = gui:WaitForChild("TextLabel")
local frame = box:WaitForChild("Frame")
local tooltip = gui:FindFirstChild("Tooltip", true)
local remote = game:GetService("ReplicatedStorage"):WaitForChild("ShopBuy")
local player = game:GetService("Players").LocalPlayer
local busy = false

local function hint(text)
	local h = Instance.new("Hint")
	h.Text = text
	h.Parent = player:FindFirstChild("PlayerGui") or gui
	delay(2, function() h:Destroy() end)
end

remote.OnClientEvent:connect(function(text)
	if gui.Parent then hint(text) end
end)

for _, item in ipairs(frame:GetChildren()) do
	local button = item:FindFirstChild("BuyButton")
	local itemName = item:FindFirstChild("ItemName")
	if button and itemName then
		button.MouseButton1Click:connect(function()
			if busy then return end
			busy = true
			remote:FireServer(itemName.Value)
			wait(0.3)
			busy = false
		end)
		if tooltip then
			button.MouseEnter:connect(function()
				tooltip.Visible = true
				pcall(function()
					tooltip.ItemName.Text = itemName.Value
					tooltip.Price.Text = "Cost: " .. item.Cost.Value .. " " .. item.Currency.Value
					tooltip.Description.Text = item.Description.Value
				end)
			end)
			button.MouseMoved:connect(function(x, y)
				tooltip.Visible = true
				tooltip.Position = UDim2.new(0, x + 40, 0, y)
			end)
			button.MouseLeave:connect(function()
				tooltip.Visible = false
			end)
		end
	end
end

local close = box:FindFirstChild("TextButton")
if close then
	close.MouseButton1Click:connect(function()
		gui:Destroy()
	end)
end
