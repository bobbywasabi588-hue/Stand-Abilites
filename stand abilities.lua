local module = {}
local utility = require(game.ServerScriptService:WaitForChild("StandUtility"))
local gbutility = require(game.ServerScriptService:WaitForChild("Utility"))
local remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local damage = require(game.ServerScriptService:WaitForChild("Damage"))
local states = require(game.ServerScriptService:WaitForChild("States"))
local blocking = require(game.ServerScriptService:WaitForChild("Blocking"))
local plrdata = require(game.ServerScriptService:WaitForChild("PlrData"))
local effect = remotes:WaitForChild("EventEffect")
local ts = game:GetService("TweenService")
module.__index = module
function module.new(player, model)
	local char = player.Character
	print("new")
	local self = setmetatable({}, module)
	self.Char = char
	self.Player = player
	self.Model = model
	self.Data = plrdata.GetData(player)
	self.Animator = model:WaitForChild("AnimationController").Animator
	self.Anims = {
		["M1"] = self.Animator:LoadAnimation(game.ReplicatedStorage.Anims.M1s.M1),
		["M2"] = self.Animator:LoadAnimation(game.ReplicatedStorage.Anims.M1s.M2),
		["M3"] = self.Animator:LoadAnimation(game.ReplicatedStorage.Anims.M1s.M3),
		["M4"] = self.Animator:LoadAnimation(game.ReplicatedStorage.Anims.M1s.M4),
		["Barrage"] = self.Animator:LoadAnimation(script.Barrage),
		["Beatdownhit"] = self.Animator:LoadAnimation(script.Beatdownhit),
		["Beatdownfinish"] = self.Animator:LoadAnimation(script.Beatdownfinish),
		["Beatdown"] = self.Animator:LoadAnimation(script.Beatdown),
		["Block"] = self.Animator:LoadAnimation(game.ReplicatedStorage.Anims.Block),
		["Idle"] = self.Animator:LoadAnimation(script.Idle),
		["Walk"] = self.Animator:LoadAnimation(script.Walk),
		["Star Finger"] = self.Animator:LoadAnimation(script["Star Finger"]),
		["TheWorld"] = self.Animator:LoadAnimation(script["TheWorld"]),
		["Uppercut"] = self.Animator:LoadAnimation(script.Uppercut),
		["TheWorldStand"] = self.Animator:LoadAnimation(script["TheWorldStand"]),
		["Hard Right"] = self.Animator:LoadAnimation(script["Hard Right"])
		
	}
	self.Combo = 0
	self.lastm1 = 0
	self.Sounds = {}
	self.Hum = char:WaitForChild("Humanoid")
	
	self.Connections = {}
	local idle = self.Anims.Idle
	idle:Play()
	local walk = self.Anims.Walk
	local currentState = "Idle"
	table.insert(self.Connections, self.Hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if self.Hum.MoveDirection.Magnitude > 0 then
			if currentState ~= "Moving" then
				if not states.GetState(self.Char, "Stunned") then 
				currentState = "Moving"
				walk:Play()
				idle:Stop()
				end
			end
		else
			if currentState ~= "Idle" then
				currentState = "Idle"
				walk:Stop()
				idle:Play()
			end
		end
	end)
	)
	gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.SummonLine, self.Char.HumanoidRootPart, 2)
	gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.SummonSound, self.Char.HumanoidRootPart, 2)
	
	local vfx = game.ReplicatedStorage.Vfx:WaitForChild(script.Name).Summon
	gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfxOnChar", vfx, model, 1)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(0.301961, 0, 0.67451)
	highlight.FillTransparency = 0
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = self.Model
	game.Debris:AddItem(highlight, 1)
	local t = ts:Create(highlight, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FillTransparency = 1}):Play()
	for _, part in pairs(self.Char:GetDescendants()) do
		if part.Name ~= "Right Arm" and part.Name ~= "Left Arm" and part.Name ~= "Right Leg" and part.Name ~= "Left Leg" and part.Name ~= "Head" and part.Name ~= "Torso" then continue end
		
	for i, v in pairs(game.ReplicatedStorage.Vfx["Star Platinum"].Auras:GetChildren()) do
		if not part:FindFirstChild(v.Name) then
			local clone = v:Clone()
			clone.Parent = part
		
		end
		end
	end
	table.insert(self.Connections, self.Char:GetAttributeChangedSignal("Stunned"):Connect(function()
		if self.Char:GetAttribute("Stunned") then
			self:Unblock()
		end
	end))
	print("new2")
	return self
