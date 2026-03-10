local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local moveRequest = ReplicatedStorage:WaitForChild("ChessMoveRequest")
local boardStateEvent = ReplicatedStorage:WaitForChild("ChessBoardState")

local controlPanel = script.Parent
local boardFrame = controlPanel:WaitForChild("BoardFrame")
local statusLabel = controlPanel:WaitForChild("StatusLabel")
local topBarFrame = controlPanel:WaitForChild("TopBarFrame")
local whiteTimerLabel = topBarFrame:WaitForChild("WhiteTimerLabel")
local blackTimerLabel = topBarFrame:WaitForChild("BlackTimerLabel")

--==================================================
-- CONFIG
--==================================================

local BOARD_PIXELS = 400
local TILE_COUNT = 8
local TILE_SIZE = BOARD_PIXELS / TILE_COUNT

local LIGHT_SQUARE = Color3.fromRGB(240, 217, 181)
local DARK_SQUARE = Color3.fromRGB(181, 136, 99)

local SELECTED_COLOR = Color3.fromRGB(255, 230, 80)
local LEGAL_MOVE_COLOR = Color3.fromRGB(100, 200, 120)
local LEGAL_CAPTURE_COLOR = Color3.fromRGB(220, 100, 100)

local WHITE_PIECE_COLOR = Color3.fromRGB(255, 255, 255)
local BLACK_PIECE_COLOR = Color3.fromRGB(20, 20, 20)

-- This should be set by the server eventually.
-- For testing, change to "Black" to see flipped board.
local playerSide = player:GetAttribute("ChessSide") or "White"



--==================================================
-- STATE
--==================================================

local squareButtons = {}
local selectedSquare = nil

-- Board state format expected from server:
-- currentBoardState = {
--     board = {
--         ["1_1"] = {piece = "Rook", team = "White"},
--         ["2_1"] = {piece = "Knight", team = "White"},
--         ...
--     },
--     legalMoves = {
--         ["2_2"] = true,
--         ["2_3"] = "move",
--         ["3_3"] = "capture",
--     },
--     turn = "White",
--     status = "White to move"
-- }
local currentBoardState = {
    board = {},
    legalMoves = {},
    turn = "White",
    status = "Waiting for game state...",
    whiteTime = 180,
    blackTime = 180,
    matchPhase = "Prematch",
    prematchRemaining = 20,
    serverTime = 0,
}

local pieceSymbols = {
	White = {
		Pawn = "P",
		Rook = "R",
		Knight = "N",
		Bishop = "B",
		Queen = "Q",
		King = "K",
	},
	Black = {
		Pawn = "p",
		Rook = "r",
		Knight = "n",
		Bishop = "b",
		Queen = "q",
		King = "k",
	}
}

local pieceImages = {
	White = {
		Pawn = "rbxassetid://135676720727266",
		Rook = "rbxassetid://129013959068992",
		Knight = "rbxassetid://92259054286443",
		Bishop = "rbxassetid://121140595364171",
		Queen = "rbxassetid://77332629592947",
		King = "rbxassetid://134189033281643",
	},
	Black = {
		Pawn = "rbxassetid://107082549612333",
		Rook = "rbxassetid://101895185586304",
		Knight = "rbxassetid://115667683935384",
		Bishop = "rbxassetid://84481867145064",
		Queen = "rbxassetid://128120007431869",
		King = "rbxassetid://78491763090579",
	}
}

--==================================================
-- HELPERS
--==================================================

local function keyFor(file, rank)
	return tostring(file) .. "_" .. tostring(rank)
end

local function isLightSquare(file, rank)
	return ((file + rank) % 2 == 0)
end

local function getBaseSquareColor(file, rank)
	return isLightSquare(file, rank) and LIGHT_SQUARE or DARK_SQUARE
end

local function convertSquareForDisplay(file, rank)
	-- White sees rank 8 at top, rank 1 at bottom
	-- Black sees rank 1 at top, rank 8 at bottom (flipped board)
	if playerSide == "White" then
		return file, rank
	else
		return 9 - file, 9 - rank
	end
end

local function displayPositionForSquare(file, rank)
	local displayFile, displayRank = convertSquareForDisplay(file, rank)

	local x = (displayFile - 1) * TILE_SIZE
	local y = (8 - displayRank) * TILE_SIZE

	return x, y
end

local function getSquareButton(file, rank)
	return squareButtons[keyFor(file, rank)]
end

local function clearSelection()
	selectedSquare = nil
	currentBoardState.legalMoves = {}
end

local function formatClock(seconds)
    seconds = math.max(0, math.floor(seconds))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

