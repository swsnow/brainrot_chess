local ServerScriptService = game:GetService("ServerScriptService")
local ChessEngine = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("ChessEngine"))

local ChessGameWrapper = {}
ChessGameWrapper.__index = ChessGameWrapper

local function keyFor(file, rank)
	return tostring(file) .. "_" .. tostring(rank)
end

local function pieceCharToType(pieceChar)
	local upper = string.upper(pieceChar)

	if upper == "P" then
		return "Pawn"
	elseif upper == "R" then
		return "Rook"
	elseif upper == "N" then
		return "Knight"
	elseif upper == "B" then
		return "Bishop"
	elseif upper == "Q" then
		return "Queen"
	elseif upper == "K" then
		return "King"
	end

	return nil
end

function ChessGameWrapper.new()
	local self = setmetatable({}, ChessGameWrapper)

	self.position = ChessEngine.newGame()
	self.turn = "White"

	return self
end

function ChessGameWrapper:getTurn()
	return self.turn
end

--==================================================
-- DISPLAY <-> ENGINE COORDINATE CONVERSION
--==================================================

function ChessGameWrapper:_displayToEngineFileRank(file, rank)
	if self.turn == "White" then
		return file, rank
	else
		return 9 - file, 9 - rank
	end
end

function ChessGameWrapper:_engineToDisplayFileRank(file, rank)
	if self.turn == "White" then
		return file, rank
	else
		return 9 - file, 9 - rank
	end
end

function ChessGameWrapper:_displayToEngineIndex(file, rank)
	local ef, er = self:_displayToEngineFileRank(file, rank)
	return ChessEngine.fileRankToIndex(ef, er)
end

function ChessGameWrapper:_engineIndexToDisplayFileRank(index)
	local ef, er = ChessEngine.indexToFileRank(index)
	return self:_engineToDisplayFileRank(ef, er)
end

--==================================================
-- PIECE OWNERSHIP / BOARD READING
--==================================================

function ChessGameWrapper:_rawPieceAtDisplaySquare(file, rank)
	local engineIndex = self:_displayToEngineIndex(file, rank)
	return self.position.board:sub(engineIndex + 1, engineIndex + 1)
end

function ChessGameWrapper:_pieceCharToTeam(pieceChar)
	if self.turn == "White" then
		return pieceChar:match("%u") and "White" or "Black"
	else
		return pieceChar:match("%u") and "Black" or "White"
	end
end

function ChessGameWrapper:getBoardState()
	local board = {}

	for file = 1, 8 do
		for rank = 1, 8 do
			local pieceChar = self:_rawPieceAtDisplaySquare(file, rank)

			if pieceChar ~= "." and pieceChar ~= " " and pieceChar ~= "\n" then
				local pieceType = pieceCharToType(pieceChar)
				if pieceType then
					board[keyFor(file, rank)] = {
						piece = pieceType,
						team = self:_pieceCharToTeam(pieceChar),
					}
				end
			end
		end
	end

	return board
end

function ChessGameWrapper:isCurrentTurnPiece(file, rank)
	local pieceChar = self:_rawPieceAtDisplaySquare(file, rank)

	if pieceChar == "." or pieceChar == " " or pieceChar == "\n" then
		return false
	end

	-- In the engine, the side to move is always uppercase
	return pieceChar:match("%u") ~= nil
end

--==================================================
-- MOVE GENERATION
--==================================================

function ChessGameWrapper:getLegalMovesMap(fromFile, fromRank)
	local legalMoves = {}

	if not self:isCurrentTurnPiece(fromFile, fromRank) then
		return legalMoves
	end

	local fromIndex = self:_displayToEngineIndex(fromFile, fromRank)
	local moves = ChessEngine.getLegalMoves(self.position)

	for _, move in ipairs(moves) do
		local moveFrom = move[1]
		local moveTo = move[2]

		if moveFrom == fromIndex then
			local toFile, toRank = self:_engineIndexToDisplayFileRank(moveTo)
			local moveKey = keyFor(toFile, toRank)

			local targetPiece = self.position.board:sub(moveTo + 1, moveTo + 1)

			if targetPiece ~= "." and targetPiece ~= " " and targetPiece ~= "\n" and targetPiece:match("%l") then
				legalMoves[moveKey] = "capture"
			else
				legalMoves[moveKey] = "move"
			end
		end
	end

	return legalMoves
end

function ChessGameWrapper:isLegalMove(fromFile, fromRank, toFile, toRank)
	local fromIndex = self:_displayToEngineIndex(fromFile, fromRank)
	local toIndex = self:_displayToEngineIndex(toFile, toRank)

	local moves = ChessEngine.getLegalMoves(self.position)

	for _, move in ipairs(moves) do
		if move[1] == fromIndex and move[2] == toIndex then
			return true
		end
	end

	return false
end

function ChessGameWrapper:applyMove(fromFile, fromRank, toFile, toRank)
	if not self:isCurrentTurnPiece(fromFile, fromRank) then
		return false, "That is not your piece"
	end

	if not self:isLegalMove(fromFile, fromRank, toFile, toRank) then
		return false, "Illegal move"
	end

	local fromIndex = self:_displayToEngineIndex(fromFile, fromRank)
	local toIndex = self:_displayToEngineIndex(toFile, toRank)

	self.position = ChessEngine.applyMove(self.position, fromIndex, toIndex)

	if self.turn == "White" then
		self.turn = "Black"
	else
		self.turn = "White"
	end

	return true
end

function ChessGameWrapper:getPayload(extra)
	local payload = {
		board = self:getBoardState(),
		turn = self.turn,
		status = self.turn .. " to move",
	}

	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end

	return payload
end

return ChessGameWrapper
