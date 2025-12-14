--====================================================--
--   Fractured Realms - Pure Minion Kill Aura
--   + Auto Switch Target System
--====================================================--

local Client = game:GetService("Players").LocalPlayer

-- CONFIG
getgenv().AuraRange = 20
getgenv().HitAmount = 5
getgenv().KillAura = false

getgenv().AutoSwitchTarget = false
getgenv().SwitchInterval = 3 -- วินาที

local AuraTarget = nil
local LastSwitchTime = 0


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
	local char = Client.Character
	if not char then return nil end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest, closest = nil, math.huge

	for _, folder in workspace.ClickCoins:GetChildren() do
		for _, enemy in folder:GetChildren() do
			local hrp = enemy:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist <= getgenv().AuraRange and dist < closest then
					closest = dist
					nearest = enemy
				end
			end
		end
	end

	return nearest
end


--====================================================--
-- UI
--====================================================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Kill Aura",
	ToggleUIKeybind = "K",
})

local Tab = Window:CreateTab("Main", "swords")


Tab:CreateSlider({
	Name = "Kill Aura Range",
	Range = {5, 100},
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
	Callback = function(text)
		getgenv().HitAmount = tonumber(text) or 5
	end,
})

-- 🔄 Auto Switch Toggle
Tab:CreateToggle({
	Name = "Auto Switch Target",
	CurrentValue = false,
	Callback = function(v)
		getgenv().AutoSwitchTarget = v
	end,
})

-- ⏱ Switch Interval
Tab:CreateInput({
	Name = "Switch Interval (Seconds)",
	PlaceholderText = "Default = 3",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		getgenv().SwitchInterval = tonumber(text) or 3
	end,
})


--====================================================--
-- Kill Aura Loop
--====================================================--
Tab:CreateToggle({
	Name = "Minion Kill Aura",
	CurrentValue = false,
	Callback = function(state)
		getgenv().KillAura = state

		if state then
			task.spawn(function()
				LastSwitchTime = tick()

				while getgenv().KillAura do
					local now = tick()

					-- เปลี่ยนเป้าเมื่อมอนตาย
					if IsEnemyDead(AuraTarget) then
						AuraTarget = GetNearestEnemy()
						LastSwitchTime = now
					end

					-- เปลี่ยนเป้าตามเวลา
					if getgenv().AutoSwitchTarget then
						if now - LastSwitchTime >= getgenv().SwitchInterval then
							AuraTarget = GetNearestEnemy()
							LastSwitchTime = now
						end
					end

					-- สั่ง follower ตี
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
