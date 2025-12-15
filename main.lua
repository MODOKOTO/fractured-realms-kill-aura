--====================================================--
-- Fractured Realms - Minion Aura
-- Kill Aura : Q Toggle
-- Follower Warp Attack (NEW)
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
getgenv().KillAura = false
getgenv().AuraRange = 50
getgenv().HitAmount = 5
getgenv().AutoSwitchTarget = false
getgenv().SwitchInterval = 3

-- Followers
getgenv().InfinityFollowerHP = false
getgenv().FollowerWarpAttack = false

-- Movement
getgenv().EnableWalkSpeed = false
getgenv().EnableJumpPower = false
getgenv().WalkSpeed = 16
getgenv().JumpPower = 50

-- Key
getgenv().ToggleKey = Enum.KeyCode.Q

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
-- FOLLOWER WARP
--====================--
local function WarpFollowersToEnemy(enemy)
	if not enemy then return end
	local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
	if not enemyRoot then return end

	local pf = workspace:FindFirstChild("Player_Followers")
	if not pf then return end
	local my = pf:FindFirstChild(Client.Name .. "_Followers")
	if not my then return end

	for _, minion in ipairs(my:GetChildren()) do
		local hrp = minion:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = enemyRoot.CFrame * CFrame.new(math.random(-3,3), 0, math.random(-3,3))
		end
	end
end

--====================--
-- COMMAND FOLLOWERS
--====================--
local function CommandFollowers(enemy)
	if not enemy then return end

	if getgenv().FollowerWarpAttack then
		WarpFollowersToEnemy(enemy)
	end

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
						if hum then hum.Health = hum.MaxHealth end
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
		local char = Client.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = getgenv().EnableWalkSpeed and getgenv().WalkSpeed or 16
				hum.JumpPower = getgenv().EnableJumpPower and getgenv().JumpPower or 50
			end
		end
		task.wait(0.2)
	end
end)

--====================--
-- POTATO GRAPHICS MODE
--====================--

getgenv().PotatoGraphics = false

local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local function SetPotatoGraphics(enable)
	-- Lighting (ฆ่าภาพก่อน)
	Lighting.GlobalShadows = not enable
	Lighting.Brightness = enable and 1 or 2
	Lighting.EnvironmentDiffuseScale = enable and 0 or 1
	Lighting.EnvironmentSpecularScale = enable and 0 or 1
	Lighting.FogEnd = enable and 9e9 or 1000
	Lighting.FogStart = 0

	-- Terrain
	if Terrain then
		Terrain.WaterWaveSize = enable and 0 or 1
		Terrain.WaterWaveSpeed = enable and 0 or 10
		Terrain.WaterReflectance = enable and 0 or 1
		Terrain.WaterTransparency = enable and 1 or 0
	end

	for _, v in ipairs(workspace:GetDescendants()) do
		-- 🔥 ลบ Effect ทุกชนิด
		if v:IsA("ParticleEmitter")
			or v:IsA("Trail")
			or v:IsA("Beam")
			or v:IsA("Fire")
			or v:IsA("Smoke")
			or v:IsA("Sparkles") then
			v.Enabled = not enable

		-- 💡 ปิดไฟทั้งหมด
		elseif v:IsA("PointLight")
			or v:IsA("SpotLight")
			or v:IsA("SurfaceLight") then
			v.Enabled = not enable

		-- 🧱 ฆ่าวัสดุ + Texture
		elseif v:IsA("BasePart") then
			if enable then
				v.Material = Enum.Material.Plastic
				v.Reflectance = 0
				v.CastShadow = false
			end

		-- 🖼️ ลบ Texture / Decal
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = enable and 1 or 0

		-- 🌈 ปิด Post Processing
		elseif v:IsA("BloomEffect")
			or v:IsA("BlurEffect")
			or v:IsA("SunRaysEffect")
			or v:IsA("ColorCorrectionEffect")
			or v:IsA("DepthOfFieldEffect") then
			v.Enabled = not enable
		end
	end
end


