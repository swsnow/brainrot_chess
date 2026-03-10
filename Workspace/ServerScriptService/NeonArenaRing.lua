local parent = workspace:WaitForChild("ChessArena")

local ringFolder = Instance.new("Folder")
ringFolder.Name = "NeonRing"
ringFolder.Parent = parent

local center = Vector3.new(0, 24, 0) -- adjust to your arena center
local radius = 46
local segmentCount = 64
local segmentSize = Vector3.new(3.2, 0.4, 0.8)

local segments = {}

for i = 1, segmentCount do
    local angle = ((i - 1) / segmentCount) * math.pi * 2
    local x = center.X + math.cos(angle) * radius
    local z = center.Z + math.sin(angle) * radius
    local pos = Vector3.new(x, center.Y, z)

    local tangentAngle = angle + math.pi / 2

    local part = Instance.new("Part")
    part.Name = "RingSegment_" .. i
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Size = segmentSize
    part.CFrame = CFrame.new(pos) * CFrame.Angles(0, -tangentAngle, 0)
    part.Parent = ringFolder

    segments[i] = part
end

local function circularDistance(a, b, total)
    local d = math.abs(a - b)
    return math.min(d, total - d)
end

local blueWidth = 14
local step = 1

while true do
    for i, seg in ipairs(segments) do
        local dist = circularDistance(i, step, segmentCount)

        if dist <= blueWidth then
            local t = dist / blueWidth
            local r = math.floor(255 * t)
            local b = math.floor(255 * (1 - t))
            seg.Color = Color3.fromRGB(r, 0, b)
        else
            seg.Color = Color3.fromRGB(255, 0, 0)
        end
    end

    step += 1
    if step > segmentCount then
        step = 1
    end

    task.wait(0.08)
end
