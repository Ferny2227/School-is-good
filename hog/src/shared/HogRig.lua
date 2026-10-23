-- shared (server + every player's computer): what the Hog looks like and how its arms and legs swing.
-- The server builds the bot Hog from this list; each player's computer moves it smoothly (no physics, no lag).
local HOG_UP = 2.8        -- the Hog's root is this high above the floor
local HOG_PARTS = {
	-- name, size, offset from the root, colour, material, shape, limb (swings around the hinge), extra rotation
	{ "Torso", Vector3.new(2.4, 2.4, 1.4), Vector3.new(0, 0.6, 0), "Pink", "SmoothPlastic" },
	{ "Overalls", Vector3.new(2.5, 1.3, 1.5), Vector3.new(0, -0.05, 0), "Bright blue", "Fabric" },
	{ "Head", Vector3.new(2.5, 2.3, 2.3), Vector3.new(0, 3, 0), "Pink", "SmoothPlastic" },
	{ "Snout", Vector3.new(0.5, 1.2, 1.2), Vector3.new(0, 2.75, -1.3), "Carnation pink", "SmoothPlastic", "cyl", nil, CFrame.Angles(0, math.pi / 2, 0) },
	{ "NostrilL", Vector3.new(0.25, 0.35, 0.1), Vector3.new(-0.22, 2.75, -1.58), "Black", "SmoothPlastic" },
	{ "NostrilR", Vector3.new(0.25, 0.35, 0.1), Vector3.new(0.22, 2.75, -1.58), "Black", "SmoothPlastic" },
	{ "EyeL", Vector3.new(0.6, 0.6, 0.1), Vector3.new(-0.65, 3.45, -1.17), "Institutional white", "SmoothPlastic" },
	{ "EyeR", Vector3.new(0.6, 0.6, 0.1), Vector3.new(0.65, 3.45, -1.17), "Institutional white", "SmoothPlastic" },
	{ "PupilL", Vector3.new(0.3, 0.3, 0.1), Vector3.new(-0.65, 3.4, -1.23), "Really red", "Neon" },
	{ "PupilR", Vector3.new(0.3, 0.3, 0.1), Vector3.new(0.65, 3.4, -1.23), "Really red", "Neon" },
	{ "BrowL", Vector3.new(0.8, 0.18, 0.1), Vector3.new(-0.65, 3.85, -1.2), "Black", "SmoothPlastic", nil, nil, CFrame.Angles(0, 0, -0.35) },
	{ "BrowR", Vector3.new(0.8, 0.18, 0.1), Vector3.new(0.65, 3.85, -1.2), "Black", "SmoothPlastic", nil, nil, CFrame.Angles(0, 0, 0.35) },
	{ "Mouth", Vector3.new(1.2, 0.2, 0.1), Vector3.new(0, 2.2, -1.17), "Black", "SmoothPlastic" },
	{ "EarL", Vector3.new(0.7, 0.8, 0.3), Vector3.new(-0.95, 4.25, -0.2), "Carnation pink", "SmoothPlastic", nil, nil, CFrame.Angles(0, 0, 0.4) },
	{ "EarR", Vector3.new(0.7, 0.8, 0.3), Vector3.new(0.95, 4.25, -0.2), "Carnation pink", "SmoothPlastic", nil, nil, CFrame.Angles(0, 0, -0.4) },
	{ "LeftArm", Vector3.new(1, 2.3, 1), Vector3.new(-1.75, 0.45, 0), "Pink", "SmoothPlastic", nil, { Vector3.new(-1.75, 1.5, 0), -1 } },
	{ "RightArm", Vector3.new(1, 2.3, 1), Vector3.new(1.75, 0.45, 0), "Pink", "SmoothPlastic", nil, { Vector3.new(1.75, 1.5, 0), 1 } },
	{ "Bat", Vector3.new(0.45, 3.4, 0.45), Vector3.new(1.75, -0.4, -1.3), "Reddish brown", "Wood", nil, { Vector3.new(1.75, 1.5, 0), 1 }, CFrame.Angles(-1.1, 0, 0) },
	{ "LeftLeg", Vector3.new(1.15, 2.2, 1.15), Vector3.new(-0.6, -1.7, 0), "Bright blue", "Fabric", nil, { Vector3.new(-0.6, -0.6, 0), 1 } },
	{ "RightLeg", Vector3.new(1.15, 2.2, 1.15), Vector3.new(0.6, -1.7, 0), "Bright blue", "Fabric", nil, { Vector3.new(0.6, -0.6, 0), -1 } },
}
-- where every part goes when the Hog's root is at `root`, `swing` = how far the arms and legs swing (radians),
-- `smash` = 0..1 the bat swinging down
local function HogPose(root, swing, smash)
	local out = {}
	for _, d in ipairs(HOG_PARTS) do
		local off, hinge, extra = d[3], d[7], d[8]
		local cf
		if hinge then
			local a = swing * hinge[2]
			if (d[1] == "RightArm" or d[1] == "Bat") and smash and smash > 0 then a = -2.2 * smash end
			cf = root * CFrame.new(hinge[1]) * CFrame.Angles(a, 0, 0) * CFrame.new(off - hinge[1])
		else
			cf = root * CFrame.new(off)
		end
		if extra then cf = cf * extra end
		out[d[1]] = cf
	end
	return out
end