end

function module:M1(animtion)
 
	if not self.Char or not self.Char.Parent then return end
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "M1CD") then return end
	if states.GetState(self.Char, "Blocking") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end

	
	if tick() - self.lastm1 > 1 then
		self.Combo = 0
	end

	self.Combo += 1
	local currentCombo = self.Combo

	print("Combo:", currentCombo)

	
	if currentCombo > 4 then
		self.Combo = 1
		currentCombo = 1
	end
	utility.MoveStand(self.Char, CFrame.new(0,0,-3))

	states.SetAttacking(self.Char, 0.2, 6)
	
	local anim = self.Anims["M"..currentCombo]
	anim.Priority = Enum.AnimationPriority.Action2

	local conn
	conn = anim:GetMarkerReachedSignal("Hit"):Connect(function()
		conn:Disconnect()

		if not self.Char or not self.Char.Parent then return end
local swing = game.ReplicatedStorage.Sounds.punchswing
gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", swing, self.Char.HumanoidRootPart, 1)
		

		if currentCombo == 4 then
			
			states.SetState(self.Char, "M1CD", 0.5)

			local hit = damage.Hitbox(
				self.Char,
				self.Char.HumanoidRootPart.CFrame * CFrame.new(0,0,-3),
				Vector3.new(5,5,5),
				"Star Platinum",
				"LastM1"
			)
			if #hit > 0 then
				for i, char in pairs(hit) do
					gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfx", game.ReplicatedStorage.Vfx.HitVfx, char.Torso.CFrame, 0.5)
					gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfxOnChar", game.ReplicatedStorage.Vfx.lastm1, char, 1)
					damage.DamageAndStun(self.Char, 30 * (1 + (self.Data.Stats["Destructive Power"] * 0.025)), char, 0.4, 26, 0.5)
				end
				gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", game.ReplicatedStorage.Sounds.lastm1, self.Char.HumanoidRootPart, 1)
			end
		else
			states.SetState(self.Char, "M1CD", 0.2)

			local hit = damage.Hitbox(
				self.Char,
				self.Char.HumanoidRootPart.CFrame * CFrame.new(0,0,-3),
				Vector3.new(7,5,5),
				"Star Platinum",
				"M1"
			)
			
			if #hit > 0 then
				for i, char in pairs(hit) do
					gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfx", game.ReplicatedStorage.Vfx.HitVfx, char.Torso.CFrame, 0.5)
					damage.DamageAndStun(self.Char, 25 * (1 + (self.Data.Stats["Destructive Power"] * 0.025)), char, 0.25, false, false, 8)
				end
				gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", game.ReplicatedStorage.Sounds.m1hit, self.Char.HumanoidRootPart, 1)

			end
		end
	end)

	anim:Play()


	if self.Combo >= 4 then
		self.Combo = 0
	end


	task.delay(0.6, function()
		if not states.GetState(self.Char, "Attacking")  then
			utility.MoveStand(self.Char, CFrame.new(-2,1,2))
		end
	end)


	self.lastm1 = tick()
end

