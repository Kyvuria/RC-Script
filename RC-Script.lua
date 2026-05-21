local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
local Window = Library:CreateWindow({
    Title = 'Requiem | Roria Conquest',
    Center = true,
    AutoShow = true,
})
local Tabs = {
    Main = Window:AddTab('Main'),
    Misc = Window:AddTab('Misc'),
}
local function Notify(title, content, duration)
    Library:Notify(title .. '\n' .. content, duration or 3)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function GetChunks()
    local chunks = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name:lower():find("chunk") then
            table.insert(chunks, child)
        end
    end
    return chunks
end

-- ============================================================
-- POKEBALLS
-- ============================================================
local MainLeft = Tabs.Main:AddLeftGroupbox('Pokeballs')
MainLeft:AddButton('TP Pokeballs To You', function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Notify("TP Pokeballs", "No character found!", 3)
        return
    end

    local count = 0
    local spread = 0
    local hrpPos = hrp.Position

    for _, chunk in ipairs(GetChunks()) do
        for _, item in ipairs(chunk:GetChildren()) do
            if item.Name == "#Item" and item:IsA("Model") then
                local parts = {}
                for _, part in ipairs(item:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                        table.insert(parts, part)
                    end
                end
                local angle = (spread * (math.pi * 2)) / 8
                local offset = Vector3.new(math.cos(angle) * 3, 0.5, math.sin(angle) * 3)
                item:PivotTo(CFrame.new(hrpPos + offset))
                for _, part in ipairs(parts) do
                    part.Anchored = true
                end
                count += 1
                spread += 1
            end
        end
    end

    if count > 0 then
        Notify("TP Pokeballs", "Teleported " .. count .. " pokeball(s) to you!", 4)
    else
        Notify("TP Pokeballs", "No pokeballs found on this route!", 3)
    end
end)

-- ============================================================
-- WORLD
-- ============================================================
local WorldLeft = Tabs.Main:AddLeftGroupbox('World')

-- DELETE TRAINERS
local savedTrainers = {}
local trainerWatcher = nil

WorldLeft:AddToggle('DeleteTrainers', {
    Text = 'Delete Trainers',
    Default = false,
    Callback = function(state)
        if state then
            savedTrainers = {}
            local count = 0

            local function stripTrainers(chunk)
                for _, obj in ipairs(chunk:GetChildren()) do
                    if obj:FindFirstChild("#Battle") then
                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        if hrp then
                            table.insert(savedTrainers, {
                                hrp = hrp,
                                originalCFrame = hrp.CFrame,
                                humanoid = hum,
                            })
                            hrp.CFrame = CFrame.new(hrp.CFrame.X, -10000, hrp.CFrame.Z)
                            if hum then hum.WalkSpeed = 0 end
                            count += 1
                        end
                    end
                end
            end

            for _, chunk in ipairs(GetChunks()) do
                stripTrainers(chunk)
            end

            trainerWatcher = workspace.ChildAdded:Connect(function(child)
                if child.Name:lower():find("chunk") then
                    task.wait(0.2)
                    stripTrainers(child)
                end
            end)

            Notify("Trainers", "Hid " .. count .. " trainer(s)!", 3)
        else
            if trainerWatcher then
                trainerWatcher:Disconnect()
                trainerWatcher = nil
            end
            local count = 0
            for _, entry in ipairs(savedTrainers) do
                if entry.hrp then
                    entry.hrp.CFrame = entry.originalCFrame
                    if entry.humanoid then
                        entry.humanoid.WalkSpeed = 16
                        entry.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                    count += 1
                end
            end
            savedTrainers = {}
            Notify("Trainers", "Restored " .. count .. " trainer(s)!", 3)
        end
    end
})

-- DELETE GRASS
local savedGrass = {}
local grassWatcher = nil
local grassKeywords = {"grass", "#grass", "tallgrass", "talgrass", "encounter"}

local function isGrass(name)
    local nameLower = name:lower()
    for _, keyword in ipairs(grassKeywords) do
        if nameLower == keyword or nameLower:find(keyword) then
            return true
        end
    end
    return false
end

WorldLeft:AddToggle('DeleteGrass', {
    Text = 'Delete Grass',
    Default = false,
    Callback = function(state)
        if state then
            savedGrass = {}
            local count = 0

            local function stripGrass(chunk)
                for _, obj in ipairs(chunk:GetDescendants()) do
                    if obj and obj.Parent and isGrass(obj.Name) then
                        table.insert(savedGrass, { parent = obj.Parent, object = obj })
                        obj.Parent = nil
                        count += 1
                    end
                end
            end

            for _, chunk in ipairs(GetChunks()) do
                stripGrass(chunk)
            end

            grassWatcher = workspace.ChildAdded:Connect(function(child)
                if child.Name:lower():find("chunk") then
                    task.wait(0.2)
                    stripGrass(child)
                end
            end)

            if count > 0 then
                Notify("Grass", "Hid " .. count .. " grass object(s)!", 3)
            else
                Notify("Grass", "No grass found! Check console (F9) for names.", 4)
                for _, chunk in ipairs(GetChunks()) do
                    for _, obj in ipairs(chunk:GetChildren()) do
                        print("[Grass Debug]", obj.Name, obj.ClassName)
                    end
                end
            end
        else
            if grassWatcher then
                grassWatcher:Disconnect()
                grassWatcher = nil
            end
            local count = 0
            for _, entry in ipairs(savedGrass) do
                if entry.object and entry.parent then
                    entry.object.Parent = entry.parent
                    count += 1
                end
            end
            savedGrass = {}
            Notify("Grass", "Restored " .. count .. " grass object(s)!", 3)
        end
    end
})

-- DELETE OBSTACLES
local savedObstacles = {}
local obstacleWatcher = nil

WorldLeft:AddToggle('DeleteObstacles', {
    Text = 'Delete Obstacles',
    Default = false,
    Callback = function(state)
        if state then
            savedObstacles = {}
            local count = 0

            local function stripObstacles(chunk)
                for _, obj in ipairs(chunk:GetChildren()) do
                    if obj.Name == "HackableShrubbery" then
                        table.insert(savedObstacles, { parent = obj.Parent, object = obj })
                        obj.Parent = nil
                        count += 1
                    end
                end
            end

            for _, chunk in ipairs(GetChunks()) do
                stripObstacles(chunk)
            end

            obstacleWatcher = workspace.ChildAdded:Connect(function(child)
                if child.Name:lower():find("chunk") then
                    task.wait(0.2)
                    stripObstacles(child)
                end
            end)

            Notify("Obstacles", "Removed " .. count .. " obstacle(s)!", 3)
        else
            if obstacleWatcher then
                obstacleWatcher:Disconnect()
                obstacleWatcher = nil
            end
            local count = 0
            for _, entry in ipairs(savedObstacles) do
                if entry.object and entry.parent then
                    entry.object.Parent = entry.parent
                    count += 1
                end
            end
            savedObstacles = {}
            Notify("Obstacles", "Restored " .. count .. " obstacle(s)!", 3)
        end
    end
})

-- ============================================================
-- MISC TAB
-- ============================================================
local MiscLeft = Tabs.Misc:AddLeftGroupbox('Player')

-- WALKSPEED SLIDER
MiscLeft:AddSlider('WalkSpeed', {
    Text = 'Walk Speed',
    Default = 16,
    Min = 16,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = value
        end
    end
})

-- NOCLIP
local noclipConnection = nil

MiscLeft:AddToggle('Noclip', {
    Text = 'Noclip',
    Default = false,
    Callback = function(state)
        if state then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            Notify("Noclip", "Noclip enabled!", 3)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            Notify("Noclip", "Noclip disabled!", 3)
        end
    end
})

-- CLICK TP (Hold Ctrl + Left Click)
local clickTpConnection = nil

MiscLeft:AddToggle('ClickTP', {
    Text = 'Click TP (Ctrl + Click)',
    Default = false,
    Callback = function(state)
        if state then
            clickTpConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local camera = workspace.CurrentCamera
                        local unitRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {char}
                        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
                        if result then
                            hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
                        end
                    end
                end
            end)
            Notify("Click TP", "Hold Ctrl + Click to teleport!", 3)
        else
            if clickTpConnection then
                clickTpConnection:Disconnect()
                clickTpConnection = nil
            end
            Notify("Click TP", "Click TP disabled!", 3)
        end
    end
})

Notify("Requiem", "Roria Conquest loaded!", 3)
