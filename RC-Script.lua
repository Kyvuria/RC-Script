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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
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
            for _, chunk in ipairs(GetChunks()) do stripTrainers(chunk) end
            trainerWatcher = workspace.ChildAdded:Connect(function(child)
                if child.Name:lower():find("chunk") then
                    task.wait(0.2)
                    stripTrainers(child)
                end
            end)
            Notify("Trainers", "Hid " .. count .. " trainer(s)!", 3)
        else
            if trainerWatcher then trainerWatcher:Disconnect() trainerWatcher = nil end
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

local savedGrass = {}
local grassWatcher = nil
local grassKeywords = {"grass", "#grass", "tallgrass", "talgrass", "encounter"}

local function isGrass(name)
    local nameLower = name:lower()
    for _, keyword in ipairs(grassKeywords) do
        if nameLower == keyword or nameLower:find(keyword) then return true end
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
            for _, chunk in ipairs(GetChunks()) do stripGrass(chunk) end
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
            end
        else
            if grassWatcher then grassWatcher:Disconnect() grassWatcher = nil end
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
            for _, chunk in ipairs(GetChunks()) do stripObstacles(chunk) end
            obstacleWatcher = workspace.ChildAdded:Connect(function(child)
                if child.Name:lower():find("chunk") then
                    task.wait(0.2)
                    stripObstacles(child)
                end
            end)
            Notify("Obstacles", "Removed " .. count .. " obstacle(s)!", 3)
        else
            if obstacleWatcher then obstacleWatcher:Disconnect() obstacleWatcher = nil end
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
local MiscRight = Tabs.Misc:AddRightGroupbox('Server')

MiscLeft:AddSlider('WalkSpeed', {
    Text = 'Walk Speed',
    Default = 16,
    Min = 16,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end
})

-- ============================================================
-- NOCLIP
-- ============================================================
local noclipEnabled = false
local noclipConnection = nil
local savedCollisions = {}

local function getOriginalCollisions(char)
    local saved = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then saved[part] = part.CanCollide end
    end
    return saved
end

local function startNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    savedCollisions = getOriginalCollisions(char)
    noclipEnabled = true
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function stopNoclip()
    noclipEnabled = false
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.1, 0) end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local original = savedCollisions[part]
            part.CanCollide = (original ~= nil) and original or true
        end
    end
    savedCollisions = {}
    task.defer(function()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end)
end

MiscLeft:AddToggle('Noclip', {
    Text = 'Noclip',
    Default = false,
    Callback = function(state)
        if state then startNoclip() Notify("Noclip", "Noclip enabled!", 3)
        else stopNoclip() Notify("Noclip", "Noclip disabled!", 3) end
    end
})

-- ============================================================
-- AUTO ENCOUNTER
-- Teleports you into grass, waits 2 full seconds so the server
-- has time to register your position and tick the step counter,
-- then snaps you back. Repeats until a battle starts.
-- Battle detection checks ScreenGui only (skips Folders etc).
-- ============================================================
local autoEncounterRunning = false

local function getClosestGrass()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local closest, closestDist = nil, math.huge
    for _, chunk in ipairs(GetChunks()) do
        for _, obj in ipairs(chunk:GetDescendants()) do
            if (obj.Name == "Grass" or obj.Name == "MGrass") and obj:IsA("BasePart") then
                local dist = hrp and (obj.Position - hrp.Position).Magnitude or 0
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end
    return closest
end

local function isInBattle()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local n = gui.Name:lower()
            if (n:find("battle") or n:find("fight") or n:find("pokemon")) and gui.Enabled then
                return true
            end
        end
    end
    return false
end

