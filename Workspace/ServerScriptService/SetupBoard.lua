local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TweenService = game:GetService("TweenService")

local arena = workspace:WaitForChild("ChessArena")

--==================================================
-- CONFIG
--==================================================

local BOARD_CENTER = Vector3.new(0, 0, 0)
local TILE_SIZE = 8

-- This should match the actual top surface of the arena board tiles.
local BOARD_TOP_Y = 2.675
local BOARD_CLEARANCE = 0.03

--==================================================
-- TEMPLATE FOLDERS
--==================================================

local templatesFolder = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("Pieces")
local whiteTemplates = templatesFolder:WaitForChild("White")
local blackTemplates = templatesFolder:WaitForChild("Black")

local piecesFolder = Workspace:FindFirstChild("Pieces")
if not piecesFolder then
    piecesFolder = Instance.new("Folder")
    piecesFolder.Name = "Pieces"
    piecesFolder.Parent = Workspace
end

piecesFolder:ClearAllChildren()

--==================================================
-- MANUAL MODEL FIXES
--==================================================

local ROTATION_FIX = {
    White = {
        Pawn   = Vector3.new(-90, 0, 0),
        Rook   = Vector3.new(0, 0, 0),
        Knight = Vector3.new(0, 90, 0),
        Bishop = Vector3.new(-90, 0, 0),
        Queen  = Vector3.new(0, 0, 0),
        King   = Vector3.new(0, 0, 0),
    },
    Black = {
        Pawn   = Vector3.new(-90, 0, 0),
        Rook   = Vector3.new(0, 0, 0),
        Knight = Vector3.new(0, 90, 0),
        Bishop = Vector3.new(-90, 0, 0),
        Queen  = Vector3.new(0, 0, 0),
        King   = Vector3.new(0, 0, 0),
    },
}

local HEIGHT_FIX = {
    White = {
        Pawn   = 1,
        Rook   = 0,
        Knight =  0,
        Bishop = 1.5,
        Queen  = 0.5,
        King   = 0,
    },
    Black = {
        Pawn   = 1,
        Rook   = -1,
        Knight =  0,
        Bishop = 1.5,
        Queen  = 0.5,
        King   = 0,
    },
}

--==================================================
-- HELPERS
--==================================================

local function boardToWorldXZ(file, rank)
    local x = BOARD_CENTER.X + ((4.5 - file) * TILE_SIZE)
    local z = BOARD_CENTER.Z + ((rank - 4.5) * TILE_SIZE)
    return x, z
end

local function getTemplate(color, pieceName)
    if color == "White" then
        return whiteTemplates:FindFirstChild(pieceName)
    else
        return blackTemplates:FindFirstChild(pieceName)
    end
end

local function getRotationFix(color, pieceName)
    if ROTATION_FIX[color] and ROTATION_FIX[color][pieceName] then
        return ROTATION_FIX[color][pieceName]
    end
    return Vector3.new(0, 0, 0)
end

local function getHeightFix(color, pieceName)
    if HEIGHT_FIX[color] and HEIGHT_FIX[color][pieceName] then
        return HEIGHT_FIX[color][pieceName]
    end
    return 0
end

local function ensurePrimaryPart(model)
    if model.PrimaryPart then
        return model.PrimaryPart
    end

    local basePart = model:FindFirstChildWhichIsA("BasePart", true)
    if basePart then
        model.PrimaryPart = basePart
        return basePart
    end

    return nil
end

local function setAnchoredRecursive(instance, anchored)
    for _, obj in ipairs(instance:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Anchored = anchored
        end
    end
end

local function setCanCollideRecursive(instance, canCollide)
    for _, obj in ipairs(instance:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = canCollide
        end
    end
end

local function placePiece(color, pieceType, file, rank, pieceId)
    local template = getTemplate(color, pieceType)
    if not template then
        warn(("Missing template for %s %s"):format(color, pieceType))
        return nil
    end

    local clone = template:Clone()
    clone.Name = pieceId
    clone.Parent = piecesFolder

    local primaryPart = ensurePrimaryPart(clone)
    if not primaryPart then
        warn(("No BasePart found in template for %s"):format(pieceId))
        clone:Destroy()
        return nil
    end

    setAnchoredRecursive(clone, true)
    setCanCollideRecursive(clone, true)

    -- Move away first so bounding box is stable
    clone:PivotTo(CFrame.new(0, 50, 0))

    local rotationFix = getRotationFix(color, pieceType)
    local neutralRotation = CFrame.new(0, 50, 0)
        * CFrame.Angles(
            math.rad(rotationFix.X),
            math.rad(rotationFix.Y),
            math.rad(rotationFix.Z)
        )

    clone:PivotTo(neutralRotation)

    local _, bboxSize = clone:GetBoundingBox()

    local x, z = boardToWorldXZ(file, rank)
    local y = BOARD_TOP_Y + (bboxSize.Y / 2) + BOARD_CLEARANCE + getHeightFix(color, pieceType)

    local facingY = (color == "White") and 0 or 180

    local finalCFrame = CFrame.new(x, y, z)
        * CFrame.Angles(0, math.rad(facingY), 0)
        * CFrame.Angles(
            math.rad(rotationFix.X),
            math.rad(rotationFix.Y),
            math.rad(rotationFix.Z)
        )

    clone:PivotTo(finalCFrame)

    clone:SetAttribute("PieceId", pieceId)
    clone:SetAttribute("PieceType", pieceType)
    clone:SetAttribute("Team", color)
    clone:SetAttribute("BoardX", file)
    clone:SetAttribute("BoardY", rank)
    clone:SetAttribute("Captured", false)

    return clone
end

--==================================================
-- STARTING POSITION
--==================================================

local function spawnStandardPosition()
    -- White back rank
    placePiece("White", "Rook",   1, 1, "White_Rook_1")
    placePiece("White", "Knight", 2, 1, "White_Knight_1")
    placePiece("White", "Bishop", 3, 1, "White_Bishop_1")
    placePiece("White", "Queen",  4, 1, "White_Queen")
    placePiece("White", "King",   5, 1, "White_King")
    placePiece("White", "Bishop", 6, 1, "White_Bishop_2")
    placePiece("White", "Knight", 7, 1, "White_Knight_2")
    placePiece("White", "Rook",   8, 1, "White_Rook_2")

    for file = 1, 8 do
        placePiece("White", "Pawn", file, 2, "White_Pawn_" .. file)
    end

    -- Black back rank
    placePiece("Black", "Rook",   1, 8, "Black_Rook_1")
    placePiece("Black", "Knight", 2, 8, "Black_Knight_1")
    placePiece("Black", "Bishop", 3, 8, "Black_Bishop_1")
    placePiece("Black", "Queen",  4, 8, "Black_Queen")
    placePiece("Black", "King",   5, 8, "Black_King")
    placePiece("Black", "Bishop", 6, 8, "Black_Bishop_2")
    placePiece("Black", "Knight", 7, 8, "Black_Knight_2")
    placePiece("Black", "Rook",   8, 8, "Black_Rook_2")

    for file = 1, 8 do
        placePiece("Black", "Pawn", file, 7, "Black_Pawn_" .. file)
    end
end

spawnStandardPosition()
print("3D chess pieces spawned.")