function module:E()
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "EMoveCD") then return end
	if states.GetState(self.Char, "Blocking") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end

	utility.MoveStand(self.Char, CFrame.new(0,0,-3))
	states.SetState(self.Char, "Barraging", 3)
	states.SetAttacking(self.Char, 3, 6)
	states.SetState(self.Char, "EMoveCD", 13)
	states.SetState(self.Char, "DoingBarrage", 3.3)

	local arms = {"Right Arm", "Left Arm"}


	task.delay(0.15, function()
		gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfxOnChar", game.ReplicatedStorage.Vfx["Star Platinum"].Barrage, self.Char, 3, CFrame.new(0,0,-6))

	local anim = self.Anims["Barrage"]
	anim:Play()
		gbutility.FireClientsInRadius(self.Char, effect, "Stand", "ArmBarrage", self.Model)
		local sound = script.BarrageSound:Clone()
		sound.Parent = self.Model.HumanoidRootPart
		sound:Play()
		game.Debris:AddItem(sound, 6)
		self.Sounds["Barrage"] = sound
		
	repeat
		local hit = damage.Hitbox(self.Char, self.Char.HumanoidRootPart.CFrame * CFrame.new(0,0,-5), Vector3.new(5,5,7), "Star Platinum", "Barrage")
		if #hit > 0 then
			local sound = game.ReplicatedStorage.Sounds.Barrage:Clone()
			sound.Parent = self.Model.HumanoidRootPart
			sound:Play()
			game.Debris:AddItem(sound, 0.3)
		end
		for i, char in pairs(hit) do
				damage.DamageAndStun(self.Char, 4 * (1 + (self.Data.Stats["Destructive Power"] * 0.025)), char, 0.5, false, false, 1)
				gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfxOnChar", game.ReplicatedStorage.Vfx["Star Platinum"].BarrageHit, char, 0.5)
		end
		task.wait(0.12)
	until not self.Char or self.Hum.Health <= 0 or states.GetState(self.Char, "Stunned") or not states.GetState(self.Char, "Barraging") 
	self:EEnd()
	states.RemoveState(self.Char, "Attacking")
		task.wait(0.5)
		if not states.GetState(self.Char, "Attacking") then
			utility.MoveStand(self.Char, CFrame.new(-2,1,2))
		end
		states.RemoveState(self.Char, "Attacking")
	end)
end

function module:T()
	print("starfinger")
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "TMoveCD") then return end
	if states.GetState(self.Char, "Blocking") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end
	
	utility.MoveStand(self.Char, CFrame.new(0,0,-3))
	states.SetAttacking(self.Char, 1, 6)
	states.SetState(self.Char, "TMoveCD", 8)

	local anim = self.Anims["Star Finger"] 
	anim:Play()
	gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.StarFingerLine, self.Model.HumanoidRootPart, 3)
	task.wait(0.55)
	if not self.Char or self.Char.Humanoid.Health <= 0 or states.GetState(self.Char, "Stunned") then return end

	gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.StarFingerSound, self.Model.HumanoidRootPart, 3)
	gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfx", game.ReplicatedStorage.Vfx["Star Platinum"].StarFinger, self.Char["Torso"].CFrame * CFrame.new(0,0,-8), 2)
	local hit = damage.Hitbox(self.Char, self.Char.HumanoidRootPart.CFrame * CFrame.new(0,0,-6), Vector3.new(2,2,12), "Star Platinum", "Star Finger")
	for i, char in pairs(hit) do
		damage.DamageAndStun(self.Char, 95 * (1 + (self.Data.Stats["Destructive Power"] * 0.025)), char, 0.5)
	end
	if #hit > 0 then
		gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", game.ReplicatedStorage.Sounds.StarFingerHit, self.Model.HumanoidRootPart, 3)
	end
	task.wait(0.5)
		if states.GetState(self.Char, "Attacking") then return end
		utility.MoveStand(self.Char, CFrame.new(-2,1,2))
	
end

