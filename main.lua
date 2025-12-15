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
-- CONFIG (Default)
--====================--
getgenv().AuraRange = 20
getgenv().HitAmount = 5
getgenv().KillAura = false

getgenv().AutoSwitchTarget = false
getgenv().SwitchInterval = 3

getgenv().InfinityFollowerHP = false
getgenv().PlayerSpeed = 16
getgenv().PlayerJump = 50

getgenv().KillAuraKey = Enum.KeyCode.Q

-- follower safety distance
local FOLLOWER_ATTACK_DISTANCE = 12

--====================--
-- STATE
--====================--
local AuraTarget = nil
local LastSwitchTime = 0

--====================--
-- NOTIFY
--====================--
local function Notify(msg)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = "Kill Aura",
			Text = msg,
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
-- EXCLUDE NPCS
--====================--
local function IsExcluded(enemy)
	local npc = workspace:FindFirstChild("NPCS")
	return npc and enemy:IsDescendantOf(npc)
end

--====================--
-- COLLECT ENEMIES
--====================--
local function GetAllEnemies()
	local list = {}

	local function scan(container)
		if not container then return end
		for _, m in ipairs(container:GetDescendants()) do
			if m:IsA("Model")
			and m:FindFirstChildOfClass("Humanoid")
			and not IsExcluded(m) then
				table.insert(list, m)
			end
		end
	end

	scan(workspace:FindFirstChild("ClickCoins"))
	scan(workspace:FindFirstChild("Dungeons"))

	local inf = workspace:FindFirstChild("INFINITE_DUNGEON")
	if inf then
		local d = inf:FindFirstChild("infinite_Dungeon")
		if d then
			scan(d:FindFirstChild("Bosses"))
		end
	end

	scan(workspace:FindFirstChild("Seraphim_Fight"))
	return list
end

--====================--
-- NEAREST ENEMY
--====================--
local function GetNearestEnemy()
	local char = Client.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local nearest, distMin = nil, math.huge
	for _, enemy in ipairs(GetAllEnemies()) do
		local hrp = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
		local hum = enemy:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - root.Position).Magnitude
			if d <= getgenv().AuraRange and d < distMin then
				distMin = d
				nearest = enemy
			end
		end
	end
	return nearest
end

--====================--
-- FOLLOWER NEAR CHECK
--====================--
local function FollowerNear(enemy)
	if not enemy or not enemy.PrimaryPart then return false end
	local pf = workspace:FindFirstChild("Player_Followers")
	if not pf then return false end
	local my = pf:FindFirstChild(Client.Name .. "_Followers")
	if not my then return false end

	for _, f in ipairs(my:GetChildren()) do
		local hrp = f:FindFirstChild("HumanoidRootPart")
		if hrp then
			if (hrp.Position - enemy.PrimaryPart.Position).Magnitude <= FOLLOWER_ATTACK_DISTANCE then
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
	for i = 1, getgenv().HitAmount do
		RS.Remotes.FollowerAttack.AssignTarget:FireServer(enemy, true)
	end
end

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
-- INFINITY FOLLOWER HP
--====================--
task.spawn(function()
	while true do
		if getgenv().InfinityFollowerHP then
			local pf = workspace:FindFirstChild("Player_Followers")
			if pf then
				local my = pf:FindFirstChild(Client.Name .. "_Followers")
				if my then
					for _, m in ipairs(my:GetChildren()) do
						local h = m:FindFirstChildOfClass("Humanoid")
						if h then h.Health = h.MaxHealth end
					end
				end
			end
		end
		task.wait(0.2)
	end
end)

--====================--
-- KEYBIND Q
--====================--
UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode == getgenv().KillAuraKey then
		getgenv().KillAura = not getgenv().KillAura
		Notify(getgenv().KillAura and "Kill Aura ON" or "Kill Aura OFF")
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

			if AuraTarget and FollowerNear(AuraTarget) then
				CommandFollowers(AuraTarget)
			end
		end
		task.wait(0.1)
	end
end)
