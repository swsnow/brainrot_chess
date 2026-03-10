local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SAFE_SPECTATOR_POS = Vector3.new(0, 20, 85)

local BOARD_HALF = 32
local BOARD_MARGIN = 4
local ARENA_LIMIT = 70
local DEBUG = true

local function isInsideBoardZone(pos)
    return math.abs(pos.X) < (BOARD_HALF + BOARD_MARGIN)
        and math.abs(pos.Z) < (BOARD_HALF + BOARD_MARGIN)
end

local function isOutsideArena(pos)
    return math.abs(pos.X) > ARENA_LIMIT or math.abs(pos.Z) > ARENA_LIMIT
end

RunService.Heartbeat:Connect(function()
    if DEBUG then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("ChessSide") == "Spectator" or player:GetAttribute("CameraMode") == "FreeLook" then
            local character = player.Character
            if character then
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos = root.Position

                    if isInsideBoardZone(pos) or isOutsideArena(pos) then
                        character:PivotTo(CFrame.new(SAFE_SPECTATOR_POS))
                    end
                end
            end
        end
    end
end)