local function updateLabels()
    statusLabel.Text = tostring(currentBoardState.status or "")

    local whiteTime = currentBoardState.whiteTime or 180
    local blackTime = currentBoardState.blackTime or 180
    local activeTurn = currentBoardState.turn

    whiteTimerLabel.Text = formatClock(whiteTime)
    blackTimerLabel.Text = formatClock(blackTime)

    whiteTimerLabel.TextColor3 =
        (activeTurn == "White")
        and Color3.fromRGB(0, 170, 255)
        or Color3.fromRGB(0, 90, 140)

    blackTimerLabel.TextColor3 =
        (activeTurn == "Black")
        and Color3.fromRGB(255, 60, 60)
        or Color3.fromRGB(140, 50, 50)
end

local function squareHasPiece(file, rank)
	local pieceData = currentBoardState.board[keyFor(file, rank)]
	return pieceData ~= nil
end

local function getPieceAt(file, rank)
	return currentBoardState.board[keyFor(file, rank)]
end

local function resetSquareVisual(file, rank)

	local button = getSquareButton(file, rank)
	if not button then
		return
	end

	button.BackgroundColor3 = getBaseSquareColor(file, rank)

	local pieceImage = button:FindFirstChild("PieceImage")

	local pieceData = getPieceAt(file, rank)

	if pieceData and pieceImage then

		pieceImage.Image = pieceImages[pieceData.team][pieceData.piece]
		pieceImage.Visible = true

	else

		if pieceImage then
			pieceImage.Image = ""
			pieceImage.Visible = false
		end

	end

end

local function renderBoard()
	for rank = 1, 8 do
		for file = 1, 8 do
			resetSquareVisual(file, rank)
		end
	end

	if selectedSquare then
		local selectedButton = getSquareButton(selectedSquare.file, selectedSquare.rank)
		if selectedButton then
			selectedButton.BackgroundColor3 = SELECTED_COLOR
		end
	end

	for moveKey, moveType in pairs(currentBoardState.legalMoves or {}) do
		local fileStr, rankStr = string.match(moveKey, "^(%d+)_(%d+)$")
		local file = tonumber(fileStr)
		local rank = tonumber(rankStr)

		if file and rank then
			local button = getSquareButton(file, rank)
			if button then
				if moveType == "capture" then
					button.BackgroundColor3 = LEGAL_CAPTURE_COLOR
				else
					button.BackgroundColor3 = LEGAL_MOVE_COLOR
				end
			end
		end
	end

	updateLabels()
end

player:GetAttributeChangedSignal("ChessSide"):Connect(function()
    playerSide = player:GetAttribute("ChessSide") or "White"
    renderBoard()
end)

local function requestSelection(file, rank)
	-- Ask server for legal moves from this square.
	-- We use the same move event with a selection payload for simplicity.
	moveRequest:FireServer({
		action = "select",
		file = file,
		rank = rank,
	})
end

local function requestMove(fromFile, fromRank, toFile, toRank)
	moveRequest:FireServer({
		action = "move",
		fromFile = fromFile,
		fromRank = fromRank,
		toFile = toFile,
		toRank = toRank,
	})
end

--==================================================
-- UI BUILD
--==================================================

boardFrame.Size = UDim2.fromOffset(BOARD_PIXELS, BOARD_PIXELS)
boardFrame.BackgroundTransparency = 1
boardFrame.BorderSizePixel = 0

for _, child in ipairs(boardFrame:GetChildren()) do
	if child:IsA("GuiObject") then
		child:Destroy()
	end
end

for rank = 1, 8 do
	for file = 1, 8 do
		local button = Instance.new("ImageButton")
		button.Name = keyFor(file, rank)
		button.Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE)

		local x, y = displayPositionForSquare(file, rank)
		button.Position = UDim2.fromOffset(x, y)

		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.BackgroundColor3 = getBaseSquareColor(file, rank)
        button.Image = ""
        button.BackgroundTransparency = 0.5

		button:SetAttribute("File", file)
		button:SetAttribute("Rank", rank)
		button.Parent = boardFrame
		squareButtons[keyFor(file, rank)] = button

		local pieceImage = Instance.new("ImageLabel")
		pieceImage.Name = "PieceImage"
		pieceImage.BackgroundTransparency = 1
		pieceImage.Size = UDim2.new(1, -6, 1, -6)
		pieceImage.Position = UDim2.new(0, 3, 0, 3)
		pieceImage.Image = ""
		pieceImage.ScaleType = Enum.ScaleType.Fit
        pieceImage.Parent = button
        pieceImage.Transparency = 0.3

		button.MouseButton1Click:Connect(function()
			local clickedFile = button:GetAttribute("File")
			local clickedRank = button:GetAttribute("Rank")
			local clickedKey = keyFor(clickedFile, clickedRank)

			-- If clicking a highlighted legal move, send move
			if selectedSquare and currentBoardState.legalMoves and currentBoardState.legalMoves[clickedKey] then
				requestMove(selectedSquare.file, selectedSquare.rank, clickedFile, clickedRank)
				clearSelection()
				renderBoard()
				return
			end

			-- If clicking same selected square, deselect
			if selectedSquare and selectedSquare.file == clickedFile and selectedSquare.rank == clickedRank then
				clearSelection()
				renderBoard()
				return
			end

			-- Otherwise try selecting a piece on this square
			if squareHasPiece(clickedFile, clickedRank) then
				selectedSquare = {
					file = clickedFile,
					rank = clickedRank
				}
				currentBoardState.legalMoves = {}
				renderBoard()
				requestSelection(clickedFile, clickedRank)
			else
				clearSelection()
				renderBoard()
			end
		end)
	end
