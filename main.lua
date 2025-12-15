--====================================================--
-- Fractured Realms - Minion Aura + Movement UI
-- COPY & PASTE VERSION
--====================================================--

--====================--
-- SERVICES
--====================--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local Client = Players.LocalPlayer

--====================--
-- GLOBAL DEFAULTS
--====================--
getgenv().KillAura = getgenv().KillAura or false
getgenv().AuraRange = getgenv().AuraRange or 50
getgenv().HitAmount = getgenv().HitAmount or 5
getgenv().AutoSwitchTarget = getgenv().AutoSwitchTarget or false
getgenv().SwitchInterval = getgenv().SwitchInterval or 3
getgenv().InfinityFollowerHP = getgenv().InfinityFollowerHP or false
getgenv().ToggleKey = getgenv().ToggleKey or Enum.KeyCode.K

-- Movement
getgenv().UseCustomMovement = getgenv().UseCustomMovement or false
getgenv().WalkSpeed = getgenv().WalkSpeed or 16
getgenv().JumpPower = getgenv().JumpPower or 50

local AuraTarget = nil
local LastSwitchTime = 0

--====================--
-- ENEMY DEAD CHECK
--====================--
local function IsEnemyDead(enemy)
	if not enemy or not enemy.Parent then return true end
	local hum = enemy:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return true end
	if enemy:GetAttribute("Dead") == true then return true end
	return false
end

--====================--
-- GET ALL ENEMIES
--====================--
local function GetAllEnemies()
	local enemies = {}

	local npcFolder = workspace:FindFirstChild("NPCS")
	local followerFolder = workspace:FindFirstChild("Player_Followers")

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if Players:GetPlayerFromCharacter(obj) then continue end
				if npcFolder and obj:IsDescendantOf(npcFolder) then continue end
				if followerFolder and obj:IsDescendantOf(followerFolder) then continue end
				table.insert(enemies, obj)
			end
		end
	end

	return enemies
end

--====================--
-- NEAREST ENEMY
--====================--
local function GetNearestEnemy()
	local char = Client.Character
	if not char then return nil end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest, closest = nil, math.huge

	for _, enemy in ipairs(GetAllEnemies()) do
		local hum = enemy:FindFirstChildOfClass("Humanoid")
		local hrp = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
		if hum and hrp then
			local dist = (hrp.Position - root.Position).Magnitude
			if dist <= getgenv().AuraRange and dist < closest then
				closest = dist
				nearest = enemy
			end
		end
	end

	return nearest
end

--====================--
-- COMMAND FOLLOWERS
--====================--
local function CommandFollowers(enemy)
	if not enemy then return end
	for i = 1, getgenv().HitAmount do
		RS.Remotes.FollowerAttack.AssignTarget:FireServer(enemy, true)
	end
end

--====================--
-- INFINITY FOLLOWER HP
--====================--
task.spawn(function()
	while true do
		if getgenv().InfinityFollowerHP then
			local pf = workspace:FindFirstChild("Player_Followers")
			if pf then
				local my = pf:FindFirstChild(Client.Name .. "_Followers")
				if my then
					for _, minion in ipairs(my:GetChildren()) do
						local hum = minion:FindFirstChildOfClass("Humanoid")
						if hum then
							hum.Health = hum.MaxHealth
						end
					end
				end
			end
		end
		task.wait(0.2)
	end
end)

--====================--
-- MOVEMENT LOOP
--====================--
task.spawn(function()
	while true do
		if getgenv().UseCustomMovement then
			local char = Client.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = getgenv().WalkSpeed
					hum.JumpPower = getgenv().JumpPower
				end
			end
		end
		task.wait(0.2)
	end
end)

--====================--
-- KEY TOGGLE
--====================--
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == getgenv().ToggleKey then
		getgenv().KillAura = not getgenv().KillAura
		AuraTarget = nil
		LastSwitchTime = tick()
	end
end)

--====================--
-- UI (RAYFIELD)
--====================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Minion Aura",
	ToggleUIKeybind = "K",
})

-- COMBAT
local CombatTab = Window:CreateTab("Combat", "swords")

CombatTab:CreateToggle({
	Name = "Kill Aura",
	CurrentValue = getgenv().KillAura,
	Callback = function(v)
		getgenv().KillAura = v
		AuraTarget = nil
		LastSwitchTime = tick()
	end,
})

CombatTab:CreateSlider({
	Name = "Aura Range",
	Range = {5, 200},
	Increment = 1,
	CurrentValue = getgenv().AuraRange,
	Callback = function(v) getgenv().AuraRange = v end,
})

CombatTab:CreateToggle({
	Name = "Auto Switch Target",
	CurrentValue = getgenv().AutoSwitchTarget,
	Callback = function(v) getgenv().AutoSwitchTarget = v end,
})

CombatTab:CreateSlider({
	Name = "Switch Interval (Sec)",
	Range = {1, 10},
	Increment = 0.5,
	CurrentValue = getgenv().SwitchInterval,
	Callback = function(v) getgenv().SwitchInterval = v end,
})

-- FOLLOWERS
local FollowerTab = Window:CreateTab("Followers", "users")

FollowerTab:CreateSlider({
	Name = "Hit Amount",
	Range = {1, 20},
	Increment = 1,
	CurrentValue = getgenv().HitAmount,
	Callback = function(v) getgenv().HitAmount = v end,
})

FollowerTab:CreateToggle({
	Name = "Infinity Follower HP",
	CurrentValue = getgenv().InfinityFollowerHP,
	Callback = function(v) getgenv().InfinityFollowerHP = v end,
})

-- MOVEMENT
local MoveTab = Window:CreateTab("Movement", "activity")

MoveTab:CreateToggle({
	Name = "Custom Movement",
	CurrentValue = getgenv().UseCustomMovement,
	Callback = function(v) getgenv().UseCustomMovement = v end,
})

MoveTab:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 150},
	Increment = 1,
	CurrentValue = getgenv().WalkSpeed,
	Callback = function(v) getgenv().WalkSpeed = v end,
})

MoveTab:CreateSlider({
	Name = "Jump Power",
	Range = {50, 300},
	Increment = 5,
	CurrentValue = getgenv().JumpPower,
	Callback = function(v) getgenv().JumpPower = v end,
})

--====================--
-- MAIN LOOP
--====================--
task.spawn(function()
	while true do
		if getgenv().KillAura then
			local now = tick()

			if IsEnemyDead(AuraTarget) then
				AuraTarget = GetNearestEnemy()
				LastSwitchTime = now
			end

			if getgenv().AutoSwitchTarget and AuraTarget then
				if now - LastSwitchTime >= getgenv().SwitchInterval then
					AuraTarget = GetNearestEnemy()
					LastSwitchTime = now
				end
			end

			if AuraTarget then
				CommandFollowers(AuraTarget)
			end
		end
		task.wait(0.1)
	end
end)
