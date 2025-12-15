--====================================================--
-- Fractured Realms - Stable Minion Kill Aura
--====================================================--

--====================--
-- SERVICES
--====================--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Client = Players.LocalPlayer

--====================--
-- CONFIG
--====================--
getgenv().AuraRange = 20
getgenv().HitAmount = 5
getgenv().KillAura = false

getgenv().InfinityFollowerHP = false

getgenv().SpeedHack = false
getgenv().PlayerSpeed = 24

getgenv().JumpHack = false
getgenv().JumpPower = 70

getgenv().KillAuraKey = Enum.KeyCode.Q

--====================--
-- STATE
--====================--
local AuraTarget = nil

--====================--
-- UTILS
--====================--
local function IsInNPCFolder(model)
	local npc = workspace:FindFirstChild("NPCS")
	return npc and model:IsDescendantOf(npc)
end

local function IsEnemyDead(enemy)
	if not enemy or not enemy.Parent then return true end
	local hum = enemy:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return true end
	if enemy:GetAttribute("Dead") == true then return true end
	return false
end

--====================--
-- COLLECT ENEMIES
--====================--
local function GetAllEnemies()
	local list = {}

	local function scan(container)
		if not container then return end
		for _, obj in ipairs(container:GetDescendants()) do
			if obj:IsA("Model")
				and obj:FindFirstChildOfClass("Humanoid")
				and not IsInNPCFolder(obj)
			then
				table.insert(list, obj)
			end
		end
	end

	scan(workspace:FindFirstChild("ClickCoins"))
	scan(workspace:FindFirstChild("Dungeons"))

	local inf = workspace:FindFirstChild("INFINITE_DUNGEON")
	if inf then
		local m = inf:FindFirstChild("infinite_Dungeon")
		if m then scan(m:FindFirstChild("Bosses")) end
	end

	scan(workspace:FindFirstChild("Seraphim_Fight"))
	scan(workspace:FindFirstChild("Scarab"))
	scan(workspace:FindFirstChild("Sentinel"))

	return list
end

--====================--
-- FIND NEAREST ENEMY
--====================--
local function GetNearestEnemy()
	local char = Client.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest, minDist = nil, math.huge

	for _, enemy in ipairs(GetAllEnemies()) do
		local hum = enemy:FindFirstChildOfClass("Humanoid")
		local hrp = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
		if hum and hrp and hum.Health > 0 then
			local d = (hrp.Position - root.Position).Magnitude
			if d <= getgenv().AuraRange and d < minDist then
				minDist = d
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
	local remote = RS.Remotes.FollowerAttack.AssignTarget
	for i = 1, getgenv().HitAmount do
		remote:FireServer(enemy, true)
	end
end

--====================--
-- FOLLOWER HP
--====================--
task.spawn(function()
	while true do
		if getgenv().InfinityFollowerHP then
			local pf = workspace:FindFirstChild("Player_Followers")
			if pf then
				local my = pf:FindFirstChild(Client.Name .. "_Followers")
				if my then
					for _, m in ipairs(my:GetChildren()) do
						local hum = m:FindFirstChildOfClass("Humanoid")
						if hum then hum.Health = hum.MaxHealth end
					end
				end
			end
		end
		task.wait(0.2)
	end
end)

--====================--
-- PLAYER SPEED & JUMP
--====================--
task.spawn(function()
	while true do
		local char = Client.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			if getgenv().SpeedHack then hum.WalkSpeed = getgenv().PlayerSpeed end
			if getgenv().JumpHack then hum.JumpPower = getgenv().JumpPower end
		end
		task.wait(0.2)
	end
end)

--====================--
-- KILL AURA LOOP
--====================--
task.spawn(function()
	while true do
		if getgenv().KillAura then
			if IsEnemyDead(AuraTarget) then
				AuraTarget = GetNearestEnemy()
			end
			if AuraTarget then
				CommandFollowers(AuraTarget)
			end
		end
		task.wait(0.1)
	end
end)

--====================--
-- UI
--====================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Minion Aura",
	ToggleUIKeybind = "K",
})

local Tab = Window:CreateTab("Main", "swords")

Tab:CreateLabel("⚔️ Kill Aura")
Tab:CreateLabel("Press [Q] to Toggle")

Tab:CreateToggle({
	Name = "Infinity Follower HP",
	CurrentValue = false,
	Callback = function(v) getgenv().InfinityFollowerHP = v end,
})

Tab:CreateToggle({
	Name = "Speed Hack",
	CurrentValue = false,
	Callback = function(v) getgenv().SpeedHack = v end,
})

Tab:CreateToggle({
	Name = "Jump Hack",
	CurrentValue = false,
	Callback = function(v) getgenv().JumpHack = v end,
})

--====================--
-- KEYBIND
--====================--
UIS.InputBegan:Connect(function(i, g)
	if g then return end
	if i.KeyCode == getgenv().KillAuraKey then
		getgenv().KillAura = not getgenv().KillAura
		if not getgenv().KillAura then AuraTarget = nil end

		Rayfield:Notify({
			Title = "Kill Aura",
			Content = getgenv().KillAura and "ON" or "OFF",
			Duration = 2
		})
	end
end)
