--====================================================--
--   Fractured Realms - Kill Aura (Optimized Build)
--   Fixed: Aura stuck, target not switching, warp stuck
--   Clean code + structured + reusable
--====================================================--

local Client = game:GetService("Players").LocalPlayer

-- ▼ Global Config
getgenv().AuraRange = 20
getgenv().HitAmount = 5

getgenv().KillAura = false
getgenv().AutoWarp = false

local CurrentEnemy = nil


--====================================================--
--  FUNCTION: ตรวจสอบว่าศัตรูตายแล้วหรือยัง
--====================================================--
local function IsEnemyDead(enemy)
	if not enemy then return true end
	
	local hrp = enemy:FindFirstChild("HumanoidRootPart")
	if not hrp then return true end

	local hum = enemy:FindFirstChildOfClass("Humanoid")
	if not hum then return true end

	if hum.Health <= 0 then return true end

	-- ถ้าเกมใช้ Attribute
	if enemy:GetAttribute("Dead") == true then return true end

	return false
end


--====================================================--
-- FUNCTION: หา Enemy ที่ใกล้ที่สุด
--====================================================--
local function GetNearestEnemy()
	local character = Client.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest
	local closestDist = 9e9

	for _, folder in workspace.ClickCoins:GetChildren() do
		for _, enemy in folder:GetChildren() do
			local hrp = enemy:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					nearest = enemy
				end
			end
		end
	end

	return nearest
end


--====================================================--
-- Rayfield UI Setup
--====================================================--

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Kill Aura",
	LoadingTitle = "Kill Aura Loaded",
	LoadingSubtitle = "by Grimcity",
	ToggleUIKeybind = "K",
})

local Tab = Window:CreateTab("Main", "swords")


--====================================================--
-- UI: Slider ระยะ Kill Aura
--====================================================--
Tab:CreateSlider({
	Name = "Kill Aura Range",
	Range = {5, 100},
	Increment = 1,
	CurrentValue = getgenv().AuraRange,
	Callback = function(value)
		getgenv().AuraRange = value
	end,
})


--====================================================--
-- UI: จำนวน Hit ต่อรอบ
--====================================================--
Tab:CreateInput({
	Name = "Hit Amount",
	PlaceholderText = "Default = 5",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		local num = tonumber(text)
		getgenv().HitAmount = num or 5
	end,
})


--====================================================--
-- TOGGLE: Kill Aura (ไม่วาร์ป)
--====================================================--
Tab:CreateToggle({
	Name = "Kill Aura (No Warp)",
	CurrentValue = false,
	Callback = function(state)
		getgenv().KillAura = state

		if state then
			task.spawn(function()
				while getgenv().KillAura do

					-- ตรวจศัตรู ถ้าตายหรือสูญหาย จะหาใหม่
					if IsEnemyDead(CurrentEnemy) then
						CurrentEnemy = GetNearestEnemy()
					end

					if CurrentEnemy then
						for i = 1, (getgenv().HitAmount or 5) do
							game:GetService("ReplicatedStorage").Remotes.FollowerAttack.AssignTarget:FireServer(CurrentEnemy, true)
						end
					end

					task.wait(0.05)
				end
			end)
		end
	end,
})


--====================================================--
-- TOGGLE: Auto Warp ไปหาศัตรู
--====================================================--
Tab:CreateToggle({
	Name = "Auto Warp to Enemy",
	CurrentValue = false,
	Callback = function(state)
		getgenv().AutoWarp = state

		if state then
			task.spawn(function()
				while getgenv().AutoWarp do

					if IsEnemyDead(CurrentEnemy) then
						CurrentEnemy = GetNearestEnemy()
					end

					local root = Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")
					local er = CurrentEnemy and CurrentEnemy:FindFirstChild("HumanoidRootPart")

					if root and er then
						root.CFrame = er.CFrame * CFrame.new(0, 0, -2)
					end

					task.wait(0.15)
				end
			end)
		end
	end,
})

--====================================================--
--  END SCRIPT
--====================================================--
