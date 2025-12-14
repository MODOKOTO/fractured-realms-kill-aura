--====================================================--
--  Fractured Realms - Universal Minion Kill Aura
--  + Manual Click Target
--====================================================--

--====================--
-- SERVICES
--====================--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Client = Players.LocalPlayer

--====================--
-- CONFIG
--====================--
getgenv().AuraRange = 20
getgenv().HitAmount = 5
getgenv().KillAura = false

getgenv().AutoSwitchTarget = false
getgenv().SwitchInterval = 3

getgenv().InfinityFollowerHP = false

--====================--
-- STATE
--====================--
local AuraTarget = nil
local ManualTarget = nil
local LastSwitchTime = 0

--====================--
-- ENEMY CHECK
--====================--
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
			if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
				table.insert(enemies, obj)
			end
		end
	end

	scan(workspace:FindFirstChild("ClickCoins"))
	scan(workspace:FindFirstChild("Dungeons"))

	local inf = workspace:FindFirstChild("INFINITE_DUNGEON")
	if inf then
		local model = inf:FindFirstChild("infinite_Dungeon")
		if model then
			scan(model:FindFirstChild("Bosses"))
		end
	end

	scan(workspace:FindFirstChild("Seraphim_Fight"))

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
-- COMMAND FOLLOWERS
--====================--
local function CommandFollowers(enemy)
	if not enemy then return end
	for i = 1, (getgenv().HitAmount or 5) do
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
-- CLICK DETECTOR TARGETING
--====================--
local function GetEnemyFromClickDetector(cd)
	local p = cd.Parent
	while p and p ~= workspace do
		if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then
			return p
		end
		p = p.Parent
	end
	return nil
end

for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("ClickDetector") then
		obj.MouseClick:Connect(function(player)
			if player ~= Client then return end

			local enemy = GetEnemyFromClickDetector(obj)
			if enemy then
				ManualTarget = enemy
				AuraTarget = enemy
				LastSwitchTime = tick()
			end
		end)
	end
end

--====================--
-- UI (Rayfield)
--====================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Minion Aura",
	ToggleUIKeybind = "K",
})

local Tab = Window:CreateTab("Main", "swords")

Tab:CreateSlider({
	Name = "Kill Aura Range",
	Range = {5, 200},
	Increment = 1,
	CurrentValue = getgenv().AuraRange,
	Callback = function(v)
		getgenv().AuraRange = v
	end,
})

Tab:CreateInput({
	Name = "Hit Amount",
	PlaceholderText = "Default = 5",
	RemoveTextAfterFocusLost = false,
	Callback = function(txt)
		getgenv().HitAmount = tonumber(txt) or 5
	end,
})

Tab:CreateToggle({
	Name = "Auto Switch Target",
	CurrentValue = false,
	Callback = function(v)
		getgenv().AutoSwitchTarget = v
	end,
})

Tab:CreateInput({
	Name = "Switch Interval (Seconds)",
	PlaceholderText = "Default = 3",
	RemoveTextAfterFocusLost = false,
	Callback = function(txt)
		getgenv().SwitchInterval = tonumber(txt) or 3
	end,
})

Tab:CreateToggle({
	Name = "Infinity Follower Health",
	CurrentValue = false,
	Callback = function(v)
		getgenv().InfinityFollowerHP = v
	end,
})

--====================--
-- KILL AURA LOOP
--====================--
Tab:CreateToggle({
	Name = "Minion Kill Aura",
	CurrentValue = false,
	Callback = function(state)
		getgenv().KillAura = state
		if not state then
			AuraTarget = nil
			ManualTarget = nil
			return
		end

		task.spawn(function()
			LastSwitchTime = tick()

			while getgenv().KillAura do
				local now = tick()

				-- ใช้เป้าที่คลิกก่อน
				if ManualTarget and not IsEnemyDead(ManualTarget) then
					AuraTarget = ManualTarget
				else
					ManualTarget = nil

					if IsEnemyDead(AuraTarget) then
						AuraTarget = GetNearestEnemy()
						LastSwitchTime = now
					end
				end

				-- Auto Switch (เฉพาะตอนไม่มี Manual Target)
				if getgenv().AutoSwitchTarget and not ManualTarget and AuraTarget then
					if now - LastSwitchTime >= getgenv().SwitchInterval then
						AuraTarget = GetNearestEnemy()
						LastSwitchTime = now
					end
				end

				if AuraTarget then
					CommandFollowers(AuraTarget)
				end

				task.wait(0.1)
			end
		end)
	end,
})