function module:R()
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "RMoveCD") then return end
	if states.GetState(self.Char, "Blocking") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end

	utility.MoveStand(self.Char, CFrame.new(0,0,-3))
	states.SetAttacking(self.Char, 0.75, 6)

	states.SetState(self.Char, "RMoveCD", 1)

	local anim = self.Anims["Hard Right"]

	gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.Ora, self.Model.HumanoidRootPart, 3)
	local conn
	 conn = anim:GetMarkerReachedSignal("Hit"):Connect(function()
		if not self.Char or self.Char.Humanoid.Health <= 0 or states.GetState(self.Char, "Stunned") then return end
		print("hit")
		local hit = damage.Hitbox(self.Char, self.Char.HumanoidRootPart.CFrame * CFrame.new(0,0,-3), Vector3.new(5,5,5), "Star Platinum", "Ora")
		for i, char in pairs(hit) do
			print(char)
			damage.DamageAndStun(self.Char, 94 * (1 + (self.Data.Stats["Destructive Power"] * 0.025)), char, 0.5, 27, 0.5)
			gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfx", game.ReplicatedStorage.Vfx["Star Platinum"].OraHit, char.Torso.CFrame, 2)
			local player = game.Players:GetPlayerFromCharacter(char)
			if player then
				remotes.CameraShake:FireClient(player,  3, 3)
			end
		end
		if #hit > 0 then
			gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.OraHit, self.Model.HumanoidRootPart, 2)
			gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.Heavyhit, self.Model.HumanoidRootPart, 2)
			local player = game.Players:GetPlayerFromCharacter(self.Char)
			if player then
				remotes.CameraShake:FireClient(player,  3, 3)
			end
		end
		conn:Disconnect()
	end)
	anim:Play()
	
	task.wait(0.75)
	if states.GetState(self.Char, "Attacking") then return end
	utility.MoveStand(self.Char, CFrame.new(-2,1,2))

end

function module:EEnd()
	states.RemoveState(self.Char, "Barraging")

	if self.Anims["Barrage"] then
	self.Anims["Barrage"]:Stop()
	end
	
	if self.Sounds["Barrage"] then
	self.Sounds["Barrage"]:Destroy()
	self.Sounds["Barrage"] = nil
	end
	
	for i, v in pairs(self.Model["Right Arm"]:GetChildren()) do
	 if v and v:IsA("Trail") or v:IsA("Attachment") then
		v:Destroy()
	 end
	end
	
	for i, v in pairs(self.Model["Left Arm"]:GetChildren()) do
	 if v and v:IsA("Trail") or v:IsA("Attachment") then
		v:Destroy()
	 end
	end
	remotes.EventEffect:FireAllClients("Global", "DestroyVfxOnChar", self.Char, "Barrage")
end

function module:V() 
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "VMoveCD") then return end
	if states.GetState(self.Char, "Blocking") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end

	states.SetState(self.Char, "VMoveCD", 12)
	local originHRP = self.Char:FindFirstChild("HumanoidRootPart")
	if not originHRP then return end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self.Char}

	local parts = workspace:GetPartBoundsInRadius(originHRP.Position, 15, params)

	local closestChar = nil
	local closestDistance = math.huge
	local seen = {}
	for _, part in pairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")

		if model 
			and model ~= self.Char 
			and model:FindFirstChild("Humanoid") 
			and not seen[model] then

			seen[model] = true

			local hrp = model:FindFirstChild("HumanoidRootPart")
			if hrp and model.Humanoid.Health > 0 then
				local dist = (hrp.Position - originHRP.Position).Magnitude

				if dist < closestDistance then
					closestDistance = dist
					closestChar = model
				end
			end
		end
	end

	if closestChar then
		local targetHRP = closestChar:FindFirstChild("HumanoidRootPart")
		local hum = self.Char:FindFirstChild("Humanoid")
		
		if targetHRP and hum then
			local behindPos = targetHRP.Position - targetHRP.CFrame.LookVector * 3.5
			local lookCF = CFrame.lookAt(behindPos, targetHRP.Position)
			
			self.Char:PivotTo(lookCF)
			local plr = game.Players:GetPlayerFromCharacter(self.Char)
			if plr then
			hum.AutoRotate = false
			task.delay(0.1, function()
				hum.AutoRotate = true
			end)
				remotes.EventEffect:FireClient(plr, "Global", "PlaySoundSoundService", game.SoundService.minitimestop )
			remotes.EventEffect:FireClient(plr, "Star Platinum", "Teleport", targetHRP.CFrame)
			remotes.EventEffect:FireClient(plr, "Star Platinum", "Teleportfx")
			remotes.CameraShake:FireClient(plr, 1,7)
			end
			local enemyplr = game.Players:GetPlayerFromCharacter(closestChar)
			if enemyplr then
				remotes.EventEffect:FireClient(enemyplr, "Global", "PlaySoundSoundService", game.SoundService.minitimestop )
				remotes.EventEffect:FireClient(enemyplr, "Star Platinum", "Teleportfx")
				remotes.CameraShake:FireClient(enemyplr, 1,7)
				end
		end
	end
