--====================================================--
--  Fractured Realms - FINAL Universal Minion Kill Aura
--====================================================--

--====================--
-- SERVICES
--====================--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Client = Players.LocalPlayer

--====================--
-- CONFIG (KEEP ALL)
--====================--
getgenv().AuraRange = 20
getgenv().HitAmount = 5

getgenv().KillAura = false
getgenv().AutoSwitchTarget = false
getgenv().SwitchInterval = 3
getgenv().InfinityFollowerHP = false

getgenv().ToggleKey = Enum.KeyCode.Q

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
		StarterGui:SetCore("SendNotification", {
			Title = "Minion Kill Aura",
			Text = msg,
			Duration = 2
		})
	end)
end

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
-- GET ALL ENEMIES (SAFE & UNIVERSAL)
--====================--
local function GetAllEnemies()
	local enemies = {}

	local npcFolder = workspace:FindFirstChild("NPCS")
	local followerFolder = workspace:FindFirstChild("Player_Followers")

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then

				-- ❌ Ignore Player Characters
				if Players:GetPlayerFromCharacter(obj) then continue end

				-- ❌ Ignore NPC Folder
				if npcFolder and obj:IsDescendantOf(npcFolder) then continue end

				-- ❌ Ignore Followers
				if followerFolder and obj:IsDescendantOf(followerFolder) then continue end

				-- ✅ Valid Enemy
				table.insert(enemies, obj)
			end
		end
	end

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
		local hrp = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
		if hrp then
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
-- COMMAND FOLLOWERS (PURE)
--====================--
local AssignRemote = RS.Remotes.FollowerAttack.AssignTarget

local function CommandFollowers(enemy)
	if not enemy then return end
	for i = 1, (getgenv().HitAmount or 5) do
		AssignRemote:FireServer(enemy, true)
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
-- KEY TOGGLE (Q)
--====================--
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == getgenv().ToggleKey then
		getgenv().KillAura = not getgenv().KillAura
		AuraTarget = nil
		LastSwitchTime = tick()
		Notify(getgenv().KillAura and "Kill Aura : ON" or "Kill Aura : OFF")
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
	Name = "Aura Range",
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
	Callback = function(t)
		getgenv().HitAmount = tonumber(t) or 5
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
	Name = "Switch Interval (Sec)",
	PlaceholderText = "Default = 3",
	RemoveTextAfterFocusLost = false,
	Callback = function(t)
		getgenv().SwitchInterval = tonumber(t) or 3
	end,
})

Tab:CreateToggle({
	Name = "Infinity Follower HP",
	CurrentValue = false,
	Callback = function(v)
		getgenv().InfinityFollowerHP = v
	end,
})

--====================--
-- MAIN LOOP (STABLE)
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
