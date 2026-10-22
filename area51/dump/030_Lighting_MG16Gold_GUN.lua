wait()

OriginalToolName = script.Parent.Name
ToolName="MG-16Gold"
Firerate=.07
MinSpread=.05
MaxSpread=7
SpreadRate=0.5
BaseDamage=15
VehicleDamage=18
automatic=true
burst=false
shot=false			--Shotgun
BarrlePos=Vector3.new(2.3,0.15,-0.2)
Cursors={"rbxasset://textures\\GunCursor.png"}
ReloadCursor="rbxasset://textures\\GunWaitCursor.png"
-------------------------------------OTHER
equiped=false
sp=script.Parent
RayLength=999
Spread=.25
enabled=true
reloading=false
down=false
sfd=0
-------------------------------------RAYINFO
Bullet=Instance.new("Part")
Bullet.Name="Bullet"
Bullet.BrickColor=BrickColor.new("New Yeller")
Bullet.Anchored=true
Bullet.CanCollide=false
Bullet.Locked=true
Bullet.Size=Vector3.new(1,1,1)
--Bullet.Transparency=.65
Bullet.formFactor=0
Bullet.TopSurface=0
Bullet.BottomSurface=0
mesh=Instance.new("SpecialMesh")
mesh.Parent=Bullet
mesh.MeshType="Brick"
mesh.Name="Mesh"
mesh.Scale=Vector3.new(.15,.15,1)
-------------------------------------SPECS
MaxCharge=500
Charge=sp.Overheat
cooldownTime = 0.1
overheated = false
overheattime = 2.3
chargeperfireMIN = 3
chargeperfireMAX = 4
batteryLife=sp.Battery
maxDepletion=4
minDepletion=3
shotsForDepl=12
battery=true
-------------------------------------PLR
player=game.Players.LocalPlayer
-------------------------------------HITSOUND
sfx=Instance.new("Sound")
sfx.Name="HitSound"
sfx.Pitch=2
sfx.SoundId="http://www.roblox.com/asset/?id=15666462"
sfx.Volume=0.7
sfx.Looped=false
sfx.PlayOnRemove=false

function check()
	if equiped==true then
		if batteryLife.Value<=0 then
		batteryLife.Value=0
		battery=false
		player.PlayerGui.GunGui.Battery.Status.Text=tostring(batteryLife.Value)
		player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-95, 256-95, 256-95)
		player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-95, 256-95, 256-95)
		else
		player.PlayerGui.GunGui.Battery.Status.Text=tostring(batteryLife.Value)
		battery=true
			if batteryLife.Value<=50 and batteryLife.Value>25 then
			player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-218, 256-215, 256-0)
			player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-218, 256-215, 256-0)
			elseif batteryLife.Value<=25 then
			player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-255, 256-0, 256-0)
			player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-255, 256-0, 256-0)
			else
			player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-255, 256-255, 256-255)
			player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-255, 256-255, 256-255)
			end
		end
		if player.PlayerGui:findFirstChild("GunGui") ~= nil then
		player.PlayerGui.GunGui.Back.Frame:TweenSize(UDim2.new(Charge.Value/MaxCharge,0,1,0),"In","Linear",0.1)
		if overheated == false then
		player.PlayerGui.GunGui.Back.Status.Text = Charge.Value.."%"
		player.PlayerGui.GunGui.Back.Frame.BackgroundColor3 = Color3.new(256-0, 256-102, 256-255)
		--sp.Name=ToolName.." | "..Charge.Value.."%"
		end
		end
	sp.Overheat.Value = Charge.Value
	end
end

--Ugly, I hate corrotines, oh well :)

function recharge()
	while true do
	wait(cooldownTime)
	if down==false then
	--if equiped==true then
	if overheated == false then
		if Charge.Value>0 then
		Charge.Value=Charge.Value-2--+math.random(1, 3) --not needed imo
		check()
		end
	end
	--end
	end
	end
end

thread=coroutine.create(recharge)
assert(coroutine.resume(thread))

