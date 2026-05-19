local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()

local Window = Library:CreateWindow({
    Title = 'Requiem | Roria Conquest',
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab('Main'),
}

local function Notify(title, content, duration)
    Library:Notify(title .. '\n' .. content, duration or 3)
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

    for _, chunk in ipairs(workspace:GetChildren()) do
        if chunk.Name:lower():find("chunk") then
            for _, item in ipairs(chunk:GetChildren()) do
                if item.Name == "#Item" and item:IsA("Model") then
                    for _, part in ipairs(item:GetDescendants()) do
                        if part:IsA("BasePart") then part.Anchored = false end
                    end

                    local angle = (spread * (math.pi * 2)) / 8
                    local offset = Vector3.new(
                        math.cos(angle) * 3,
                        0.5,
                        math.sin(angle) * 3
                    )

                    item:PivotTo(CFrame.new(hrp.Position + offset))

                    for _, part in ipairs(item:GetDescendants()) do
                        if part:IsA("BasePart") then part.Anchored = true end
                    end

                    count += 1
                    spread += 1
                end
            end
        end
    end

    if count > 0 then
        Notify("TP Pokeballs", "Teleported " .. count .. " pokeball(s) to you!", 4)
    else
        Notify("TP Pokeballs", "No pokeballs found on this route!", 3)
    end
end)

Notify("Requiem", "Roria Conquest loaded!", 3)
