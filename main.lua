--====================================================--
--   Fractured Realms - Pure Minion Kill Aura
--   + Auto Switch Target System (STABLE)
--====================================================--

local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

--====================--
-- CONFIG (GLOBAL)
--====================--
getgenv().AuraRange = 20
getgenv().HitAmount = 5
getgenv().KillAura = false

getgenv().AutoSwitchTarget = false
getgenv().SwitchInterval = 3 -- seconds


--====================--
-- STATE
--====================--
local AuraTarget = nil
local LastSwitchTime = 0


--====================--
-- Enemy Dead Checker
--====================--
local function IsEnemyDead(enemy)
	if not enemy or not enemy.Parent then return true end

	local hum = enemy:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return true end

	if enemy:GetAttribute("Dead") == true then return true end

	return false
end


--====================--
-- Get Nearest Enemy
--====================--
local function GetNearestEnemy()
	local char = Client.Character
	if not char then return nil end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearest, closest = nil, math.huge

	for _, zone in ipairs(workspace.ClickCoins:GetChildren()) do
		for _, enemy in ipairs(zone:GetChildren()) do
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


--====================--
-- Assign Target To Minions
--====================--
local function CommandMinions(enemy)
	if not enemy then return end

	for i = 1, (getgenv().HitAmount or 5) do
		RS.Remotes.FollowerAttack.AssignTarget:FireServer(enemy, true)
	end
end


--====================--
-- UI (Rayfield)
--====================--
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
	Callback = function(text)
		getgenv().SwitchInterval = tonumber(text) or 3
	end,
})


--====================--
-- Kill Aura Loop
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

				-- 1️⃣ เป้าไม่มี หรือ มอนตาย → หาใหม่ทันที
				if IsEnemyDead(AuraTarget) then
					AuraTarget = GetNearestEnemy()
					LastSwitchTime = now
				end

				-- 2️⃣ Auto Switch ตามเวลา
				if getgenv().AutoSwitchTarget and AuraTarget then
					if now - LastSwitchTime >= getgenv().SwitchInterval then
						local newTarget = GetNearestEnemy()
						if newTarget ~= AuraTarget then
							AuraTarget = newTarget
						end
						LastSwitchTime = now
					end
				end

				-- 3️⃣ สั่ง minion ตี
				if AuraTarget then
					CommandMinions(AuraTarget)
				end

				task.wait(0.1)
			end
		end)
	end,
})
