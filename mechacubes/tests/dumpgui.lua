-- Everything visible in the player's GUI, with absolute rectangles and draw order.
local pg = JOINER:FindFirstChild("PlayerGui")
local out = {}
local old = not API.classes.GuiObject.props.AnchorPoint -- 2016 engines: ZIndex 1..10, global order
local function c3(c) if not c then return {0, 0, 0} end return { c.r, c.g, c.b } end
local order = 0
local function visit(o, guiIndex, siblingPath)
	local cls = rawget(o, "_class")
	if isA(cls, "GuiObject") then
		if o.Visible == false then return end
		local x, y, w, h = ABSRECT(o)
		order = order + 1
		local p = rawget(o, "_p")
		local z = p.ZIndex or 1
		local item = {
			x = x, y = y, w = w, h = h, cls = cls, name = p.Name, order = order, gui = guiIndex, full = o:GetFullName(),
			z = z, path = siblingPath,
			bg = c3(p.BackgroundColor3), bgt = p.BackgroundTransparency or 0, border = p.BorderSizePixel or 0,
			text = (p.Text ~= nil and isA(cls, "GuiObject") and p.Text) or nil, tc = c3(p.TextColor3), tt = p.TextTransparency or 0,
			scaled = p.TextScaled and true or false, ts = p.TextSize or 0,
			fontsize = p.FontSize and p.FontSize.Name or "", xa = p.TextXAlignment and p.TextXAlignment.Name or nil, ya = p.TextYAlignment and p.TextYAlignment.Name or nil, image = p.Image or nil, it = p.ImageTransparency or 0, ic = c3(p.ImageColor3),
			clip = p.ClipsDescendants and true or false,
		}
		table.insert(out, item)
	end
	local kids = {}
	for i, c in ipairs(rawget(o, "_children")) do kids[i] = c end
	for i, c in ipairs(kids) do
		local sp = {}
		for k, v in ipairs(siblingPath) do sp[k] = v end
		local cz = rawget(c, "_p").ZIndex or 1
		table.insert(sp, cz * 100000 + i)
		visit(c, guiIndex, sp)
	end
end
local gi = 0
for _, g in ipairs(rawget(pg, "_children")) do
	if rawget(g, "_class") == "ScreenGui" and rawget(g, "_p").Enabled ~= false then
		gi = gi + 1
		visit(g, (rawget(g, "_p").DisplayOrder or 0) * 1000 + gi, {})
	end
end
return out
