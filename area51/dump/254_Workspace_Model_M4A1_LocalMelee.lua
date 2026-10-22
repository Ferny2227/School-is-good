--[[

Dax,

See the MeleeScript.

]]

local canmelee = true;
local tool = script.Parent;

function onKeyDown(key)
	key:lower();
	if key == "v" then
		if canmelee == false then
			return;
		end

		tool.Melee:play()

		canmelee = false;

		local rgrip = tool.Parent["Right Arm"].RightGrip;

		script.melee.Value = true;

		for i = 1,6 do
			rgrip.C1 = rgrip.C1 * CFrame.fromEulerAnglesXYZ(-0.55,0,0);
			wait();
		end

		wait(0.25);

		for i = 1, 6 do
			rgrip.C1 = rgrip.C1 * CFrame.fromEulerAnglesXYZ(0.55,0,0);
			wait();
		end

		script.melee.Value = false;

		wait(0.5);

		canmelee = true;
	end
end

function onSelect(mouse)
	mouse.KeyDown:connect(onKeyDown);
end


function blow(hit)
	local humanoid = hit.Parent:findFirstChild("Humanoid")
	if not humanoid then return end
	local vCharacter = Tool.Parent
	local vPlayer = game.Players:playerFromCharacter(vCharacter)
	local hum = vCharacter:findFirstChild("Humanoid") -- non-nil if tool held by a character
	if humanoid ~= hum and hum ~= nil and game.Players:playerFromCharacter(humanoid.Parent) and game.Players:playerFromCharacter(humanoid.Parent).TeamColor~=cc then
		tagHumanoid(humanoid, vPlayer)
		humanoid:TakeDamage(300)
		wait(1)
		untagHumanoid(humanoid)
	end
end


tool.Equipped:connect(onSelect);