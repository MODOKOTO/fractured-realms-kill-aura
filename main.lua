--====================================================--
-- Fractured Realms - Manual Monster Selector + Minion Control
--====================================================--

local Players = game:GetService("Players")
local Client = Players.LocalPlayer

--========================--
-- GLOBAL STATE
--========================--
getgenv().SelectedZone = "Zone1"
getgenv().SelectedMonster = nil

--========================--
-- UTIL
--========================--
local function GetZones()
	local zones = {}
	for _, z in ipairs(workspace.ClickCoins:GetChildren()) do
		table.insert(zones, z.Name)
	end
	return zones
end

local function GetMonstersInZone(zoneName)
	local list = {}
	local zone = workspace.ClickCoins:FindFirstChild(zoneName)
	if not zone then return list end

	for _, m in ipairs(zone:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("ClickPart") then
			table.insert(list, m.Name)
		end
	end
	return list
end

local function GetMonsterByName(zone, name)
	local z = workspace.ClickCoins:FindFirstChild(zone)
	if not z then return nil end
	return z:FindFirstChild(name)
end

--========================--
-- MINION HANDLER
--========================--
local function ApplyTargetToMinions(enemyName)
	local folder = workspace.Player_Followers:FindFirstChild(Client.Name .. "_Followers")
	if not folder then return end

	for _, minion in ipairs(folder:GetChildren()) do
		local hum = minion:FindFirstChildOfClass("Humanoid")
		local targetFolder = minion:FindFirstChild("TargetFolder")

		if hum then
			hum.MaxHealth = 999999
			hum.Health = hum.MaxHealth
		end

		if targetFolder and targetFolder:FindFirstChild("NewTarget") then
			targetFolder.NewTarget.Value = enemyName
			if targetFolder:FindFirstChild("OldTarget") then
				targetFolder.OldTarget.Value = enemyName
			end
		end
	end
end

--========================--
-- UI
--========================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
	Name = "Fractured Realms - Monster Control",
	ToggleUIKeybind = "K",
})

local Tab = Window:CreateTab("Selector", "swords")

--========================--
-- Zone Dropdown
--========================--
Tab:CreateDropdown({
	Name = "Select Zone",
	Options = GetZones(),
	CurrentOption = getgenv().SelectedZone,
	Callback = function(v)
		getgenv().SelectedZone = v
	end,
})

--========================--
-- Monster Dropdown
--========================--
Tab:CreateDropdown({
	Name = "Select Monster",
	Options = {},
	Callback = function(v)
		getgenv().SelectedMonster = v
	end,
})

-- Refresh monsters when zone changes
Tab:CreateButton({
	Name = "Refresh Monster List",
	Callback = function()
		local monsters = GetMonstersInZone(getgenv().SelectedZone)
		Rayfield:Notify({
			Title = "Monster List Updated",
			Content = "Found " .. #monsters .. " monsters",
			Duration = 2,
		})
	end,
})

--========================--
-- Warp Button (Player Only)
--========================--
Tab:CreateButton({
	Name = "Warp To Selected Monster",
	Callback = function()
		if not getgenv().SelectedMonster then return end
		local monster = GetMonsterByName(getgenv().SelectedZone, getgenv().SelectedMonster)
		if monster and monster:FindFirstChild("HumanoidRootPart") then
			Client.Character.HumanoidRootPart.CFrame =
				monster.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
		end
	end,
})

--========================--
-- Minion Attack Button
--========================--
Tab:CreateButton({
	Name = "Send Minions To Attack",
	Callback = function()
		if not getgenv().SelectedMonster then return end
		ApplyTargetToMinions(getgenv().SelectedMonster)
	end,
})
