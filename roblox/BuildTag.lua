
-- build tag (bottom middle): tells you which version of the place file is running
pcall(function()
	local tag = Instance.new("TextLabel")
	tag.Name = "BuildTag"
	tag.BackgroundTransparency = 1
	tag.Position = UDim2.new(0.5, -75, 1, -18)
	tag.Size = UDim2.new(0, 150, 0, 16)
	tag.TextColor3 = Color3.new(1, 1, 1)
	tag.TextTransparency = 0.4
	tag.FontSize = Enum.FontSize.Size12
	tag.Text = "build: admin-3"
	tag.Parent = gui
end)
