local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local arenaMoveEvent = ReplicatedStorage:WaitForChild("ChessArenaMove")

local piecesFolder = workspace:WaitForChild("Pieces")

local BOARD_CENTER = Vector3.new(0, 0, 0)
local TILE_SIZE = 8
local BOARD_TOP_Y = 2.675

local MOVE_TIME = 0.25
local CAPTURE_TIME = 0.18
local HOP_HEIGHT = 2

local function boardToWorld(file, rank, currentY)
    local x = BOARD_CENTER.X + ((4.5 - file) * TILE_SIZE)
    local z = BOARD_CENTER.Z + ((rank - 4.5) * TILE_SIZE)
    local y = currentY or (BOARD_TOP_Y + 3)
    return Vector3.new(x, y, z)
end

local function findPieceModelById(pieceId)
    for _, model in ipairs(piecesFolder:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("PieceId") == pieceId then
            return model
        end
    end
    return nil
end

local function getModelRootPosition(model)
    if model.PrimaryPart then
        return model.PrimaryPart.Position
    end

    local cf = model:GetPivot()
    return cf.Position
end

local function pivotModelToPosition(model, targetPos)
    local current = model:GetPivot()
    local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = current:GetComponents()

    local newCFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z) * CFrame.fromMatrix(
        Vector3.new(),
        Vector3.new(r00, r10, r20),
        Vector3.new(r01, r11, r21),
        Vector3.new(r02, r12, r22)
    )

    model:PivotTo(newCFrame)
end

local function playPieceAnimation(model, animationName)
    -- Placeholder hook.
    -- Later you can:
    -- 1. find AnimationController / Animator
    -- 2. load animation by type/name
    -- 3. play it here

    -- Example future use:
    -- local controller = model:FindFirstChild("AnimationController", true)
    -- ...
end

local function animateMove(model, toFile, toRank)
    local startPos = getModelRootPosition(model)
    local targetPos = boardToWorld(toFile, toRank, startPos.Y)

    local proxy = Instance.new("CFrameValue")
    proxy.Value = CFrame.new(startPos)

    local connection
    connection = proxy:GetPropertyChangedSignal("Value"):Connect(function()
        pivotModelToPosition(model, proxy.Value.Position)
    end)

    local tween = TweenService:Create(
        proxy,
        TweenInfo.new(MOVE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Value = CFrame.new(targetPos)}
    )

    tween:Play()
    tween.Completed:Wait()

    if connection then
        connection:Disconnect()
    end
    proxy:Destroy()

    pivotModelToPosition(model, targetPos)
end

local function animateHopMove(model, toFile, toRank)
    local startPos = getModelRootPosition(model)
    local endPos = boardToWorld(toFile, toRank, startPos.Y)

    local duration = MOVE_TIME
    local startTime = tick()

    while true do
        local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
        local flat = startPos:Lerp(endPos, alpha)
        local yOffset = math.sin(alpha * math.pi) * HOP_HEIGHT

        pivotModelToPosition(model, flat + Vector3.new(0, yOffset, 0))

        if alpha >= 1 then
            break
        end

        task.wait()
    end

    pivotModelToPosition(model, endPos)
end

local function animateCapture(victimModel)
    if not victimModel then
        return
    end

    playPieceAnimation(victimModel, "CaptureVictim")

    local startPos = getModelRootPosition(victimModel)
    local proxy = Instance.new("CFrameValue")
    proxy.Value = CFrame.new(startPos)

    local connection
    connection = proxy:GetPropertyChangedSignal("Value"):Connect(function()
        victimModel:PivotTo(proxy.Value)
    end)

    local tween = TweenService:Create(
        proxy,
        TweenInfo.new(CAPTURE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Value = CFrame.new(startPos + Vector3.new(0, -3, 0))
        }
    )

    for _, obj in ipairs(victimModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency = math.clamp(obj.Transparency + 0.35, 0, 1)
        end
    end

    tween:Play()
    tween.Completed:Wait()

    if connection then
        connection:Disconnect()
    end
    proxy:Destroy()

    victimModel:Destroy()
end

arenaMoveEvent.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then
        return
    end

    local movingModel = data.pieceId and findPieceModelById(data.pieceId) or nil
    if not movingModel then
        return
    end

    local pieceType = movingModel:GetAttribute("PieceType")

    if data.moveType == "capture" and data.capturedPieceId then
        local victimModel = findPieceModelById(data.capturedPieceId)

        playPieceAnimation(movingModel, "Attack")

        if pieceType == "Knight" then
            animateHopMove(movingModel, data.toFile, data.toRank)
        else
            animateMove(movingModel, data.toFile, data.toRank)
        end

        animateCapture(victimModel)
    else
        playPieceAnimation(movingModel, "Move")

        if pieceType == "Knight" then
            animateHopMove(movingModel, data.toFile, data.toRank)
        else
            animateMove(movingModel, data.toFile, data.toRank)
        end
    end

    movingModel:SetAttribute("BoardX", data.toFile)
    movingModel:SetAttribute("BoardY", data.toRank)
end)
