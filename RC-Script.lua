local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
local Options = Library.Options
local Toggles = Library.Toggles
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

local function isInBattle()
    return workspace:FindFirstChild("RouteNight") ~= nil or workspace:FindFirstChild("RouteDay") ~= nil
end

local function findMGrass()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local grass, closestDist = nil, math.huge
    for _, chunk in ipairs(GetChunks()) do
        for _, obj in ipairs(chunk:GetDescendants()) do
            if obj.Name == "Grass" and obj:IsA("BasePart") and obj.Parent and obj.Parent.Name == "MGrass" then
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    grass = obj
                end
            end
        end
    end
    return grass
end

local function resetCamera()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    if hum then cam.CameraSubject = hum end
end

local function showChar()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.LocalTransparencyModifier = 0 end)
        end
    end
end

local function hideChar()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.LocalTransparencyModifier = 1 end)
        end
    end
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
-- AUTO BATTLE
-- ============================================================
local AutoBattleGroup = Tabs.Main:AddRightGroupbox('Auto Battle')
local autoBattleEnabled = false

-- PP tracking table: ppTracker[slotNumber] = remaining PP this session
local ppTracker = {nil, nil, nil, nil}

local function resetPPTracker()
    ppTracker = {nil, nil, nil, nil}
end

-- Reads current PP for a move slot from the battle UI
-- Returns current PP or nil if it can't find it
local function readMovePP(battleGui, slotIndex)
    -- Gather all visible PP-related labels, sorted left-to-right
    local ppLabels = {}
    for _, obj in ipairs(battleGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            local t = obj.Text or ""
            -- Match patterns like "15/20", "PP: 15/20", "15 / 20"
            if t:match("%d+%s*/%s*%d+") then
                table.insert(ppLabels, obj)
            end
        end
    end
    table.sort(ppLabels, function(a, b)
        return a.AbsolutePosition.X < b.AbsolutePosition.X
    end)
    local label = ppLabels[slotIndex]
    if label then
        local cur = label.Text:match("(%d+)%s*/%s*%d+")
        if cur then return tonumber(cur) end
    end
    return nil
end

-- Finds and clicks a move button by slot index (1-4, sorted left to right)
local function clickMoveSlot(battleGui, slotIndex)
    local buttons = {}
    for _, obj in ipairs(battleGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
            local name = obj.Name:lower()
            if name:find("move") or name:find("attack") or name:find("skill") then
                table.insert(buttons, obj)
            end
        end
    end
    table.sort(buttons, function(a, b)
        return a.AbsolutePosition.X < b.AbsolutePosition.X
    end)
    local btn = buttons[slotIndex]
    if btn then
        btn:Activate()
        return true
    end
    return false
end

-- Main auto move function called each turn
local function autoUseMove()
    if not Toggles.AutoMove.Value then return end

    task.spawn(function()
        local playerGui = LocalPlayer.PlayerGui
        local mainGui = playerGui:FindFirstChild("MainGui")
        local battleGui = mainGui and mainGui:FindFirstChild("BattleGui")
        if not battleGui then
            warn("[AutoMove] No BattleGui found")
            return
        end

        -- Wait for and click the Fight button first
        local fightBtn = nil
        local waited = 0
        while not fightBtn and waited < 5 do
            for _, obj in ipairs(battleGui:GetDescendants()) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                    if obj.Name:lower():find("fight") then
                        fightBtn = obj
                        break
                    end
                end
            end
            task.wait(0.1)
            waited += 0.1
        end

        if not fightBtn then
            warn("[AutoMove] Fight button not found")
            return
        end

        fightBtn:Activate()
        task.wait(0.4)

        -- Build the priority list from the dropdown selection
        -- Options.MovePriority.Value is a string like "Move 1"
        -- We'll try slots in the user's chosen priority order
        local slotMap = {["Move 1"] = 1, ["Move 2"] = 2, ["Move 3"] = 3, ["Move 4"] = 4}

        -- Get ordered priority from the dropdown value
        -- The dropdown stores the selected value as a string
        local selectedValue = Options.MovePriority.Value
        local orderedSlots = {}

        -- Primary slot from dropdown
        local primarySlot = slotMap[selectedValue] or 1
        table.insert(orderedSlots, primarySlot)

        -- Append remaining slots as fallback in order
        for i = 1, 4 do
            if i ~= primarySlot then
                table.insert(orderedSlots, i)
            end
        end

        -- Try each slot in priority order, skipping ones with 0 PP
        for _, slot in ipairs(orderedSlots) do
            -- Read PP for this slot
            local pp = readMovePP(battleGui, slot)

            -- Update our tracker
            if pp ~= nil then
                ppTracker[slot] = pp
            end

            -- Skip if we know this slot is out of PP
            if ppTracker[slot] ~= nil and ppTracker[slot] <= 0 then
                print("[AutoMove] Slot", slot, "is out of PP, skipping")
            else
                -- Try to click it
                local success = clickMoveSlot(battleGui, slot)
                if success then
                    print("[AutoMove] Used move slot", slot)
                    -- Decrement our local PP tracker
                    if ppTracker[slot] ~= nil then
                        ppTracker[slot] = ppTracker[slot] - 1
                    end
                    return
                end
            end
        end

        warn("[AutoMove] All move slots exhausted or unavailable!")
        Notify("Auto Move", "All moves out of PP!", 4)
    end)
end

local function doEncounter()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    local camera = workspace.CurrentCamera
    if not hrp then return false end

    local grass = findMGrass()
    if not grass then
        Notify("Auto Battle", "No MGrass found!", 3)
        return false
    end

    local origin = hrp.CFrame
    local battleStarted = false
    local restored = false
    local conn
    local battleWatcher
    local battleEndWatcher

    local function fullyRestore()
        showChar()
        resetCamera()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if h then h.Anchored = false end
    end

    local function restorePosition()
        if restored then return end
        restored = true
        if conn then conn:Disconnect() conn = nil end
        if battleWatcher then battleWatcher:Disconnect() battleWatcher = nil end
        hrp.Anchored = false
        hrp.CFrame = origin
        resetCamera()
        showChar()
    end

    hideChar()

    local jitterOrigin = CFrame.new(grass.Position.X, grass.Position.Y + 3, grass.Position.Z)

    battleWatcher = workspace.ChildAdded:Connect(function(child)
        if child.Name == "RouteNight" or child.Name == "RouteDay" then
            battleStarted = true
            restorePosition()
            -- Fire auto move after battle UI is ready
            task.spawn(function()
                task.wait(1.2)
                autoUseMove()
            end)
            battleEndWatcher = workspace.ChildRemoved:Connect(function(removed)
                if removed.Name == "RouteNight" or removed.Name == "RouteDay" then
                    if battleEndWatcher then battleEndWatcher:Disconnect() battleEndWatcher = nil end
                    task.wait(0.3)
                    fullyRestore()
                end
            end)
        end
    end)

    camera.CameraType = Enum.CameraType.Scriptable

    local step = 0
    conn = RunService.Heartbeat:Connect(function()
        if restored then return end
        step += 1
        hrp.Anchored = true
        camera.CameraType = Enum.CameraType.Scriptable
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end
        local offset = step % 8
        if offset == 0 then
            hrp.CFrame = jitterOrigin
        elseif offset == 1 then
            hrp.CFrame = jitterOrigin * CFrame.new(4, 0, 0)
        elseif offset == 2 then
            hrp.CFrame = jitterOrigin * CFrame.new(0, 0, 4)
        elseif offset == 3 then
            hrp.CFrame = jitterOrigin * CFrame.new(-4, 0, 0)
        elseif offset == 4 then
            hrp.CFrame = jitterOrigin * CFrame.new(0, 0, -4)
        elseif offset == 5 then
            hrp.CFrame = jitterOrigin * CFrame.new(4, 0, 4)
        elseif offset == 6 then
            hrp.CFrame = jitterOrigin * CFrame.new(-4, 0, 4)
        else
            hrp.CFrame = jitterOrigin * CFrame.new(4, 0, -4)
        end
    end)

    local elapsed = 0
    while not restored and elapsed < 6 and autoBattleEnabled do
        task.wait(0.1)
        elapsed += 0.1
    end

    if not restored then
        if conn then conn:Disconnect() conn = nil end
        if battleWatcher then battleWatcher:Disconnect() battleWatcher = nil end
        if battleEndWatcher then battleEndWatcher:Disconnect() battleEndWatcher = nil end
        hrp.Anchored = false
        hrp.CFrame = origin
        fullyRestore()
    end

    return battleStarted
end

AutoBattleGroup:AddToggle('AutoBattle', {
    Text = 'Auto Battle',
    Default = false,
    Callback = function(state)
        autoBattleEnabled = state
        if not state then
            if not isInBattle() then
                resetCamera()
                showChar()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            end
            Notify("Auto Battle", "Stopped!", 3)
            return
        end

        Notify("Auto Battle", "Started!", 3)
        task.spawn(function()
            while autoBattleEnabled do
                if isInBattle() then
                    repeat task.wait(0.3) until not isInBattle() or not autoBattleEnabled
                    task.wait(0.5)
                end

                if not autoBattleEnabled then break end

                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
                showChar()
                task.wait(0.2)

                doEncounter()

                if not autoBattleEnabled then break end

                local waitForBattle = 0
                repeat
                    task.wait(0.2)
                    waitForBattle += 0.2
                until isInBattle() or waitForBattle >= 3 or not autoBattleEnabled

                repeat task.wait(0.3) until not isInBattle() or not autoBattleEnabled
                task.wait(0.8)
            end

            if not isInBattle() then
                showChar()
                resetCamera()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            end
        end)
    end
})

AutoBattleGroup:AddToggle('AutoMove', {
    Text = 'Auto Use Move',
    Default = false,
    Callback = function(state)
        if state then
            resetPPTracker()
            Notify("Auto Move", "Enabled!", 3)
        else
            Notify("Auto Move", "Disabled!", 3)
        end
    end
})

AutoBattleGroup:AddDropdown('MovePriority', {
    Text = 'Move Priority',
    Values = {'Move 1', 'Move 2', 'Move 3', 'Move 4'},
    Default = 1, -- defaults to "Move 1"
})

AutoBattleGroup:AddButton('Reset PP Tracker', function()
    resetPPTracker()
    Notify("Auto Move", "PP tracker reset!", 3)
end)

-- ============================================================
-- MISC TAB
-- ============================================================
local MiscLeft = Tabs.Misc:AddLeftGroupbox('Player')
local MiscRight = Tabs.Misc:AddRightGroupbox('Server')

MiscLeft:AddSlider('WalkSpeed', {
    Text = 'Walk Speed',
    Default = 16,
    Min = 16,
    Max = 30,
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
