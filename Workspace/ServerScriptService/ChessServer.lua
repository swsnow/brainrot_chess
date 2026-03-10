local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ChessGameWrapper = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("ChessGameWrapper"))

local moveRequest = ReplicatedStorage:WaitForChild("ChessMoveRequest")
local boardStateEvent = ReplicatedStorage:WaitForChild("ChessBoardState")
local arenaMoveEvent = ReplicatedStorage:WaitForChild("ChessArenaMove")

local RunService = game:GetService("RunService")

local gameState = ChessGameWrapper.new()

local START_TIME = 180

local PREMATCH_DURATION = 20

local whiteTimeRemaining = START_TIME
local blackTimeRemaining = START_TIME

local matchPhase = "Prematch"
local prematchEndsAt = workspace:GetServerTimeNow() + PREMATCH_DURATION
local activeTurnStartedAt = nil

local function formatClock(totalSeconds)
    totalSeconds = math.max(0, math.floor(totalSeconds))
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

local function getDisplayedTimes()
    local whiteTime = whiteTimeRemaining
    local blackTime = blackTimeRemaining

    if matchPhase == "Live" and activeTurnStartedAt then
        local now = workspace:GetServerTimeNow()
        local elapsed = now - activeTurnStartedAt

        if gameState:getTurn() == "White" then
            whiteTime = math.max(0, whiteTimeRemaining - elapsed)
        else
            blackTime = math.max(0, blackTimeRemaining - elapsed)
        end
    end

    return whiteTime, blackTime
end

local function getPlayerSide(player)
    return player:GetAttribute("ChessSide")
end

local function sendState(player, extra)
    local now = workspace:GetServerTimeNow()
    local whiteTime, blackTime = getDisplayedTimes()
    local payload = gameState:getPayload(extra)

    payload.whiteTime = whiteTime
    payload.blackTime = blackTime
    payload.serverTime = now
    payload.matchPhase = matchPhase

    if matchPhase == "Prematch" then
        payload.prematchRemaining = math.max(0, prematchEndsAt - now)
        payload.status = ("Match starts in %d"):format(math.ceil(payload.prematchRemaining))
    else
        payload.prematchRemaining = 0
    end

    boardStateEvent:FireClient(player, payload)
end

local function broadcastState(extra)
    for _, player in ipairs(Players:GetPlayers()) do
        sendState(player, extra)
    end
end

local function commitActiveClock()
    local now = workspace:GetServerTimeNow()
    local elapsed = now - activeTurnStartedAt

    if gameState:getTurn() == "White" then
        whiteTimeRemaining = math.max(0, whiteTimeRemaining - elapsed)
    else
        blackTimeRemaining = math.max(0, blackTimeRemaining - elapsed)
    end

    activeTurnStartedAt = now
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        sendState(player)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.defer(function()
        sendState(player)
    end)
end

local function findArenaPieceModel(team, file, rank)
    local piecesFolder = workspace:FindFirstChild("Pieces")
    if not piecesFolder then
        return nil
    end

    for _, pieceModel in ipairs(piecesFolder:GetChildren()) do
        if pieceModel:IsA("Model")
            and pieceModel:GetAttribute("Team") == team
            and pieceModel:GetAttribute("BoardX") == file
            and pieceModel:GetAttribute("BoardY") == rank
            and pieceModel:GetAttribute("Captured") ~= true then
            return pieceModel
        end
    end

    return nil
end

local function updateArenaTimerDisplays()
    local arena = workspace:FindFirstChild("ChessArena")
    if not arena then
        return
    end

    local blueDisplay = arena:FindFirstChild("PlayerBox_Blue_TimerDisplay", true)
    local redDisplay = arena:FindFirstChild("PlayerBox_Red_TimerDisplay", true)

    local whiteTime, blackTime = getDisplayedTimes()

    if blueDisplay then
        local gui = blueDisplay:FindFirstChild("TimerGui")
        local label = gui and gui:FindFirstChild("TimerLabel")
        if label then
            label.Text = formatClock(whiteTime)
            label.TextColor3 =
                (gameState:getTurn() == "White")
                and Color3.fromRGB(0, 170, 255)
                or Color3.fromRGB(0, 90, 140)
        end
    end

    if redDisplay then
        local gui = redDisplay:FindFirstChild("TimerGui")
        local label = gui and gui:FindFirstChild("TimerLabel")
        if label then
            label.Text = formatClock(blackTime)
            label.TextColor3 =
                (gameState:getTurn() == "Black")
                and Color3.fromRGB(255, 60, 60)
                or Color3.fromRGB(140, 50, 50)
        end
    end
end

