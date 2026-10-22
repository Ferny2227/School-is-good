id = 139486131
player = script.Parent.Parent.Parent.Parent
function onClick()
	 game:GetService("MarketplaceService"):PromptPurchase(player,id,2)
end
script.Parent.MouseButton1Down:connect(onClick)

 