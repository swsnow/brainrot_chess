
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent
local controlPanel = gui:WaitForChild("ControlPanelFrame")

------------------------------------------------------------
-- TIMER BAR CREATION
------------------------------------------------------------

local function createTimerBar(parent)

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBarFrame"
    topBar.Size = UDim2.new(1, -20, 0, 48)
    topBar.Position = UDim2.new(0, 10, 0, 10)
    topBar.BackgroundColor3 = Color3.fromRGB(12,12,16)
    topBar.BorderSizePixel = 0
    topBar.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = topBar


    -- WHITE TIMER

    local whiteTimer = Instance.new("TextLabel")
    whiteTimer.Name = "WhiteTimerLabel"
    whiteTimer.Size = UDim2.new(0.48,0,1,0)
    whiteTimer.Position = UDim2.new(0,0,0,0)
    whiteTimer.BackgroundColor3 = Color3.fromRGB(20,20,24)
    whiteTimer.BorderSizePixel = 0
    whiteTimer.Font = Enum.Font.Code
    whiteTimer.TextScaled = true
    whiteTimer.Text = "03:00"
    whiteTimer.TextColor3 = Color3.fromRGB(0,170,255)
    whiteTimer.Parent = topBar

    local whiteCorner = Instance.new("UICorner")
    whiteCorner.CornerRadius = UDim.new(0,6)
    whiteCorner.Parent = whiteTimer


    -- BLACK TIMER

    local blackTimer = Instance.new("TextLabel")
    blackTimer.Name = "BlackTimerLabel"
    blackTimer.Size = UDim2.new(0.48,0,1,0)
    blackTimer.Position = UDim2.new(0.52,0,0,0)
    blackTimer.BackgroundColor3 = Color3.fromRGB(20,20,24)
    blackTimer.BorderSizePixel = 0
    blackTimer.Font = Enum.Font.Code
    blackTimer.TextScaled = true
    blackTimer.Text = "03:00"
    blackTimer.TextColor3 = Color3.fromRGB(255,60,60)
    blackTimer.Parent = topBar

    local blackCorner = Instance.new("UICorner")
    blackCorner.CornerRadius = UDim.new(0,6)
    blackCorner.Parent = blackTimer

    whiteTimer.TextStrokeTransparency = 0.4
    blackTimer.TextStrokeTransparency = 0.4

    return whiteTimer, blackTimer
end


local whiteTimerLabel, blackTimerLabel = createTimerBar(controlPanel)


local function refresh()
	local inChessMatch = player:GetAttribute("InChessMatch")
	gui.Enabled = inChessMatch == true
	controlPanel.Visible = inChessMatch == true
end

player:GetAttributeChangedSignal("InChessMatch"):Connect(refresh)
refresh()
