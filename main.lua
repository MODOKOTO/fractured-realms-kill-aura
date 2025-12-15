--====================================================--
-- Fractured Realms - Universal Minion Kill Aura (FULL)
--====================================================--

--====================--
-- SERVICES
--====================--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Client = Players.LocalPlayer

--====================--
-- CONFIG (Global)
--====================--
getgenv().AuraRange = 20
getgenv().HitAmount = 5
getgenv().KillAura = false

getgenv().AutoSwitchTarget = false
getgenv().SwitchInterval = 3

getgenv().InfinityFollowerHP = false

getgenv().SpeedHack = false
getgenv().PlayerSpeed = 24

getgenv().KillAuraKey = Enum.KeyCode.Q

--====================--
-- STATE
--====================--
local AuraTarget = nil
local LastSwitchTime = 0

--====================--
-- UTILS
--====================--
local function IsInNPCFolder(model)
	local npcFolder = workspace:FindFirstChild("NPCS")
	return npcFolder and model:IsDescendantOf(npcFolder)
end

local function IsEnemyDead(enemy)
	if not enemy or not enemy.Parent then return true end

	local hum = enemy:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return true end
	if enemy:GetAttribute("Dead") == true then return true end

	return false
end

--====================--
-- COLLECT ALL ENEMIES
--====================--
local function GetAllEnemies()
	local enemies = {}

	local function scan(container)
		if not container then return end
		for _, obj in ipairs(container:GetDescendants()) do
			if obj:IsA("Model")
				and obj:FindFirstChildOfClass("Humanoid")
				and not IsInNPCFolder(obj)
			then
				table.insert(enemies, obj)
			end
		end
	end

	-- Normal
	scan(workspace:FindFirstChild("ClickCoins"))
	scan(workspace:FindFirstChild("Dungeons"))

	-- Infinite Dungeon
	local inf = workspace:FindFirstChild("INFINITE_DUNGEON")
	if inf then
		local model = inf:FindFirstChild("infinite_Dungeon")
		if model then
			scan(model:FindFirstChild("Bosses"))
		end
	end

	-- World Boss
	scan(workspace:FindFirstChild("Seraphim_Fight"))
	scan(workspace:FindFirstChild("Scarab"))
	scan(workspace:FindFirstChild("Sentinel"))

	return enemies
end

--====================--
-- FIND NEAREST ENEMY
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

		if hum and hrp and hum.Health > 0 then
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
-- COMMAND FOLLOWERS (KillAura)
--====================--
local function CommandFollowers(enemy)
	if not enemy then return end
	local remote = RS:FindFirstChild("Remotes")
		and RS.Remotes:FindFirstChild("FollowerAttack")
		and RS.Remotes.FollowerAttack:FindFirstChild("AssignTarget")

	if not remote then return end

	for i = 1, getgenv().HitAmount do
		remote:FireServer(enemy, true)
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
-- PLAYER SPEED
--====================--
task.spawn(function()
	while true do
		if getgenv().SpeedHack then
			local char = Client.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = getgenv().PlayerSpeed
				end
			end
		end
		task.wait(0.2)
	end
end)

--====================--
-- KILLAURA LOOP
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

--====================--
-- KEYBIND (Q)
--====================--
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == getgenv().KillAuraKey then
		getgenv().KillAura = not getgenv().KillAura
		if not getgenv().KillAura then
			AuraTarget = nil
		end
		Rayfield:Notify({
			Title = "Kill Aura",
			Content = getgenv().KillAura and "ENABLED" or "DISABLED",
			Duration = 2
		})
	end
end)

--====================--
-- UI (Rayfield)
--====================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Minion System",
	ToggleUIKeybind = "K",
})

local Tab = Window:CreateTab("Main", "swords")

-- Combat
Tab:CreateLabel("⚔️ Combat")
Tab:CreateLabel("Press [Q] to Toggle Kill Aura")

Tab:CreateSlider({
	Name = "Kill Aura Range",
	Range = {5, 200},
	Increment = 1,
	CurrentValue = getgenv().AuraRange,
	Callback = function(v) getgenv().AuraRange = v end,
})

Tab:CreateInput({
	Name = "Hit Amount",
	PlaceholderText = "Default = 5",
	RemoveTextAfterFocusLost = false,
	Callback = function(t) getgenv().HitAmount = tonumber(t) or 5 end,
})

Tab:CreateToggle({
	Name = "Auto Switch Target",
	CurrentValue = false,
	Callback = function(v) getgenv().AutoSwitchTarget = v end,
})

Tab:CreateInput({
	Name = "Switch Interval",
	PlaceholderText = "Default = 3",
	RemoveTextAfterFocusLost = false,
	Callback = function(t) getgenv().SwitchInterval = tonumber(t) or 3 end,
})

-- Followers
Tab:CreateLabel("🤖 Followers")

Tab:CreateToggle({
	Name = "Infinity Follower Health",
	CurrentValue = false,
	Callback = function(v) getgenv().InfinityFollowerHP = v end,
})

-- Player
Tab:CreateLabel("🏃 Player")

Tab:CreateToggle({
	Name = "Speed Hack",
	CurrentValue = false,
	Callback = function(v) getgenv().SpeedHack = v end,
})

Tab:CreateSlider({
	Name = "Player Speed",
	Range = {16, 100},
	Increment = 1,
	CurrentValue = getgenv().PlayerSpeed,
	Callback = function(v) getgenv().PlayerSpeed = v end,
})
