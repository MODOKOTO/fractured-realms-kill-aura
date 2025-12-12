--grimcity was here
local Client = game:GetService("Players").LocalPlayer

-- ค่า Default
getgenv().AuraRange = 20
getgenv().HitAmount = 5

getgenv().KillAura = false
getgenv().AutoWarp = false

local CurrentEnemy = nil  -- ใช้เก็บศัตรูที่กำลังตีอยู่


----------------------------------------------
-- ฟังก์ชันหา Enemy ใกล้สุด
----------------------------------------------
local function GetNearestEnemy()
    local Character = Client.Character
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Nearest
    local ClosestAmount = 9e9

    for _, Folder in workspace.ClickCoins:GetChildren() do
        local Children = Folder:GetChildren()
        if #Children == 0 then continue end

        for _, Enemy in Children do
            local HRP = Enemy:FindFirstChild("HumanoidRootPart")
            if HRP then
                local Magnitude = (HRP.Position - HumanoidRootPart.Position).Magnitude
                if Magnitude < ClosestAmount then
                    ClosestAmount = Magnitude
                    Nearest = Enemy
                end
            end
        end
    end

    return Nearest
end


----------------------------------------------
-- Rayfield UI Setup
----------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Fractured Realms - Kill Aura",
   LoadingTitle = "Fractured Realms - Kill Aura",
   LoadingSubtitle = "by Grimcity",
   ToggleUIKeybind = "K",
})

local Tab = Window:CreateTab("Main", "swords")

----------------------------------------------------
-- UI Slider ระยะ
----------------------------------------------------
Tab:CreateSlider({
    Name = "Kill Aura Range",
    Range = {5, 100},
    Increment = 1,
    CurrentValue = getgenv().AuraRange,
    Callback = function(Value)
        getgenv().AuraRange = Value
    end,
})

----------------------------------------------------
-- UI ตั้งจำนวน Hit
----------------------------------------------------
Tab:CreateInput({
    Name = "Hit Amount (Default = 5)",
    PlaceholderText = "ใส่จำนวนครั้ง",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local Num = tonumber(Text)
        if Num then
            getgenv().HitAmount = Num
        else
            getgenv().HitAmount = 5
        end
    end,
})


----------------------------------------------------
-- ⭐ Toggle: Kill Aura แบบไม่วาร์ป ⭐
----------------------------------------------------
Tab:CreateToggle({
   Name = "Kill Aura (No Warp)",
   CurrentValue = false,
   Callback = function(Value)
        getgenv().KillAura = Value

        if Value then
            -- เริ่ม Kill Aura
            task.spawn(function()
                while getgenv().KillAura do

                    -- ตรวจสอบศัตรูที่กำลังตีอยู่
                    if not CurrentEnemy or not CurrentEnemy:FindFirstChild("HumanoidRootPart") then
                        CurrentEnemy = GetNearestEnemy()
                    end

                    if CurrentEnemy then
                        -- ถ้าศัตรูตาย หาใหม่ทันที
                        local Hum = CurrentEnemy:FindFirstChildOfClass("Humanoid")
                        if Hum and Hum.Health <= 0 then
                            CurrentEnemy = GetNearestEnemy()
                        end

                        -- ตีศัตรู
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



----------------------------------------------------
-- ⭐ Toggle: Auto Warp (วาร์ปไปที่มอนอย่างเดียว) ⭐
----------------------------------------------------
Tab:CreateToggle({
   Name = "Auto Warp to Enemy",
   CurrentValue = false,
   Callback = function(Value)
        getgenv().AutoWarp = Value

        if Value then
            task.spawn(function()
                while getgenv().AutoWarp do

                    -- เลือกศัตรูที่จะวาร์ปไปหา
                    if not CurrentEnemy or not CurrentEnemy:FindFirstChild("HumanoidRootPart") then
                        CurrentEnemy = GetNearestEnemy()
                    end

                    local Root = Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")
                    local ER = CurrentEnemy and CurrentEnemy:FindFirstChild("HumanoidRootPart")

                    if Root and ER then
                        -- วาร์ปหลังมอน 2 studs
                        Root.CFrame = ER.CFrame * CFrame.new(0, 0, -2)
                    end

                    task.wait(0.15)
                end
            end)
        end
   end,
})
