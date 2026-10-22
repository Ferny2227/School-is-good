id = 139486113
player = script.Parent.Parent.Parent.Parent
function onClick()
	 game:GetService("MarketplaceService"):PromptPurchase(player,id,2)
end
script.Parent.MouseButton1Up:connect(onClick)

 