end

--==================================================
-- BOARD LABELS
--==================================================

for file = 1, 8 do
	local displayFile, _ = convertSquareForDisplay(file, 1)
	local fileLabel = Instance.new("TextLabel")
	fileLabel.Name = "FileLabel_" .. tostring(file)
	fileLabel.Size = UDim2.fromOffset(TILE_SIZE, 18)
	fileLabel.Position = UDim2.fromOffset((displayFile - 1) * TILE_SIZE, BOARD_PIXELS + 2)
	fileLabel.BackgroundTransparency = 1
	fileLabel.TextScaled = true
	fileLabel.Font = Enum.Font.Gotham
	fileLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	fileLabel.Text = string.char(string.byte("a") + file - 1)
	fileLabel.Parent = boardFrame
end

for rank = 1, 8 do
	local _, displayRank = convertSquareForDisplay(1, rank)
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel_" .. tostring(rank)
	rankLabel.Size = UDim2.fromOffset(18, TILE_SIZE)
	rankLabel.Position = UDim2.fromOffset(-20, (8 - displayRank) * TILE_SIZE)
	rankLabel.BackgroundTransparency = 1
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.Gotham
	rankLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	rankLabel.Text = tostring(rank)
	rankLabel.Parent = boardFrame
end

--==================================================
-- SERVER UPDATES
--==================================================

boardStateEvent.OnClientEvent:Connect(function(payload)
    
    print("whiteTime:", payload.whiteTime, "blackTime:", payload.blackTime, "serverTime:", payload.serverTime)
    
    if payload.board then
        currentBoardState.board = payload.board
    end

    if payload.legalMoves ~= nil then
        currentBoardState.legalMoves = payload.legalMoves
    end

    if payload.turn then
        currentBoardState.turn = payload.turn
    end

    if payload.status then
        currentBoardState.status = payload.status
    end

    if payload.selected then
        selectedSquare = payload.selected
    end

    if payload.clearSelection then
        selectedSquare = nil
        currentBoardState.legalMoves = {}
    end

    if payload.whiteTime ~= nil then
        currentBoardState.whiteTime = payload.whiteTime
    end

    if payload.blackTime ~= nil then
        currentBoardState.blackTime = payload.blackTime
    end

    if payload.serverTime ~= nil then
        currentBoardState.serverTime = payload.serverTime
    end
    
    if payload.matchPhase then
        currentBoardState.matchPhase = payload.matchPhase
    end

    if payload.prematchRemaining ~= nil then
        currentBoardState.prematchRemaining = payload.prematchRemaining
    end

    renderBoard()
end)

--==================================================
-- INITIAL VISUALS
--==================================================

statusLabel.Text = "Waiting for board..."
whiteTimerLabel.Text = "03:00"
blackTimerLabel.Text = "03:00"
renderBoard()

local RunService = game:GetService("RunService")

RunService.RenderStepped:Connect(function()
    local whiteTime = currentBoardState.whiteTime or 180
    local blackTime = currentBoardState.blackTime or 180
    local turn = currentBoardState.turn or "White"
    local serverTime = currentBoardState.serverTime or workspace:GetServerTimeNow()
    local phase = currentBoardState.matchPhase or "Prematch"

    if phase == "Live" then
        local elapsed = workspace:GetServerTimeNow() - serverTime

        if turn == "White" then
            whiteTime = math.max(0, whiteTime - elapsed)
        else
            blackTime = math.max(0, blackTime - elapsed)
        end
    end

    whiteTimerLabel.Text = formatClock(whiteTime)
    blackTimerLabel.Text = formatClock(blackTime)

    if turn == "White" then
        whiteTimerLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
        blackTimerLabel.TextColor3 = Color3.fromRGB(140, 50, 50)
    else
        whiteTimerLabel.TextColor3 = Color3.fromRGB(0, 90, 140)
        blackTimerLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
    end
end)
