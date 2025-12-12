--====================================================--
--   Fractured Realms - Pure Minion Kill Aura
--   Version: No Warp / No Player Movement
--   Followers attack automatically by game's AI
--====================================================--

local Client = game:GetService("Players").LocalPlayer

-- CONFIG
getgenv().AuraRange = 20
getgenv().HitAmount = 5
getgenv().KillAura = false

local AuraTarget = nil   -- เป้าเฉพาะของ Kill Aura ลูกน้อง


--====================================================--
-- Enemy Dead Checker
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
-- Get Nearest Enemy
--====================================================--
local function GetNearestEnemy()
	local playerChar = Client.Character
	if not playerChar then return nil end

	local root = playerChar:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest, closest = nil, 9e9

	for _, folder in workspace.ClickCoins:GetChildren() do
		for _, enemy in folder:GetChildren() do
			local hrp = enemy:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist < closest and dist <= getgenv().AuraRange then
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
	LoadingSubtitle = "Follower Edition",
	ToggleUIKeybind = "K",
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
	Callback = function(v)
		getgenv().AuraRange = v
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
		getgenv().HitAmount = tonumber(text) or 5
	end,
})


--====================================================--
-- Toggle: Follower Kill Aura (NO WARP)
--====================================================--
Tab:CreateToggle({
	Name = "Minion Kill Aura",
	CurrentValue = false,
	Callback = function(state)
		getgenv().KillAura = state

		if state then
			task.spawn(function()
				while getgenv().KillAura do

					-- หาเป้าใหม่
					if IsEnemyDead(AuraTarget) then
						AuraTarget = GetNearestEnemy()
					end

					-- ส่งเป้าไปให้ลูกน้องตี
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