MiscLeft:AddToggle('AutoEncounter', {
    Text = 'Auto Encounter',
    Default = false,
    Callback = function(state)
        if state then
            local grass = getClosestGrass()
            if not grass then
                Notify("Auto Encounter", "No grass found on this route!", 3)
                return
            end

            -- Clone a grass part and sink it deep underground below the player
            -- completely invisible to everyone, only the server sees it
            local ghostGrass = grass:Clone()
            ghostGrass.Name = "Grass"
            ghostGrass.Anchored = true
            ghostGrass.CanCollide = false
            ghostGrass.Transparency = 1
            ghostGrass.Size = Vector3.new(20, 1, 20)
            ghostGrass.Parent = workspace

            autoEncounterRunning = true
            Notify("Auto Encounter", "Running!", 3)

            task.spawn(function()
                while autoEncounterRunning do
                    if isInBattle() then
                        task.wait(0.5)
                    else
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            -- Keep ghost grass directly under player, 2000 studs underground
                            -- so it is completely invisible but server still detects overlap
                            local underPos = Vector3.new(hrp.Position.X, hrp.Position.Y - 2000, hrp.Position.Z)
                            ghostGrass.CFrame = CFrame.new(underPos)

                            local realCFrame = hrp.CFrame

                            -- Flicker player down into ghost grass for 3 frames
                            hrp.CFrame = CFrame.new(underPos.X, underPos.Y + 1, underPos.Z)
                            task.wait()
                            task.wait()
                            task.wait()

                            -- Snap back instantly
                            if hrp and hrp.Parent then
                                hrp.CFrame = realCFrame
                            end

                            task.wait(0.2)
                        else
                            task.wait(0.5)
                        end
                    end
                end

                -- Clean up ghost grass when stopped
                if ghostGrass and ghostGrass.Parent then
                    ghostGrass:Destroy()
                end
            end)
        else
            autoEncounterRunning = false
            Notify("Auto Encounter", "Stopped!", 3)
        end
    end
})

-- CLICK TP
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
            if clickTpConnection then clickTpConnection:Disconnect() clickTpConnection = nil end
            Notify("Click TP", "Click TP disabled!", 3)
        end
    end
})

-- ============================================================
-- SERVER BUTTONS
-- ============================================================
MiscRight:AddButton('Rejoin', function()
    Notify("Rejoin", "Rejoining...", 2)
    task.wait(0.5)
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

MiscRight:AddButton('Server Hop', function()
    Notify("Server Hop", "Finding a new server...", 3)
    task.spawn(function()
        local placeId = game.PlaceId
        local currentJobId = game.JobId
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.id ~= currentJobId and server.playing < server.maxPlayers then
                    local ok = pcall(function()
                        TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                    end)
                    if ok then return end
                end
            end
        end
        Notify("Server Hop", "No servers found, rejoining...", 3)
        task.wait(1)
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
end)

MiscRight:AddButton('Join Lowest Server', function()
    Notify("Join Lowest", "Finding lowest pop server...", 3)
    task.spawn(function()
        local placeId = game.PlaceId
        local currentJobId = game.JobId
        local blacklist = {}
        local maxAttempts = 5

        local function fetchServers()
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
                ))
            end)
            if success and result and result.data then return result.data end
            return nil
        end

        local function getSortedServers(servers)
            local valid = {}
            for _, server in ipairs(servers) do
                if server.id ~= currentJobId
                    and not blacklist[server.id]
                    and server.playing < server.maxPlayers
                    and server.playing >= 0
                then
                    table.insert(valid, server)
                end
            end
            table.sort(valid, function(a, b) return a.playing < b.playing end)
            return valid
        end

        for attempt = 1, maxAttempts do
            local servers = fetchServers()
            if not servers then Notify("Join Lowest", "Could not fetch server list.", 3) return end
            local sorted = getSortedServers(servers)
            if #sorted == 0 then Notify("Join Lowest", "No valid servers found.", 3) return end
            local target = sorted[1]
            Notify("Join Lowest", "Attempt " .. attempt .. ": joining server with " .. target.playing .. " player(s)...", 4)
            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, target.id, LocalPlayer)
            end)
            if ok then return else blacklist[target.id] = true task.wait(1) end
        end

        Notify("Join Lowest", "All attempts failed, rejoining current server...", 3)
        task.wait(1)
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
end)

Notify("Requiem", "Roria Conquest loaded!", 3)
