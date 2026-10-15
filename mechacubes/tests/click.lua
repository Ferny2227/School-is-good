-- Clicks every visible button in the player's GUI, one at a time, and notes which click caused errors.
local pg = JOINER:FindFirstChild("PlayerGui")
local function visible(o)
	while o and rawget(o, "_class") ~= "PlayerGui" do
		local c = rawget(o, "_class")
		if c == "ScreenGui" then
			if rawget(o, "_p").Enabled == false then return false end
		elseif isA(c, "GuiObject") then
			if o.Visible == false then return false end
		end
		o = o.Parent
	end
	return o ~= nil
end
local function fire(btn, name, ...)
	local ev = rawget(btn, "_events")[name]
	if ev then
		CTX = CLIENT_CTX
		ev:_fire(...)
		CTX = SERVER
	end
end
CLICKED = {}
local done = {}
for round = 1, ROUNDS or 3 do
	local list = {}
	local function walk(o)
		for _, c in ipairs(rawget(o, "_children")) do
			if isA(rawget(c, "_class"), "GuiButton") and not done[c] and visible(c) then table.insert(list, c) end
			walk(c)
		end
	end
	walk(pg)
	if #list == 0 then break end
	table.sort(list, function(a, b) return a:GetFullName() < b:GetFullName() end)
	for _, b in ipairs(list) do
		if not done[b] and b.Parent and visible(b) then
			done[b] = true
			local before = #ERRORS
			fire(b, "MouseEnter", 1, 1)
			fire(b, "MouseButton1Down", 1, 1)
			fire(b, "MouseButton1Up", 1, 1)
			fire(b, "MouseButton1Click")
			fire(b, "Activated")
			runFor(1.5)
			fire(b, "MouseLeave", 1, 1)
			runFor(0.5)
			local errs = {}
			for i = before + 1, #ERRORS do table.insert(errs, ERRORS[i].msg) end
			table.insert(CLICKED, { path = b:GetFullName(), errors = errs })
			if SNAP then SNAP(b:GetFullName()) end
		end
	end
end