end

function module:C() 
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "CMoveCD") then return end
	if states.GetState(self.Char, "Blocking") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end

	local hum = self.Char:FindFirstChild("Humanoid")
	if not hum then return end
	states.SetState(self.Char, "CMoveCD", 60)
	states.SetAttacking(self.Char, 1, 5)
	
	local anim2 = self.Anims.TheWorld
	anim2:Play()
	
	task.delay(1, function()
		anim2:Stop()
	end)
	local plrs = {}
	local chars = {}
	
	local originHRP = self.Char:FindFirstChild("HumanoidRootPart")
	if not originHRP then return end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self.Char}

	local parts = workspace:GetPartBoundsInRadius(originHRP.Position, 40, params)
	for i, part in pairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChild("Humanoid") and not table.find(chars, model) then
			table.insert(chars, model)
			local enemyplr = game.Players:GetPlayerFromCharacter(model)
			if enemyplr and not table.find(plrs, enemyplr) then
				table.insert(plrs, enemyplr)
			end
		end
	end
	local sound = game.SoundService.theworldline:Clone()
	sound.Parent = self.Char.HumanoidRootPart
	sound:Play()
	game.Debris:AddItem(sound, 4)
	table.insert(plrs, game.Players:GetPlayerFromCharacter(self.Char))

	
	for i, v in pairs(chars) do
		print("Timestopped", v.Name)
		if states.GetState(v, "Attacking") then
			print("attacking")
		end
	
		
		states.SetStun(v, 4, 0, 0)
		local root = v:FindFirstChild("HumanoidRootPart")
		local enemyhum = v:FindFirstChild("Humanoid")
		if enemyhum and root then
			states.SetState(v, "Timestopped", 4)
			enemyhum.WalkSpeed = 0
			enemyhum.JumpPower = 0
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		end
	for i, v in pairs(plrs) do
		remotes.EventEffect:FireClient(v, "Star Platinum", "TheWorld")
	end
	task.delay(4, function()
		for i, v in pairs(chars) do
		v.HumanoidRootPart.Anchored = false
		end
		gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.timeresume, self.Char.HumanoidRootPart, 3)
		gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.timeresumeline, self.Char.HumanoidRootPart, 3)
	end)
task.delay(1, function()
	gbutility.FireClientsInRadius(self.Char, effect, "Global", "PlaySound", script.clocktick, self.Char.HumanoidRootPart, 3)
end)
end

function module:Block()
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "BlockCD") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end
	blocking.Block(self.Char)
	local anim = self.Animator:LoadAnimation(game.ReplicatedStorage.Anims:WaitForChild("Block"))
	anim:Play()
	self.Anims["Block"] = anim
	utility.MoveStand(self.Char, CFrame.new(0,0,-3))
end

function module:Unblock()
	blocking.Unblock(self.Char)
	if self.Anims["Block"] then
		self.Anims["Block"]:Stop()
	end
	if not states.GetState(self.Char, "Attacking") then
		utility.MoveStand(self.Char, CFrame.new(-2,1,2))
	end
end