function onChargeChanged()
if Charge.Value >= MaxCharge then
Charge.Value = 100
overheated = true
	for i = 1, MaxCharge do
	wait(overheattime/MaxCharge)
	Charge.Value = Charge.Value - 1
	if player.PlayerGui:findFirstChild("GunGui") ~= nil and equiped == true then
	player.PlayerGui.GunGui.Back.Status.Text = "OVERHEATED"
	player.PlayerGui.GunGui.Back.Frame.BackgroundColor3 = Color3.new(256-255, 256-0, 256-0)
	--sp.Name=ToolName.." | "..Charge.Value.."%"
	end
	sp.Overheat.Value = Charge.Value
	check()
	if Charge.Value==0 then
	overheated = false
	if player.PlayerGui:findFirstChild("GunGui") ~= nil and equiped == true then
	player.PlayerGui.GunGui.Back.Status.Text = Charge.Value.."%"
	player.PlayerGui.GunGui.Back.Frame.BackgroundColor3 = Color3.new(256-0, 256-102, 256-255)
	--sp.Name=ToolName.." | "..Charge.Value.."%"
	end
	break
	end
	end
overheated = false
end

if Charge.Value <= 0 then
Charge.Value = 0
	if player.PlayerGui:findFirstChild("GunGui") ~= nil then
	player.PlayerGui.GunGui.Back.Status.Text = Charge.Value.."%"
	player.PlayerGui.GunGui.Back.Frame.BackgroundColor3 = Color3.new(256-0, 256-102, 256-255)
	--sp.Name=ToolName.." | "..Charge.Value.."%"
	end
end

end
sp.Overheat.Changed:connect(onChargeChanged)


function onBatteryChanged()
if batteryLife.Value<=0 then
batteryLife.Value=0
battery=false
player.PlayerGui.GunGui.Battery.Status.Text=tostring(batteryLife.Value)
player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-95, 256-95, 256-95)
player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-95, 256-95, 256-95)
else
player.PlayerGui.GunGui.Battery.Status.Text=tostring(batteryLife.Value)
battery=true
	if batteryLife.Value<=50 and batteryLife.Value>25 then
	player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-218, 256-215, 256-0)
	player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-218, 256-215, 256-0)
	elseif batteryLife.Value<=25 then
	player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-255, 256-0, 256-0)
	player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-255, 256-0, 256-0)
	else
	player.PlayerGui.GunGui.Battery.Status.TextColor3 = Color3.new(256-255, 256-255, 256-255)
	player.PlayerGui.GunGui.Battery.sign.TextColor3 = Color3.new(256-255, 256-255, 256-255)
	end
end
end
sp.Battery.Changed:connect(onBatteryChanged)	
					

function computeDirection(vec)
	local lenSquared = vec.magnitude * vec.magnitude
	local invSqrt = 1 / math.sqrt(lenSquared)
	return Vector3.new(vec.x * invSqrt, vec.y * invSqrt, vec.z * invSqrt)
end

 ------------------------------------------------------------------------------------Raycasting functions
 function raycast(startp, endp, ign)
	local vec=(endp-startp)
	if vec.magnitude<1000 then
	local hit,pos=game.Workspace:FindPartOnRay(Ray.new(startp,vec),ign)
	if hit and pos then
		if hit.Parent.className=="Tool" or hit.Parent.className=="Hat" then
			if hit.Parent.Parent ~= nil then
			if hit.Parent.Parent:findFirstChild("Humanoid")~=nil then
			return hit.Parent, pos
			end
			end
		elseif string.lower(hit.Name)=="glass" then
			local vec=(endp-pos)
			hit,pos=raycast(pos,vec,ign)
		elseif string.lower(hit.Name)=="water" then
			local vec=(endp-pos)
			hit,pos=raycast(pos,vec,ign)
		elseif hit.Transparency==1 or hit.Name=="Bullet" or hit.Name=="BulletTexture" then
			local vec=(endp-pos)
			hit,pos=raycast(pos,vec,hit)
		end
	end
	return hit,pos
	end
	return nil
end
-------------------------------------------------------------------------------






function tagHumanoid(humanoid)
	local plr=game.Players:playerFromCharacter(sp.Parent)
	if plr~=nil then
		local tag=Instance.new("ObjectValue")
		tag.Value=plr
		tag.Name="creator"
		tag.Parent=humanoid
		delay(2,function()
			if tag~=nil then
				tag.Parent=nil
			end
		end)
	end
end

function onKeyDown(key,mouse)
	key=key:lower()
	--[[if key=="r" and not reloading then
		reload(mouse)
	end]]
end

function movecframe(p,pos)
	p.Parent=game.Lighting
	p.Position=pos
	p.Parent=game.Workspace
