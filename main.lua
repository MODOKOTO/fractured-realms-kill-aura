--====================================================--
--   Fractured Realms - Kill Aura (Bug-Fixed Version)
--   Fixed: Aura stuck, Warp stuck, not switching mobs
--   Separated Targeting Systems (Aura / Warp)
--====================================================--

local Client = game:GetService("Players").LocalPlayer


-- ▼ CONFIG
getgenv().AuraRange = 20
getgenv().HitAmount = 5

getgenv().KillAura = false
getgenv().AutoWarp = false

-- แยก target คนละชุด
local AuraTarget = nil
local WarpTarget = nil


--====================================================--
--  UTIL: Enemy Dead Checker
--====================================================--
local function IsEnemyDead(enemy)
	if not enemy then return true end

	local hum = enemy:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return true end

	local hrp = enemy:FindFirstChild("HumanoidRootPart")
	if not hrp then return true end

	if enemy:GetAttribute("Dead") == true then return true end

	return false
end


--====================================================--
--  UTIL: Get Nearest Enemy
--====================================================--
local function GetNearestEnemy()
	local character = Client.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest
	local closest = 9e9

	for _, folder in workspace.ClickCoins:GetChildren() do
		for _, enemy in folder:GetChildren() do
			local hrp = enemy:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist < closest then
					closest = dist
					nearest = enemy
				end
			end
		end
	end

	return nearest
end


--====================================================--
-- UI: Rayfield
--====================================================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Kill Aura",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "by OnMD",
	ToggleUIKeybind = "L",
})

local Tab = Window:CreateTab("Main", "swords")


--====================================================--
-- UI: Aura Range Slider
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
-- UI: Hit Amount
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
-- Toggle: Kill Aura (NO WARP)
--====================================================--
Tab:CreateToggle({
	Name = "Kill Aura (No Warp)",
	CurrentValue = false,
	Callback = function(state)
		getgenv().KillAura = state

		if state then
			task.spawn(function()
				while getgenv().KillAura do

					-- หาใหม่ถ้าตาย/หาย
					if IsEnemyDead(AuraTarget) then
						AuraTarget = GetNearestEnemy()
					end

					if AuraTarget then
						for i = 1, (getgenv().HitAmount or 5) do
							game.ReplicatedStorage.Remotes.FollowerAttack.AssignTarget:FireServer(AuraTarget, true)
						end
					end

					task.wait(0.05)
				end
			end)
		end
	end,
})


--====================================================--
-- Toggle: Auto Warp
--====================================================--
Tab:CreateToggle({
	Name = "Auto Warp to Enemy",
	CurrentValue = false,
	Callback = function(state)
		getgenv().AutoWarp = state

		if state then
			task.spawn(function()
				while getgenv().AutoWarp do

					-- หาเป้าวาร์ปใหม่
					if IsEnemyDead(WarpTarget) then
						WarpTarget = GetNearestEnemy()
					end

					local character = Client.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					local er = WarpTarget and WarpTarget:FindFirstChild("HumanoidRootPart")

					if root and er then
						root.CFrame = er.CFrame * CFrame.new(0, 0, -2)
					end

					task.wait(0.15)
				end
			end)
		end
	end,
})