function module:X() 
	if states.GetState(self.Char, "Stunned") then return end
	if states.GetState(self.Char, "Attacking") then return end
	if states.GetState(self.Char, "XMoveCD") then return end
	if states.GetState(self.Char, "Blocking") then return end
	if not self.Char:GetAttribute("StandEquipped") then return end

	states.SetState(self.Char, "XMoveCD", 20)
	states.SetState(self.Char, "Attacking", 0.5)

	utility.MoveStand(self.Char, CFrame.new(0,0,-3))
	local anim = self.Anims.Uppercut
	local conn
	 conn = anim:GetMarkerReachedSignal("Hit"):Connect(function()
		if not self.Char or self.Char.Humanoid.Health <= 0 or states.GetState(self.Char, "Stunned") then return end
		local hit = damage.Hitbox(self.Char, self.Char.HumanoidRootPart.CFrame * CFrame.new(0,0,-3), Vector3.new(5,5,5), "Star Platinum", "Beatdown")
		task.spawn(function()
		if hit and #hit > 0 then
				local player = game.Players:GetPlayerFromCharacter(self.Char)
				if player then
					remotes.CameraShake:FireClient(player,  2, 3)
					task.delay(3.3, function()
						local player = game.Players:GetPlayerFromCharacter(self.Char)
						if player then
							remotes.CameraShake:FireClient(player,  2, 3)
						end
					end)
				end
				states.SetState(self.Char, "IFRAMES", 4)
			states.RemoveState(self.Char, "Attacking")
				states.SetAttacking(self.Char, 4, 0)
			gbutility.FireClientsInRadius(self.Char, effect, "Star Platinum", "Beatdown", self.Char)
			local beatdownanim = self.Anims.Beatdown
			task.wait(0.5)
				utility.MoveStand(self.Char, CFrame.new(0,0,-3) * CFrame.Angles(math.rad(35),0,0))
			self.Char:SetAttribute("Barraging", true)
				gbutility.FireClientsInRadius(self.Char, effect, "Stand", "ArmBarrage", self.Model)
			beatdownanim:Play()
			task.wait(2.5)
			utility.MoveStand(self.Char, CFrame.new(0,0,-3) * CFrame.Angles(0,0,0))
			states.RemoveState(self.Char, "Barraging")
			beatdownanim:Stop()
			local finish = self.Animator:LoadAnimation(script.Beatdownfinish)
			finish:Play()
				task.wait(1.5)
				if states.GetState(self.Char, "Attacking") then return end
				utility.MoveStand(self.Char, CFrame.new(-2,1,2))
		end
		end)
		for _, char in pairs(hit) do
			states.SetStun(char, 4, 0, 0)
			states.SetState(char, "IFRAMES", 4)
			local hitanim = char:FindFirstChild("Humanoid").Animator:LoadAnimation(script.Beatdownhit)
			hitanim:Play()
			local player = game.Players:GetPlayerFromCharacter(char)
			if player then
				remotes.CameraShake:FireClient(player,  2, 3)
				task.delay(3.3, function()
					local player = game.Players:GetPlayerFromCharacter(char)
					if player then
						remotes.CameraShake:FireClient(player,  2, 3)
					end
				end)
			end
			gbutility.FireClientsInRadius(self.Char, effect, "Star Platinum", "Beatdownhit", char)
			local attackerRoot = self.Char.HumanoidRootPart
			local targetRoot = char.HumanoidRootPart
			
			local frontPos = attackerRoot.Position + attackerRoot.CFrame.LookVector * 5
			targetRoot.CFrame = CFrame.lookAt(frontPos , attackerRoot.Position)
			local att0 = Instance.new("Attachment")
			att0.Parent = targetRoot

			local att1 = Instance.new("Attachment")
			att1.Parent = attackerRoot
			att1.Position = Vector3.new(0, 0, -5)

			local alignPos = Instance.new("AlignPosition")
			alignPos.Attachment0 = att0
			alignPos.Attachment1 = att1
			alignPos.RigidityEnabled = true
			alignPos.Responsiveness = 200
			alignPos.MaxForce = 50000
			alignPos.Parent = targetRoot

			local alignOri = Instance.new("AlignOrientation")
			alignOri.Attachment0 = att0
			alignOri.Attachment1 = att1
			alignOri.RigidityEnabled = true
			alignOri.Responsiveness = 200
			alignOri.MaxTorque = 50000
			alignOri.Parent = targetRoot
			print("Weld created")
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				hum.AutoRotate = false
				
			end
			
			task.spawn(function()
				for i = 1, 17 do
					if not self.Char or self.Char.Humanoid.Health <= 0 or states.GetState(self.Char, "Stunned") then return end

					local hum = char:FindFirstChild("Humanoid")

					if not hum or hum.Health <= 0 then
						break
					end

					if not char.Parent then
						break
					end

					damage.DamageAndStun(
						self.Char,
						6 * (1 + (self.Data.Stats["Destructive Power"] * 0.025)),
						char,
						false,
						false,
						false,
						false,
						true
					)

					task.wait(0.15)
				end
			end)
			task.delay(3, function()
				hitanim:Stop()
				wait(0.30)
				local hum = char:FindFirstChild("Humanoid")
				if alignPos then
					alignPos:Destroy()
				end

				if alignOri then
					alignOri:Destroy()
				end

				if att0 then
					att0:Destroy()
				end

				if att1 then
					att1:Destroy()
				end
				if hum then
					hum.AutoRotate = true
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				end
				local player = game.Players:GetPlayerFromCharacter(char)
				if player then
					remotes.CameraShake:FireClient(player,  2, 3)
				end
				damage.DamageAndStun(self.Char, 22 * (1 + (self.Data.Stats["Destructive Power"] * 0.025)), char, 0.5, 30, 0.5)
				task.delay(1, function()
					if hum then
						hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
						hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
					end
				end)
			end)	
		end
		conn:Disconnect()
	end)
	anim:Play()
	task.wait(0.6)
	if states.GetState(self.Char, "Attacking") then return end
	utility.MoveStand(self.Char, CFrame.new(-2,1,2))