end


function checkAllyWIJ(killer, victim)
if killer.TeamColor==BrickColor.new("New Yeller") and victim.TeamColor==BrickColor.new("New Yeller") then
	if killer~=victim then
	return false
	else
	return true
	end
else
	if killer ~= victim then
		if killer.TeamColor==BrickColor.new("Bright red") and victim.TeamColor==BrickColor.new("Bright green") then 
		return true
		elseif killer.TeamColor==BrickColor.new("Bright green") and victim.TeamColor==BrickColor.new("Bright red") then
		return true
		elseif killer.TeamColor == victim.TeamColor then
		return true
		else
		return false
		end
		return false
	else
	return true
	end
	return false
end
end

function takeDamage(dm, pl)
if pl:findFirstChild("Shield")~=nil then
sh=pl:findFirstChild("Shield")
	if sh.Value==0 then
	pl.Humanoid:TakeDamage(dm)
	elseif sh.Value<dm then
	newdm=dm-sh.Value
	sh.Value=0
	pl.Humanoid:TakeDamage(newdm)
	elseif sh.Value>dm then
	sh.Value=sh.Value-dm
	elseif sh.Value==dm then
	sh.Value=0
	end
else
pl.Humanoid:TakeDamage(dm)
end
end

function fire(aim)
	script.Parent.Handle.Fire.Pitch=(math.random(2,5)/10)+1
	sp.Handle.Fire:Play()

	local bullet=Bullet:clone()
	--[[local bt2=game.Lighting.BulletTexture:clone()
	bt2.BrickColor=BrickColor.new("Bright red")
	bt2.Mesh.Scale=Vector3.new(.5,.5,2)]]--
	local totalDist=0
	Lengthdist=-RayLength/.5
	local startpoint=sp.Handle.CFrame*BarrlePos
	local direction=(aim-startpoint)
	local cfrm=CFrame.new(startpoint, direction+startpoint)
	local vector=startpoint+(direction.Unit*999)
		if (startpoint-vector).magnitude<1000 then
			if game.Workspace:FindPartOnRay(Ray.new(player.Character.Head.Position,startpoint-player.Character.Head.Position),player.Character)==nil then
			local hit,pos=raycast(startpoint,vector,player.Character)
			bullet.Parent=game.Workspace
			--bt2.Parent=game.Workspace
			if hit~=nil then
				if hit.Parent:FindFirstChild("VecHealth")~=nil then
				vech=hit.Parent:FindFirstChild("VecHealth")
				vech.Value=vech.Value-VehicleDamage
				end
				if hit.Parent:FindFirstChild("HealthStatus")~=nil then
				fo=hit.Parent:FindFirstChild("HealthStatus")
				fo.Value=fo.Value-BaseDamage
				end
				local humanoid=hit.Parent:FindFirstChild("Humanoid")
				if humanoid~=nil then
					local damage=math.random(BaseDamage-(BaseDamage*.25),BaseDamage+(BaseDamage*.25))
					if hit.Name=="Head" then
						damage=damage*1.25
					elseif hit.Name=="Torso" then
					else
						damage=damage*.75
					end
					if humanoid.Health>0 then
						local eplr=game.Players:playerFromCharacter(humanoid.Parent)
						local plr=game.Players:playerFromCharacter(sp.Parent)
						if eplr~=nil and plr~=nil then
						if (checkAllyWIJ(plr, eplr)==false) then
								if hit.Parent:findFirstChild("ForceField")==nil then
								tagHumanoid(humanoid)
								takeDamage(damage, humanoid.Parent)
								sX=sfx:clone()
								sX.Parent=player
								sX:play()
								end
						end
						else
							if hit.Parent:findFirstChild("ForceField")==nil then
							tagHumanoid(humanoid)
							takeDamage(damage, humanoid.Parent)
							sX=sfx:clone()
							sX.Parent=player
							sX:play()
							end
						end
					end
				end
				distance=(startpoint-pos).magnitude
				bullet.CFrame=cfrm*CFrame.new(0,0,-distance/2)
				bullet.Mesh.Scale=Vector3.new(.15,.15,distance)
			else
				bullet.CFrame=cfrm*CFrame.new(0,0,-RayLength/2) 
				bullet.Mesh.Scale=Vector3.new(.15,.15,RayLength)
			end
			if pos~=nil then
				--bt2.CFrame=bullet.CFrame
				--movecframe(bt2,pos)
			end
			local deb=game:FindFirstChild("Debris")
			if deb==nil then
				local debris=Instance.new("Debris")
				debris.Parent=game
			end
			check()
			game.Debris:AddItem(bullet,.05)
			game.Debris:AddItem(sX, 1)
			--game.Debris:AddItem(bt2,.5)
		end
	end
