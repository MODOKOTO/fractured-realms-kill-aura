--====================================================--
--  Fractured Realms - Universal Minion Kill Aura
--  Supports:
--  • ClickCoins
--  • Dungeons
--  • Infinite Dungeon Bosses
--  • World Boss (Seraphim)
--  • Auto Switch Target
--  • Infinity Follower HP
--====================================================--

--====================--
-- SERVICES
--====================--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Client = Players.LocalPlayer

--====================--
-- CONFIG (Default)
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
local LastSwitchTime = 0

--====================--
-- ENEMY VALIDATION
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

	-- Normal mobs
	scan(workspace:FindFirstChild("ClickCoins"))
	scan(workspace:FindFirstChild("Dungeons"))

	-- Infinite Dungeon Bosses
	local inf = workspace:FindFirstChild("INFINITE_DUNGEON")
	if inf then
		local model = inf:FindFirstChild("infinite_Dungeon")
		if model then
			scan(model:FindFirstChild("Bosses"))
		end
	end

	-- World Boss
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
			return
		end

		task.spawn(function()
			LastSwitchTime = tick()

			while getgenv().KillAura do
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

				task.wait(0.1)
			end
		end)
	end,
})


-- --====================================================--
-- --   Fractured Realms - Pure Minion Kill Aura
-- --   + Auto Switch Target
-- --   + Dungeons Support
-- --   + Infinity Follower Health
-- --====================================================--

-- local Players = game:GetService("Players")
-- local Client = Players.LocalPlayer
-- local RS = game:GetService("ReplicatedStorage")

-- --====================--
-- -- CONFIG
-- --====================--
-- getgenv().AuraRange = 20
-- getgenv().HitAmount = 5
-- getgenv().KillAura = false

-- getgenv().AutoSwitchTarget = false
-- getgenv().SwitchInterval = 3

-- getgenv().InfinityFollowerHP = false

-- --====================--
-- -- STATE
-- --====================--
-- local AuraTarget = nil
-- local LastSwitchTime = 0


-- --====================--
-- -- Enemy Dead Checker
-- --====================--
-- local function IsEnemyDead(enemy)
-- 	if not enemy or not enemy.Parent then return true end

-- 	local hum = enemy:FindFirstChildOfClass("Humanoid")
-- 	if not hum or hum.Health <= 0 then return true end

-- 	if enemy:GetAttribute("Dead") == true then return true end

-- 	return false
-- end


-- --====================--
-- -- Get Enemy Containers
-- --====================--
-- local function GetEnemyFolders()
-- 	local folders = {}

-- 	if workspace:FindFirstChild("ClickCoins") then
-- 		table.insert(folders, workspace.ClickCoins)
-- 	end

-- 	if workspace:FindFirstChild("Dungeons") then
-- 		table.insert(folders, workspace.Dungeons)
-- 	end

-- 	return folders
-- end


-- --====================--
-- -- Get Nearest Enemy (ClickCoins + Dungeons)
-- --====================--
-- local function GetNearestEnemy()
-- 	local char = Client.Character
-- 	if not char then return nil end

-- 	local root = char:FindFirstChild("HumanoidRootPart")
-- 	if not root then return nil end

-- 	local nearest, closest = nil, math.huge

-- 	for _, container in ipairs(GetEnemyFolders()) do
-- 		for _, zone in ipairs(container:GetChildren()) do
-- 			for _, enemy in ipairs(zone:GetChildren()) do
-- 				local hrp = enemy:FindFirstChild("HumanoidRootPart")
-- 				if hrp then
-- 					local dist = (hrp.Position - root.Position).Magnitude
-- 					if dist <= getgenv().AuraRange and dist < closest then
-- 						closest = dist
-- 						nearest = enemy
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	return nearest
-- end


-- --====================--
-- -- Command Minions
-- --====================--
-- local function CommandMinions(enemy)
-- 	if not enemy then return end

-- 	for i = 1, (getgenv().HitAmount or 5) do
-- 		RS.Remotes.FollowerAttack.AssignTarget:FireServer(enemy, true)
-- 	end
-- end


-- --====================--
-- -- Infinity Follower Health
-- --====================--
-- task.spawn(function()
-- 	while true do
-- 		if getgenv().InfinityFollowerHP then
-- 			local folder = workspace:FindFirstChild("Player_Followers")
-- 			if folder then
-- 				local myFollowers = folder:FindFirstChild(Client.Name .. "_Followers")
-- 				if myFollowers then
-- 					for _, minion in ipairs(myFollowers:GetChildren()) do
-- 						local hum = minion:FindFirstChildOfClass("Humanoid")
-- 						if hum then
-- 							hum.Health = hum.MaxHealth
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		task.wait(0.2)
-- 	end
-- end)


-- --====================--
-- -- UI (Rayfield)
-- --====================--
-- local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- local Window = Rayfield:CreateWindow({
-- 	Name = "Fractured Realms - Kill Aura",
-- 	ToggleUIKeybind = "K",
-- })

-- local Tab = Window:CreateTab("Main", "swords")


-- Tab:CreateSlider({
-- 	Name = "Kill Aura Range",
-- 	Range = {5, 150},
-- 	Increment = 1,
-- 	CurrentValue = getgenv().AuraRange,
-- 	Callback = function(v)
-- 		getgenv().AuraRange = v
-- 	end,
-- })

-- Tab:CreateInput({
-- 	Name = "Hit Amount",
-- 	PlaceholderText = "Default = 5",
-- 	RemoveTextAfterFocusLost = false,
-- 	Callback = function(text)
-- 		getgenv().HitAmount = tonumber(text) or 5
-- 	end,
-- })

-- Tab:CreateToggle({
-- 	Name = "Auto Switch Target",
-- 	CurrentValue = false,
-- 	Callback = function(v)
-- 		getgenv().AutoSwitchTarget = v
-- 	end,
-- })

-- Tab:CreateInput({
-- 	Name = "Switch Interval (Seconds)",
-- 	PlaceholderText = "Default = 3",
-- 	RemoveTextAfterFocusLost = false,
-- 	Callback = function(text)
-- 		getgenv().SwitchInterval = tonumber(text) or 3
-- 	end,
-- })

-- Tab:CreateToggle({
-- 	Name = "Infinity Follower Health",
-- 	CurrentValue = false,
-- 	Callback = function(v)
-- 		getgenv().InfinityFollowerHP = v
-- 	end,
-- })


-- --====================--
-- -- Kill Aura Loop
-- --====================--
-- Tab:CreateToggle({
-- 	Name = "Minion Kill Aura",
-- 	CurrentValue = false,
-- 	Callback = function(state)
-- 		getgenv().KillAura = state

-- 		if not state then
-- 			AuraTarget = nil
-- 			return
-- 		end

-- 		task.spawn(function()
-- 			LastSwitchTime = tick()

-- 			while getgenv().KillAura do
-- 				local now = tick()

-- 				if IsEnemyDead(AuraTarget) then
-- 					AuraTarget = GetNearestEnemy()
-- 					LastSwitchTime = now
-- 				end

-- 				if getgenv().AutoSwitchTarget and AuraTarget then
-- 					if now - LastSwitchTime >= getgenv().SwitchInterval then
-- 						AuraTarget = GetNearestEnemy()
-- 						LastSwitchTime = now
-- 					end
-- 				end

-- 				if AuraTarget then
-- 					CommandMinions(AuraTarget)
-- 				end

-- 				task.wait(0.1)
-- 			end
-- 		end)
-- 	end,
-- })
