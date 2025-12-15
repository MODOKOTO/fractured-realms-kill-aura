--====================================================--
--  Fractured Realms - Universal Minion Kill Aura
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
getgenv().AuraRange = 25
getgenv().HitAmount = 5
getgenv().KillAura = false

getgenv().AutoSwitchTarget = true
getgenv().SwitchInterval = 3

getgenv().InfinityFollowerHP = false
getgenv().PlayerSpeed = 16
getgenv().PlayerJump = 50

-- Keybind
getgenv().KillAuraKey = Enum.KeyCode.Q

-- Follower safety distance (แก้ยึกยัก UID ซ้ำ)
local FOLLOWER_ATTACK_DISTANCE = 12

--====================--
-- STATE
--====================--
local AuraTarget = nil
local LastSwitchTime = 0

--====================--
-- UTILS
--====================--
local function Notify(text)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = "Kill Aura",
			Text = text,
			Duration = 2
		})
	end)
end

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
-- EXCLUDED NPCS
--====================--
local function IsNPCExcluded(enemy)
	local npcFolder = workspace:FindFirstChild("NPCS")
	if npcFolder and enemy:IsDescendantOf(npcFolder) then
		return true
	end
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
				and not IsNPCExcluded(obj) then
				table.insert(enemies, obj)
			end
		end
	end

	scan(workspace:FindFirstChild("ClickCoins"))
	scan(workspace:FindFirstChild("Dungeons"))

	local inf = workspace:FindFirstChild("INFINITE_DUNGEON")
	if inf then
		local dungeon = inf:FindFirstChild("infinite_Dungeon")
		if dungeon then
			scan(dungeon:FindFirstChild("Bosses"))
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
-- FOLLOWER DISTANCE CHECK
--====================--
local function AnyFollowerNearEnemy(enemy)
	if not enemy or not enemy.PrimaryPart then return false end

	local pf = workspace:FindFirstChild("Player_Followers")
	if not pf then return false end

	local my = pf:FindFirstChild(Client.Name .. "_Followers")
	if not my then return false end

	for _, follower in ipairs(my:GetChildren()) do
		local root = follower:FindFirstChild("HumanoidRootPart")
		if root then
			local dist = (root.Position - enemy.PrimaryPart.Position).Magnitude
			if dist <= FOLLOWER_ATTACK_DISTANCE then
				return true
			end
		end
	end

	return false
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
-- PLAYER STATS
--====================--
task.spawn(function()
	while true do
		local char = Client.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = getgenv().PlayerSpeed
				hum.JumpPower = getgenv().PlayerJump
			end
		end
		task.wait(0.2)
	end
end)

--====================--
-- KEYBIND (Q)
--====================--
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == getgenv().KillAuraKey then
		getgenv().KillAura = not getgenv().KillAura
		Notify(getgenv().KillAura and "Kill Aura : ON" or "Kill Aura : OFF")
	end
end)

--====================--
-- KILL AURA LOOP
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

			if AuraTarget and AnyFollowerNearEnemy(AuraTarget) then
				CommandFollowers(AuraTarget)
			end
		end
		task.wait(0.1)
	end
end)