task.spawn(function()
    while true do
        local now = workspace:GetServerTimeNow()

        if matchPhase == "Prematch" then
            if now >= prematchEndsAt then
                matchPhase = "Live"
                activeTurnStartedAt = now

                local arena = workspace:FindFirstChild("ChessArena")
                if arena then
                    local music = arena:FindFirstChild("PrematchMusic")
                    if music and music:IsA("Sound") then
                        music:Stop()
                    end

                    local sweepValue = arena:FindFirstChild("PreMatchSweepEnabled")
                    if sweepValue then
                        sweepValue.Value = false
                    end

                    local startSound = arena:FindFirstChild("MatchStartSound")
                    if startSound and startSound:IsA("Sound") then
                        startSound:Play()
                    end
                end

                broadcastState({
                    status = "White to move",
                    matchStarted = true,
                    matchPhase = "Live",
                    prematchRemaining = 0,
                })

                print("Match started: White clock running")
            else
                -- keep clients informed during prematch
                broadcastState()
            end
        else
            -- optional periodic sync during live play
            broadcastState()
        end

        updateArenaTimerDisplays()
        task.wait(0.25)
    end
end)

moveRequest.OnServerEvent:Connect(function(player, payload)
    if type(payload) ~= "table" then
        return
    end

    if matchPhase ~= "Live" then
        sendState(player, {
            status = "Match starting...",
            clearSelection = true,
            legalMoves = {},
        })
        return
    end

    local playerSide = getPlayerSide(player)
    if playerSide ~= gameState:getTurn() then
        sendState(player, {
            clearSelection = true,
            legalMoves = {},
            status = "It is not your turn",
        })
        return
    end

    if payload.action == "select" then
        local file = payload.file
        local rank = payload.rank

        if typeof(file) ~= "number" or typeof(rank) ~= "number" then
            return
        end

        local legalMoves = gameState:getLegalMovesMap(file, rank)

        sendState(player, {
            selected = { file = file, rank = rank },
            legalMoves = legalMoves,
        })
        return
    end

    if payload.action == "move" then
        local fromFile = payload.fromFile
        local fromRank = payload.fromRank
        local toFile = payload.toFile
        local toRank = payload.toRank

        if typeof(fromFile) ~= "number"
            or typeof(fromRank) ~= "number"
            or typeof(toFile) ~= "number"
            or typeof(toRank) ~= "number" then
            return
        end

        -- Capture board state BEFORE applying move
        local boardBeforeMove = gameState:getBoardState()
        local movingKey = tostring(fromFile) .. "_" .. tostring(fromRank)
        local targetKey = tostring(toFile) .. "_" .. tostring(toRank)

        local movingPieceData = boardBeforeMove[movingKey]
        local targetPieceData = boardBeforeMove[targetKey]

        local movingModel = movingPieceData and findArenaPieceModel(movingPieceData.team, fromFile, fromRank) or nil
        local targetModel = targetPieceData and findArenaPieceModel(targetPieceData.team, toFile, toRank) or nil

        local movingPieceId = movingModel and movingModel:GetAttribute("PieceId") or nil
        local capturedPieceId = targetModel and targetModel:GetAttribute("PieceId") or nil
        
        local ok, err = gameState:applyMove(fromFile, fromRank, toFile, toRank)

        if not ok then
            sendState(player, {
                selected = { file = fromFile, rank = fromRank },
                legalMoves = gameState:getLegalMovesMap(fromFile, fromRank),
                status = err,
            })
            return
        end
        
        local now = workspace:GetServerTimeNow()
        local elapsed = now - activeTurnStartedAt

        -- turn before applyMove was the player who just moved
        if playerSide == "White" then
            whiteTimeRemaining = math.max(0, whiteTimeRemaining - elapsed)
        else
            blackTimeRemaining = math.max(0, blackTimeRemaining - elapsed)
        end

        activeTurnStartedAt = now

        commitActiveClock()
        activeTurnStartedAt = workspace:GetServerTimeNow()

        if not ok then
            sendState(player, {
                selected = { file = fromFile, rank = fromRank },
                legalMoves = gameState:getLegalMovesMap(fromFile, fromRank),
                status = err,
            })
            return
        end

        if movingModel then
            movingModel:SetAttribute("BoardX", toFile)
            movingModel:SetAttribute("BoardY", toRank)
        end

        if targetModel then
            targetModel:SetAttribute("Captured", true)
        end

        arenaMoveEvent:FireAllClients({
            pieceId = movingPieceId,
            fromFile = fromFile,
            fromRank = fromRank,
            toFile = toFile,
            toRank = toRank,
            moveType = capturedPieceId and "capture" or "move",
            capturedPieceId = capturedPieceId,
        })

        broadcastState({
            clearSelection = true,
        })
    end
end)