end

function onButton1Up(mouse)
	down=false
end

function onButton1Down(mouse)
	h=sp.Parent:FindFirstChild("Humanoid")
	if not enabled or reloading or down or h==nil then
		return
	end
	if Charge.Value<MaxCharge and h.Health>0 and overheated==false and battery==true then
		--[[if sp.Ammo.Value<=0 then
			if not reloading then
				reload(mouse)
			end
			return
		end]]
		down=true
		enabled=false
		while down do
			if Charge.Value>=MaxCharge or sp.Parent:FindFirstChild("Humanoid")==nil or overheated == true then
				break
			end
			sfd=sfd+1
			if sfd>=shotsForDepl then
			sfd=0
			batteryLife.Value=batteryLife.Value-math.random(minDepletion, maxDepletion)
			end
			if burst then
				local startpoint=sp.Handle.CFrame*BarrlePos
				local mag=(mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag))
				fire(mouse.Hit.p+rndm)
				Charge.Value=Charge.Value+math.random(chargeperfireMIN, chargeperfireMAX)
				if Charge.Value>=MaxCharge then
					break
				end
				wait(.05)
				local startpoint=sp.Handle.CFrame*BarrlePos
				local mag2=((mouse.Hit.p+rndm)-startpoint).magnitude
				local rndm2=Vector3.new(math.random(-(.1/10)*mag2,(.1/10)*mag2),math.random(-(.1/10)*mag2,(.1/10)*mag2),math.random(-(.1/10)*mag2,(.1/10)*mag2))
				fire(mouse.Hit.p+rndm+rndm2)
				Charge.Value=Charge.Value+math.random(chargeperfireMIN, chargeperfireMAX)
				if Charge.Value>=MaxCharge then
					break
				end
				wait(.05)
				fire(mouse.Hit.p+rndm+rndm2+rndm2)
				Charge.Value=Charge.Value+math.random(chargeperfireMIN, chargeperfireMAX)
			elseif shot then
				Charge.Value=Charge.Value+math.random(chargeperfireMIN, chargeperfireMAX)
				local startpoint=sp.Handle.CFrame*BarrlePos
				local mag=(mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag))
				fire(mouse.Hit.p+rndm)
				local mag2=((mouse.Hit.p+rndm)-startpoint).magnitude
				local rndm2=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2))
				fire(mouse.Hit.p+rndm+rndm2)
				local rndm3=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2))
				fire(mouse.Hit.p+rndm+rndm3)
				local rndm4=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2))
				fire(mouse.Hit.p+rndm+rndm4)
			else
				Charge.Value=Charge.Value+math.random(chargeperfireMIN, chargeperfireMAX)
				local startpoint=sp.Handle.CFrame*BarrlePos
				local mag=(mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag))
				fire(mouse.Hit.p+rndm)
			end
			wait(Firerate)
			if not automatic or battery==false then
				break
			end
		end	
		enabled=true
	else
		sp.Handle.Trigger:Play()
	end
end

function onEquippedLocal(mouse)
	if mouse==nil then
		print("Mouse not found")
		return 
	end
	script.GunGui:clone().Parent=player.PlayerGui
	mouse.Icon=Cursors[1]
	mouse.KeyDown:connect(function(key) onKeyDown(key,mouse) end)
	mouse.Button1Down:connect(function() onButton1Down(mouse) end)
	mouse.Button1Up:connect(function() onButton1Up(mouse) end)
	equiped=true
	down=false
	reloading=false
	check()
end
function onUnequippedLocal(mouse)
		if player.PlayerGui:FindFirstChild("GunGui")~=nil then
		player.PlayerGui:FindFirstChild("GunGui").Parent=nil	
		end
	equiped=false
	reloading=false
	down=false
	sp.Name = OriginalToolName
end
sp.Equipped:connect(onEquippedLocal)
sp.Unequipped:connect(onUnequippedLocal)
check()