--====================--
-- UI (RAYFIELD)
--====================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Minion Aura",
	ToggleUIKeybind = "K",
})

--====================--
-- KEY TOGGLE (Q)
--====================--
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == getgenv().ToggleKey then
		getgenv().KillAura = not getgenv().KillAura
		AuraTarget = nil
		LastSwitchTime = tick()

		Rayfield:Notify({
			Title = "Kill Aura",
			Content = getgenv().KillAura and "ON  (Q)" or "OFF (Q)",
			Duration = 2,
		})
	end
end)

--====================--
-- COMBAT TAB
--====================--
local CombatTab = Window:CreateTab("Combat", "swords")

CombatTab:CreateLabel("Kill Aura Toggle Key : [ Q ]")

CombatTab:CreateSlider({
	Name = "Aura Range",
	Range = {5, 200},
	Increment = 1,
	CurrentValue = getgenv().AuraRange,
	Callback = function(v) getgenv().AuraRange = v end,
})

CombatTab:CreateInput({
	Name = "Hit Amount",
	PlaceholderText = "Number only (ex: 5, 50, 500)",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		local value = tonumber(text)
		if value and value >= 1 then
			getgenv().HitAmount = math.floor(value)
		end
	end,
})

CombatTab:CreateToggle({
	Name = "Follower Warp Attack",
	CurrentValue = getgenv().FollowerWarpAttack,
	Callback = function(v)
		getgenv().FollowerWarpAttack = v
	end,
})

CombatTab:CreateToggle({
	Name = "Auto Switch Target",
	CurrentValue = getgenv().AutoSwitchTarget,
	Callback = function(v)
		getgenv().AutoSwitchTarget = v
	end,
})

CombatTab:CreateSlider({
	Name = "Switch Interval (Sec)",
	Range = {1, 10},
	Increment = 0.5,
	CurrentValue = getgenv().SwitchInterval,
	Callback = function(v)
		getgenv().SwitchInterval = v
	end,
})

--====================--
-- FOLLOWERS TAB
--====================--
local FollowerTab = Window:CreateTab("Followers", "users")

FollowerTab:CreateToggle({
	Name = "Infinity Follower HP",
	CurrentValue = getgenv().InfinityFollowerHP,
	Callback = function(v)
		getgenv().InfinityFollowerHP = v
	end,
})

--====================--
-- MOVEMENT TAB
--====================--
local MoveTab = Window:CreateTab("Movement", "activity")

MoveTab:CreateToggle({
	Name = "Enable Walk Speed",
	CurrentValue = getgenv().EnableWalkSpeed,
	Callback = function(v)
		getgenv().EnableWalkSpeed = v
	end,
})

MoveTab:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 150},
	Increment = 1,
	CurrentValue = getgenv().WalkSpeed,
	Callback = function(v)
		getgenv().WalkSpeed = v
	end,
})

MoveTab:CreateToggle({
	Name = "Enable Jump Power",
	CurrentValue = getgenv().EnableJumpPower,
	Callback = function(v)
		getgenv().EnableJumpPower = v
	end,
})

MoveTab:CreateSlider({
	Name = "Jump Power",
	Range = {50, 300},
	Increment = 5,
	CurrentValue = getgenv().JumpPower,
	Callback = function(v)
		getgenv().JumpPower = v
	end,
})

--====================--
-- GRAPHICS TAB (POTATO)
--====================--
local GraphicsTab = Window:CreateTab("Graphics", "monitor")

GraphicsTab:CreateLabel("Extreme Performance Mode")

GraphicsTab:CreateToggle({
	Name = "POTATO GRAPHICS (NO EFFECT)",
	CurrentValue = getgenv().PotatoGraphics,
	Callback = function(v)
		getgenv().PotatoGraphics = v
		SetPotatoGraphics(v)

		Rayfield:Notify({
			Title = "Graphics",
			Content = v and "POTATO MODE : ON 🥔 (MAX FPS)"
				or "POTATO MODE : OFF",
			Duration = 2,
		})
	end,
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