end

function module:Unequip()
	for i, v in pairs(self.Char:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
			v.Transparency = NumberSequence.new(1)
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(0.301961, 0, 0.67451)


	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = self.Model

	game.Debris:AddItem(highlight, 1)
	local t = ts:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FillTransparency = 0}):Play()
	task.wait(0.2)
	for i, v in pairs(self.Model:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Decal") or v:IsA("Texture") then
			print(v.Name)
			v.Transparency = 1
		end
	end
end

function module:Equip()
	for i, v in pairs(self.Model:GetDescendants()) do
		if v.Name == "HumanoidRootPart" then continue end
		if v:IsA("BasePart")  or v:IsA("MeshPart") or v:IsA("Decal") or v:IsA("Texture") then
			
			v.Transparency = 0
		end
	end
	for i, v in pairs(self.Char:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
			v.Transparency = NumberSequence.new(0,1)

		end
	end
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(0.301961, 0, 0.67451)
	local char = self.Char
	local model = self.Model
	gbutility.FireClientsInRadius(char, effect, "Global", "PlaySound", script.SummonSound, char.HumanoidRootPart, 2)
	gbutility.FireClientsInRadius(char, effect, "Global", "PlaySound", script.SummonLine, char.HumanoidRootPart, 2)

	highlight.FillTransparency = 0
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = self.Model
	local vfx = game.ReplicatedStorage.Vfx:WaitForChild(script.Name).Summon
	gbutility.FireClientsInRadius(self.Char, effect, "Global", "SpawnVfxOnChar", vfx, model, 1)
	game.Debris:AddItem(highlight, 1)
	local t = ts:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FillTransparency = 1}):Play()
	utility.MoveStand(self.Char, CFrame.new(-2,1,2))
end


return module
