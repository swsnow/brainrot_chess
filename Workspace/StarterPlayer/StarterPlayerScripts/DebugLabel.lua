local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "DebugHelpGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(310, 90)
label.Position = UDim2.new(0, 20, 0, 20)
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.Code
label.TextSize = 16
label.Text = "Debug Keys:\n1 = Blue booth\n2 = Red booth\n3 = Spectator\n4 = Free-look\n5 = Noclip fly\n6 = Normal Walk"
label.Parent = gui
