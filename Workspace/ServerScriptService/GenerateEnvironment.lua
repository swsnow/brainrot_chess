local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local MODEL_NAME = "ChessArena"

local old = Workspace:FindFirstChild(MODEL_NAME)
if old then
	old:Destroy()
end

local model = Instance.new("Model")
model.Name = MODEL_NAME
model.Parent = Workspace

--==================================================
-- CONFIG
--==================================================

local CENTER = Vector3.new(0, 0, 0)

local FLOOR_RADIUS = 60
local FLOOR_HEIGHT = 2

local WALL_RADIUS = 58
local WALL_SEGMENTS = 28

local COLUMN_RADIUS = 2
local COLUMN_HEIGHT = 18
local COLUMN_TOP_Y = FLOOR_HEIGHT + COLUMN_HEIGHT

local TOP_RING_HEIGHT = 3
local TOP_RING_WIDTH = 5
local TOP_RING_Y = COLUMN_TOP_Y + 2

local ARCH_HEIGHT = 8
local ARCH_THICKNESS = 2
local ARCH_WIDTH_SHRINK = 3

local BOARD_TILE_SIZE = 8
local BOARD_THICKNESS = 1
local BOARD_Y = FLOOR_HEIGHT + BOARD_THICKNESS / 2 + 0.05
local BOARD_BORDER = 4

local BOOTH_WIDTH = 24
local BOOTH_DEPTH = 16
local BOOTH_HEIGHT = 12
local BOOTH_FLOOR_THICKNESS = 1
local BOOTH_WALL_THICKNESS = 1
local BOOTH_GLASS_THICKNESS = 0.6

local BOOTH_PITCH_DEGREES = -12
local BOOTH_BASE_Y = FLOOR_HEIGHT + COLUMN_HEIGHT - 2
local BOOTH_OFFSET = WALL_RADIUS - 4

local BOOTH_SUPPORT_LENGTH = 12
local BOOTH_SUPPORT_THICKNESS = 2

local BOX_GAP_ANGLE = math.rad(30)
local NORTH_BOX_ANGLE = math.rad(-90)
local SOUTH_BOX_ANGLE = math.rad(90)

local SPOTLIGHT_BRIGHTNESS = 6
local SPOTLIGHT_RANGE = 120
local SPOTLIGHT_ANGLE = 45

local STAND_WIDTH = 22
local STAND_DEPTH = 24
local STAND_STEP_HEIGHT = 2
local STAND_STEP_DEPTH = 4
local STAND_ROWS = 6
local STAND_BASE_Y = FLOOR_HEIGHT
local STAND_OFFSET = FLOOR_RADIUS - 8

local STAND_ROWS = 6
local STAND_STEP_HEIGHT = 2
local STAND_STEP_DEPTH = 4

local STAND_INNER_RADIUS = 40
local STAND_OUTER_RADIUS = STAND_INNER_RADIUS + (STAND_ROWS * STAND_STEP_DEPTH)

local STAND_SEGMENTS = 20
local STAND_ARC_DEGREES = 70

local STAND_WALL_HEIGHT = 5

local BOARD_SIZE = 64
local BLOCKER_HEIGHT = 12
local BLOCKER_THICKNESS = 2
local HALF = BOARD_SIZE / 2

local ARENA_BOUNDARY = 72
local OUTER_HEIGHT = 20
local OUTER_THICKNESS = 4

local POOL_INNER_RADIUS = 36
local POOL_OUTER_RADIUS = 48
local POOL_HEIGHT = 0.6
local POOL_Y = FLOOR_HEIGHT + 0.15

local POOL_SEGMENTS = 14
local POOL_ARC_DEGREES = 70
local POOL_REFLECTANCE = 0.28

local LOWER_WALL_RADIUS = 60
local LOWER_WALL_HEIGHT = 10
local LOWER_WALL_THICKNESS = 2
local LOWER_WALL_SEGMENTS = 36

local preMatchSweepEnabled = true
local spotlightRigs = {}

--==================================================
-- HELPERS
--==================================================


local function makePart(name, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

local function makeCylinder(name, position, radius, height, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function makeGlassPart(name, size, cframe, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.CFrame = cframe
	p.Material = Enum.Material.Glass
	p.Transparency = transparency or 0.45
	p.Color = Color3.fromRGB(200, 235, 255)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function makeNeonPart(name, size, cframe, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cframe
	p.Material = Enum.Material.Neon
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function createBeamBetween(name, p1, p2, thicknessX, thicknessY, color, material)
	local mid = (p1 + p2) / 2
	local dist = (p2 - p1).Magnitude

	makePart(
		name,
		Vector3.new(thicknessX, thicknessY, dist),
		CFrame.lookAt(mid, p2),
		color,
		material
	)
end

local function angleDifference(a, b)
	local diff = math.atan2(math.sin(a - b), math.cos(a - b))
	return math.abs(diff)
end

local function createSpawnMarker(name, cframe)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(4, 1, 4)
	p.CFrame = cframe
	p.Parent = model
	return p
end

local function createCameraMarker(name, cframe)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = cframe
	p.Parent = model
	return p
end

local function createNeonBeamBetween(name, p1, p2, thickness, color)
	local mid = (p1 + p2) / 2
	local length = (p2 - p1).Magnitude

	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = Vector3.new(thickness, thickness, length)
	part.CFrame = CFrame.lookAt(mid, p2)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model

	return part
end

local function addNeonFrame(name, floorCFrame, roofCFrame, width, depth, frameColor)
	local halfW = width / 2
	local halfD = depth / 2
	local t = 0.35

	-- Floor corners
	local floorFrontLeft  = (floorCFrame * CFrame.new(-halfW, 0, -halfD)).Position
	local floorFrontRight = (floorCFrame * CFrame.new( halfW, 0, -halfD)).Position
	local floorBackLeft   = (floorCFrame * CFrame.new(-halfW, 0,  halfD)).Position
	local floorBackRight  = (floorCFrame * CFrame.new( halfW, 0,  halfD)).Position

	-- Roof corners
	local roofFrontLeft   = (roofCFrame * CFrame.new(-halfW, 0, -halfD)).Position
	local roofFrontRight  = (roofCFrame * CFrame.new( halfW, 0, -halfD)).Position
	local roofBackLeft    = (roofCFrame * CFrame.new(-halfW, 0,  halfD)).Position
	local roofBackRight   = (roofCFrame * CFrame.new( halfW, 0,  halfD)).Position

	-- Bottom perimeter
	createNeonBeamBetween(name .. "_Neon_BottomFront", floorFrontLeft, floorFrontRight, t, frameColor)
	createNeonBeamBetween(name .. "_Neon_BottomBack",  floorBackLeft,  floorBackRight,  t, frameColor)
	createNeonBeamBetween(name .. "_Neon_BottomLeft",  floorFrontLeft, floorBackLeft,   t, frameColor)
	createNeonBeamBetween(name .. "_Neon_BottomRight", floorFrontRight,floorBackRight,  t, frameColor)

	-- Top perimeter
	createNeonBeamBetween(name .. "_Neon_TopFront", roofFrontLeft, roofFrontRight, t, frameColor)
	createNeonBeamBetween(name .. "_Neon_TopBack",  roofBackLeft,  roofBackRight,  t, frameColor)
	createNeonBeamBetween(name .. "_Neon_TopLeft",  roofFrontLeft, roofBackLeft,   t, frameColor)
	createNeonBeamBetween(name .. "_Neon_TopRight", roofFrontRight,roofBackRight,  t, frameColor)

	-- Vertical/slanted corners
	createNeonBeamBetween(name .. "_Neon_FrontLeft",  floorFrontLeft,  roofFrontLeft,  t, frameColor)
	createNeonBeamBetween(name .. "_Neon_FrontRight", floorFrontRight, roofFrontRight, t, frameColor)
	createNeonBeamBetween(name .. "_Neon_BackLeft",   floorBackLeft,   roofBackLeft,   t, frameColor)
	createNeonBeamBetween(name .. "_Neon_BackRight",  floorBackRight,  roofBackRight,  t, frameColor)
end

local function makeInvisibleBlocker(name, size, cframe)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Transparency = 1
	p.CanCollide = true
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size
	p.CFrame = cframe
	p.Parent = model
	return p
end

local function createMovingSpotlight(name, position, initialLookAt, color)
	local pivot = Instance.new("Part")
	pivot.Name = name .. "_Pivot"
	pivot.Anchored = true
	pivot.CanCollide = false
	pivot.Transparency = 1
	pivot.Size = Vector3.new(1, 1, 1)
	pivot.CFrame = CFrame.new(position, initialLookAt)
	pivot.Parent = model

	local lightPart = Instance.new("Part")
	lightPart.Name = name
	lightPart.Anchored = true
	lightPart.CanCollide = false
	lightPart.Size = Vector3.new(1.5, 1.5, 1.5)
	lightPart.Material = Enum.Material.Metal
	lightPart.Color = Color3.fromRGB(40, 40, 40)
	lightPart.CFrame = pivot.CFrame
	lightPart.Parent = model

	local spot = Instance.new("SpotLight")
	spot.Color = color
	spot.Brightness = SPOTLIGHT_BRIGHTNESS
	spot.Range = SPOTLIGHT_RANGE
	spot.Angle = SPOTLIGHT_ANGLE
	spot.Face = Enum.NormalId.Front
	spot.Shadows = true
	spot.Parent = lightPart

	return {
		Pivot = pivot,
		LightPart = lightPart,
		SpotLight = spot,
	}
end

local function createTerracedStand(name, centerPos, faceAngle)
	local baseCFrame = CFrame.new(centerPos) * CFrame.Angles(0, faceAngle, 0)

	for row = 1, STAND_ROWS do
		local rowHeight = STAND_STEP_HEIGHT * row
		local rowDepth = STAND_STEP_DEPTH
		local zOffset = ((STAND_ROWS - row) * STAND_STEP_DEPTH) - (STAND_DEPTH / 2) + (rowDepth / 2)

		makePart(
			name .. "_Row_" .. row,
			Vector3.new(STAND_WIDTH, rowHeight, rowDepth),
			baseCFrame * CFrame.new(0, rowHeight / 2, zOffset),
			Color3.fromRGB(230, 230, 235),
			Enum.Material.Marble
		)
	end

	-- Optional low rear wall
	makePart(
		name .. "_BackWall",
		Vector3.new(STAND_WIDTH, 6, 1.5),
		baseCFrame * CFrame.new(0, 3, (STAND_DEPTH / 2) + 0.75),
		Color3.fromRGB(245, 245, 245),
		Enum.Material.Marble
	)

	-- Optional side walls
	makePart(
		name .. "_LeftWall",
		Vector3.new(1.5, 6, STAND_DEPTH),
		baseCFrame * CFrame.new(-(STAND_WIDTH / 2) - 0.75, 3, 0),
		Color3.fromRGB(245, 245, 245),
		Enum.Material.Marble
	)

	makePart(
		name .. "_RightWall",
		Vector3.new(1.5, 6, STAND_DEPTH),
		baseCFrame * CFrame.new((STAND_WIDTH / 2) + 0.75, 3, 0),
		Color3.fromRGB(245, 245, 245),
		Enum.Material.Marble
	)
end

local function createCurvedTerracedStand(name, centerAngleDegrees)
	local halfArc = math.rad(STAND_ARC_DEGREES / 2)
	local centerAngle = math.rad(centerAngleDegrees)

	for row = 1, STAND_ROWS do
		local rowInner = STAND_INNER_RADIUS + ((row - 1) * STAND_STEP_DEPTH)
		local rowOuter = rowInner + STAND_STEP_DEPTH
		local rowRadius = (rowInner + rowOuter) / 2
		local rowHeight = row * STAND_STEP_HEIGHT

		for seg = 1, STAND_SEGMENTS do
			local t0 = (seg - 1) / STAND_SEGMENTS
			local t1 = seg / STAND_SEGMENTS

			local a0 = centerAngle - halfArc + (2 * halfArc * t0)
			local a1 = centerAngle - halfArc + (2 * halfArc * t1)
			local midAngle = (a0 + a1) / 2

			local p1 = CENTER + Vector3.new(math.cos(a0) * rowRadius, 0, math.sin(a0) * rowRadius)
			local p2 = CENTER + Vector3.new(math.cos(a1) * rowRadius, 0, math.sin(a1) * rowRadius)
			local mid = (p1 + p2) / 2
			local segLength = (p2 - p1).Magnitude

			makePart(
				name .. "_Row_" .. row .. "_Seg_" .. seg,
				Vector3.new(segLength + 0.2, rowHeight, STAND_STEP_DEPTH),
				CFrame.new(mid.X, FLOOR_HEIGHT + (rowHeight / 2), mid.Z) * CFrame.Angles(0, -midAngle, 0),
				Color3.fromRGB(235, 235, 240),
				Enum.Material.Marble
			)
		end
	end
end

local function createCurvedStandBackWall(name, centerAngleDegrees)
	local halfArc = math.rad(STAND_ARC_DEGREES / 2)
	local centerAngle = math.rad(centerAngleDegrees)
	local wallRadius = STAND_OUTER_RADIUS + 1

	for seg = 1, STAND_SEGMENTS do
		local t0 = (seg - 1) / STAND_SEGMENTS
		local t1 = seg / STAND_SEGMENTS

		local a0 = centerAngle - halfArc + (2 * halfArc * t0)
		local a1 = centerAngle - halfArc + (2 * halfArc * t1)
		local midAngle = (a0 + a1) / 2

		local p1 = CENTER + Vector3.new(math.cos(a0) * wallRadius, 0, math.sin(a0) * wallRadius)
		local p2 = CENTER + Vector3.new(math.cos(a1) * wallRadius, 0, math.sin(a1) * wallRadius)
		local mid = (p1 + p2) / 2
		local segLength = (p2 - p1).Magnitude

		makePart(
			name .. "_BackWallSeg_" .. seg,
			Vector3.new(segLength + 0.2, STAND_WALL_HEIGHT, 1.5),
			CFrame.new(mid.X, FLOOR_HEIGHT + (STAND_WALL_HEIGHT / 2), mid.Z) * CFrame.Angles(0, -midAngle, 0),
			Color3.fromRGB(250, 250, 250),
			Enum.Material.Marble
		)
	end
end

local function createReflectivePool(name, centerAngleDegrees)
	local halfArc = math.rad(POOL_ARC_DEGREES / 2)
	local centerAngle = math.rad(centerAngleDegrees)

	for seg = 1, POOL_SEGMENTS do
		local t0 = (seg - 1) / POOL_SEGMENTS
		local t1 = seg / POOL_SEGMENTS

		local a0 = centerAngle - halfArc + (2 * halfArc * t0)
		local a1 = centerAngle - halfArc + (2 * halfArc * t1)
		local midAngle = (a0 + a1) / 2

		local innerP1 = CENTER + Vector3.new(math.cos(a0) * POOL_INNER_RADIUS, 0, math.sin(a0) * POOL_INNER_RADIUS)
		local innerP2 = CENTER + Vector3.new(math.cos(a1) * POOL_INNER_RADIUS, 0, math.sin(a1) * POOL_INNER_RADIUS)
		local outerP1 = CENTER + Vector3.new(math.cos(a0) * POOL_OUTER_RADIUS, 0, math.sin(a0) * POOL_OUTER_RADIUS)
		local outerP2 = CENTER + Vector3.new(math.cos(a1) * POOL_OUTER_RADIUS, 0, math.sin(a1) * POOL_OUTER_RADIUS)

		local midInner = (innerP1 + innerP2) / 2
		local midOuter = (outerP1 + outerP2) / 2
		local mid = (midInner + midOuter) / 2

		local radialDepth = POOL_OUTER_RADIUS - POOL_INNER_RADIUS
		local arcWidth = (midOuter - midInner).Magnitude * math.tan((a1 - a0) / 2) * 2

		local part = makePart(
			name .. "_Seg_" .. seg,
			Vector3.new(arcWidth + 1.5, POOL_HEIGHT, radialDepth),
			CFrame.new(mid.X, POOL_Y, mid.Z) * CFrame.Angles(0, -midAngle, 0),
			Color3.fromRGB(12, 18, 24),
			Enum.Material.SmoothPlastic
		)

		part.Reflectance = POOL_REFLECTANCE


	end
end

local function createPoolEdge(name, radius, centerAngleDegrees, arcDegrees, thickness, height, color, material)
	local halfArc = math.rad(arcDegrees / 2)
	local centerAngle = math.rad(centerAngleDegrees)
	local segments = POOL_SEGMENTS

	for seg = 1, segments do
		local t0 = (seg - 1) / segments
		local t1 = seg / segments

		local a0 = centerAngle - halfArc + (2 * halfArc * t0)
		local a1 = centerAngle - halfArc + (2 * halfArc * t1)
		local midAngle = (a0 + a1) / 2

		local p1 = CENTER + Vector3.new(math.cos(a0) * radius, 0, math.sin(a0) * radius)
		local p2 = CENTER + Vector3.new(math.cos(a1) * radius, 0, math.sin(a1) * radius)
		local mid = (p1 + p2) / 2
		local segLength = (p2 - p1).Magnitude

		makePart(
			name .. "_Seg_" .. seg,
			Vector3.new(segLength + 0.2, height, thickness),
			CFrame.new(mid.X, POOL_Y + (height / 2), mid.Z) * CFrame.Angles(0, -midAngle, 0),
			color,
			material
		)
	end
end

local function createContinuousLowerWall(name)
	for i = 0, LOWER_WALL_SEGMENTS - 1 do
		local a0 = (math.pi * 2 / LOWER_WALL_SEGMENTS) * i
		local a1 = (math.pi * 2 / LOWER_WALL_SEGMENTS) * (i + 1)
		local midAngle = (a0 + a1) / 2

		local p1 = CENTER + Vector3.new(math.cos(a0) * LOWER_WALL_RADIUS, 0, math.sin(a0) * LOWER_WALL_RADIUS)
		local p2 = CENTER + Vector3.new(math.cos(a1) * LOWER_WALL_RADIUS, 0, math.sin(a1) * LOWER_WALL_RADIUS)
		local mid = (p1 + p2) / 2
		local segLength = (p2 - p1).Magnitude

		makePart(
			name .. "_Seg_" .. i,
			Vector3.new(segLength + 0.2, LOWER_WALL_HEIGHT, LOWER_WALL_THICKNESS),
			CFrame.new(mid.X, FLOOR_HEIGHT + (LOWER_WALL_HEIGHT / 2), mid.Z) * CFrame.Angles(0, -midAngle, 0),
			Color3.fromRGB(250, 250, 250),
			Enum.Material.Marble
		)
	end
end

local function formatTimeString(totalSeconds)
	totalSeconds = math.max(0, math.floor(totalSeconds))
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	return string.format("%02d:%02d", minutes, seconds)
end

local function createBoothTimerDisplay(name, cframe, color)
	local timerPart = Instance.new("Part")
	timerPart.Name = name
	timerPart.Anchored = true
	timerPart.CanCollide = false
	timerPart.Transparency = 1
	timerPart.Size = Vector3.new(10, 3, 0.2)
	timerPart.CFrame = cframe
	timerPart.Parent = model

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TimerGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = true
	surfaceGui.CanvasSize = Vector2.new(600, 180)
	surfaceGui.Parent = timerPart

	local label = Instance.new("TextLabel")
	label.Name = "TimerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "03:00"
	label.Font = Enum.Font.Code
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.35
	label.Parent = surfaceGui

	return timerPart
end

local function syncSpotlightRig(rig)
	rig.LightPart.CFrame = rig.Pivot.CFrame
end

local function addArenaSpotlights(boxName, baseCFrame)
	local halfW = BOOTH_WIDTH / 2
	local roofY = BOOTH_HEIGHT + 1

	local leftPos = (baseCFrame * CFrame.new(-halfW + 3, roofY, -2)).Position
	local rightPos = (baseCFrame * CFrame.new(halfW - 3, roofY, -2)).Position

	table.insert(spotlightRigs, createMovingSpotlight(boxName .. "_SpotlightLeft", leftPos, CENTER, Color3.fromRGB(0, 170, 255)))
	table.insert(spotlightRigs, createMovingSpotlight(boxName .. "_SpotlightRight", rightPos, CENTER, Color3.fromRGB(255, 60, 60)))
end

local function createArchBetween(name, p1, p2, columnTopY, archRise, thickness, color, material)
	local baseLeft = Vector3.new(p1.X, columnTopY, p1.Z)
	local baseRight = Vector3.new(p2.X, columnTopY, p2.Z)

	local mid = (baseLeft + baseRight) / 2
	local spanVec = Vector3.new(baseRight.X - baseLeft.X, 0, baseRight.Z - baseLeft.Z)
	local span = spanVec.Magnitude
	if span < 0.1 then
		return
	end

	local dir = spanVec.Unit
	local archTop = Vector3.new(mid.X, columnTopY + archRise, mid.Z)

	local leftMid = (baseLeft + archTop) / 2
	local leftLength = (archTop - baseLeft).Magnitude

	makePart(
		name .. "_LeftDiag",
		Vector3.new(thickness, thickness, leftLength),
		CFrame.lookAt(leftMid, archTop) * CFrame.Angles(math.rad(90), 0, 0),
		color,
		material
	)

	local rightMid = (baseRight + archTop) / 2
	local rightLength = (archTop - baseRight).Magnitude

	makePart(
		name .. "_RightDiag",
		Vector3.new(thickness, thickness, rightLength),
		CFrame.lookAt(rightMid, archTop) * CFrame.Angles(math.rad(90), 0, 0),
		color,
		material
	)

	makePart(
		name .. "_Top",
		Vector3.new(span - ARCH_WIDTH_SHRINK, thickness, thickness),
		CFrame.new(archTop, archTop + dir),
		color,
		material
	)
end

local function createSlantedBooth(name, centerPos, lookAtPos, frameColor)
	local halfW = BOOTH_WIDTH / 2
	local halfD = BOOTH_DEPTH / 2

	local flatLookAt = Vector3.new(lookAtPos.X, centerPos.Y, lookAtPos.Z)
	local baseCFrame = CFrame.new(centerPos, flatLookAt)

	-- Floor is angled forward
	local floorCFrame = baseCFrame * CFrame.Angles(math.rad(BOOTH_PITCH_DEGREES), 0, 0)

	-- Roof stays level
	local roofY = centerPos.Y + BOOTH_HEIGHT
	local roofCenter = Vector3.new(centerPos.X, roofY, centerPos.Z)
	local roofCFrame = CFrame.new(roofCenter, roofCenter + baseCFrame.LookVector)

	-- Sample front and back floor heights
	local frontFloorPos = (floorCFrame * CFrame.new(0, 0, -halfD)).Position
	local backFloorPos = (floorCFrame * CFrame.new(0, 0, halfD)).Position

	local frontRoofPos = (roofCFrame * CFrame.new(0, 0, -halfD)).Position
	local backRoofPos = (roofCFrame * CFrame.new(0, 0, halfD)).Position

	local frontWallHeight = frontRoofPos.Y - frontFloorPos.Y
	local backWallHeight = backRoofPos.Y - backFloorPos.Y

	local frontWallCenterY = (frontRoofPos.Y + frontFloorPos.Y) / 2
	local backWallCenterY = (backRoofPos.Y + backFloorPos.Y) / 2

	-- Floor
	makePart(
		name .. "_Floor",
		Vector3.new(BOOTH_WIDTH, BOOTH_FLOOR_THICKNESS, BOOTH_DEPTH),
		floorCFrame,
		Color3.fromRGB(65, 65, 75),
		Enum.Material.Metal
	)

	-- Roof (level)
	makePart(
		name .. "_Roof",
		Vector3.new(BOOTH_WIDTH, 1, BOOTH_DEPTH),
		roofCFrame,
		Color3.fromRGB(85, 85, 95),
		Enum.Material.Metal
	)

	-- Back wall (shorter)
	makePart(
		name .. "_BackWall",
		Vector3.new(BOOTH_WIDTH, backWallHeight, BOOTH_WALL_THICKNESS),
		CFrame.new(
			(backFloorPos.X + backRoofPos.X) / 2,
			backWallCenterY,
			(backFloorPos.Z + backRoofPos.Z) / 2
		) * CFrame.Angles(0, select(2, baseCFrame:ToOrientation()), 0),
		Color3.fromRGB(75, 75, 85),
		Enum.Material.Metal
	)

	-- Front glass (taller)
	makeGlassPart(
		name .. "_FrontGlass",
		Vector3.new(BOOTH_WIDTH, frontWallHeight, BOOTH_GLASS_THICKNESS),
		CFrame.new(
			(frontFloorPos.X + frontRoofPos.X) / 2,
			frontWallCenterY,
			(frontFloorPos.Z + frontRoofPos.Z) / 2
		) * CFrame.Angles(0, select(2, baseCFrame:ToOrientation()), 0),
		0.35
	)

	-- Side glass
	local leftFloorMid = (floorCFrame * CFrame.new(-halfW, 0, 0)).Position
	local rightFloorMid = (floorCFrame * CFrame.new(halfW, 0, 0)).Position
	local leftRoofMid = (roofCFrame * CFrame.new(-halfW, 0, 0)).Position
	local rightRoofMid = (roofCFrame * CFrame.new(halfW, 0, 0)).Position

	makeGlassPart(
		name .. "_LeftGlass",
		Vector3.new(BOOTH_GLASS_THICKNESS, BOOTH_HEIGHT, BOOTH_DEPTH),
		CFrame.new(
			(leftFloorMid.X + leftRoofMid.X) / 2,
			(leftFloorMid.Y + leftRoofMid.Y) / 2,
			(leftFloorMid.Z + leftRoofMid.Z) / 2
		) * CFrame.Angles(0, select(2, baseCFrame:ToOrientation()), 0),
		0.45
	)

	makeGlassPart(
		name .. "_RightGlass",
		Vector3.new(BOOTH_GLASS_THICKNESS, BOOTH_HEIGHT, BOOTH_DEPTH),
		CFrame.new(
			(rightFloorMid.X + rightRoofMid.X) / 2,
			(rightFloorMid.Y + rightRoofMid.Y) / 2,
			(rightFloorMid.Z + rightRoofMid.Z) / 2
		) * CFrame.Angles(0, select(2, baseCFrame:ToOrientation()), 0),
		0.45
	)

	-- Rear lip on the floor
	makePart(
		name .. "_RearLip",
		Vector3.new(BOOTH_WIDTH - 2, 0.8, 2),
		floorCFrame * CFrame.new(0, 0.8, halfD - 1.2),
		Color3.fromRGB(55, 55, 60),
		Enum.Material.Metal
	)

	-- Neon frame: use the level roof/floor midpoint frame for now
	addNeonFrame(name, floorCFrame, roofCFrame, BOOTH_WIDTH, BOOTH_DEPTH, frameColor)

	-- Spotlights from roof/front
	addArenaSpotlights(name, roofCFrame, frameColor)

	-- Rear support arms start from back lower area
	local leftSupportStart = (floorCFrame * CFrame.new(-halfW + 2, 1, halfD - 1)).Position
	local leftSupportEnd = leftSupportStart + (baseCFrame.LookVector * -BOOTH_SUPPORT_LENGTH) + Vector3.new(0, -6, 0)
	local leftMid = (leftSupportStart + leftSupportEnd) / 2
	local leftLength = (leftSupportEnd - leftSupportStart).Magnitude

	makePart(
		name .. "_SupportLeft",
		Vector3.new(BOOTH_SUPPORT_THICKNESS, BOOTH_SUPPORT_THICKNESS, leftLength),
		CFrame.lookAt(leftMid, leftSupportEnd),
		Color3.fromRGB(90, 90, 100),
		Enum.Material.Metal
	)

	local rightSupportStart = (floorCFrame * CFrame.new(halfW - 2, 1, halfD - 1)).Position
	local rightSupportEnd = rightSupportStart + (baseCFrame.LookVector * -BOOTH_SUPPORT_LENGTH) + Vector3.new(0, -6, 0)
	local rightMid = (rightSupportStart + rightSupportEnd) / 2
	local rightLength = (rightSupportEnd - rightSupportStart).Magnitude

	makePart(
		name .. "_SupportRight",
		Vector3.new(BOOTH_SUPPORT_THICKNESS, BOOTH_SUPPORT_THICKNESS, rightLength),
		CFrame.lookAt(rightMid, rightSupportEnd),
		Color3.fromRGB(90, 90, 100),
		Enum.Material.Metal
	)

	makePart(
		name .. "_SupportFootLeft",
		Vector3.new(3, 3, 3),
		CFrame.new(leftSupportEnd),
		Color3.fromRGB(100, 100, 110),
		Enum.Material.Metal
	)

	makePart(
		name .. "_SupportFootRight",
		Vector3.new(3, 3, 3),
		CFrame.new(rightSupportEnd),
		Color3.fromRGB(100, 100, 110),
		Enum.Material.Metal
	)

	createSpawnMarker(
		name .. "_SpawnMarker",
		baseCFrame * CFrame.new(0, 1, 5.5)
	)

	local camPos = (baseCFrame * CFrame.new(0, 10, -5)).Position
	local camCFrame = CFrame.lookAt(camPos, CENTER + Vector3.new(0, BOARD_Y + 2, 0))
	createCameraMarker(name .. "_CameraMarker", camCFrame)

	local timerY = centerPos.Y + BOOTH_HEIGHT * 0.72
	local timerOffset = (baseCFrame.LookVector * -(BOOTH_DEPTH / 2 + 0.8))
	local timerPos = Vector3.new(centerPos.X, timerY, centerPos.Z) + timerOffset

	local timerCFrame = CFrame.new(timerPos, timerPos + baseCFrame.LookVector)

	-- createSpawnMarker(name .. "_SpawnMarker", floorCFrame * CFrame.new(0, 3, 1))
	-- createCameraMarker(name .. "_CameraMarker", floorCFrame * CFrame.new(0, 9, 8))

	createBoothTimerDisplay(name .. "_TimerDisplay", timerCFrame, frameColor)

end

--==================================================
-- FLOOR
--==================================================

makeCylinder(
	"ArenaFloor",
	CENTER + Vector3.new(0, FLOOR_HEIGHT / 2, 0),
	FLOOR_RADIUS,
	FLOOR_HEIGHT,
	Color3.fromRGB(0, 0, 0),
	Enum.Material.Slate
)

--==================================================
-- BOARD
--==================================================

local boardSize = BOARD_TILE_SIZE * 8
local boardTotal = boardSize + BOARD_BORDER * 2

--makePart(
--   "BoardBorder",
--   Vector3.new(boardTotal, BOARD_THICKNESS, boardTotal),
--   CFrame.new(CENTER + Vector3.new(0, BOARD_Y, 0)),
--   Color3.fromRGB(111, 78, 55),
--  Enum.Material.Wood
--)

--for _, i in ipairs({0, 2}) do
--    local angle = math.rad(i * 90)
--    local x = math.cos(angle) * STAND_OFFSET
--    local z = math.sin(angle) * STAND_OFFSET

--   createTerracedStand(
--       "SpectatorStand_" .. i,
--       CENTER + Vector3.new(x, STAND_BASE_Y, z),
--       -angle
--  )   )
-- end

local startX = CENTER.X - (boardSize / 2) + (BOARD_TILE_SIZE / 2)
local startZ = CENTER.Z - (boardSize / 2) + (BOARD_TILE_SIZE / 2)

for row = 0, 7 do
	for col = 0, 7 do
		local isLight = ((row + col) % 2 == 0)
		local x = startX + col * BOARD_TILE_SIZE
		local z = startZ + row * BOARD_TILE_SIZE

		makePart(
			("Tile_%d_%d"):format(row + 1, col + 1),
			Vector3.new(BOARD_TILE_SIZE, BOARD_THICKNESS + 0.05, BOARD_TILE_SIZE),
			CFrame.new(x, BOARD_Y + 0.1, z),
			isLight and Color3.fromRGB(231, 225, 208) or Color3.fromRGB(63, 63, 70),
			Enum.Material.Marble
		)
	end
end

createCameraMarker("BoardCenter", CFrame.new(CENTER + Vector3.new(0, BOARD_Y + 0.6, 0)))

--==================================================
-- COLUMNS
--==================================================

local columnPositions = {}

for i = 0, WALL_SEGMENTS - 1 do
	local angle = (math.pi * 2 / WALL_SEGMENTS) * i
	local x = math.cos(angle) * WALL_RADIUS
	local z = math.sin(angle) * WALL_RADIUS

	local pos = CENTER + Vector3.new(x, FLOOR_HEIGHT + COLUMN_HEIGHT / 2, z)
	table.insert(columnPositions, {
		angle = angle,
		top = CENTER + Vector3.new(x, COLUMN_TOP_Y, z),
	})

	local column = Instance.new("Part")
	column.Name = "WallColumn_" .. i
	column.Anchored = true
	column.Shape = Enum.PartType.Cylinder
	column.Material = Enum.Material.Marble
	column.Color = Color3.fromRGB(255, 255, 255)
	column.Size = Vector3.new(COLUMN_HEIGHT, COLUMN_RADIUS * 2, COLUMN_RADIUS * 2)
	column.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	column.TopSurface = Enum.SurfaceType.Smooth
	column.BottomSurface = Enum.SurfaceType.Smooth
	column.Parent = model
end

--==================================================
-- TOP RING + ARCHES
--==================================================

for i = 1, #columnPositions do
	local a = columnPositions[i]
	local b = columnPositions[(i % #columnPositions) + 1]

	local midAngle = (a.angle + b.angle) / 2
	local skipSegment = false

	if angleDifference(midAngle, NORTH_BOX_ANGLE) < BOX_GAP_ANGLE / 2 then
		skipSegment = true
	end

	if angleDifference(midAngle, SOUTH_BOX_ANGLE) < BOX_GAP_ANGLE / 2 then
		skipSegment = true
	end

	if not skipSegment then
		local p1 = Vector3.new(a.top.X, TOP_RING_Y, a.top.Z)
		local p2 = Vector3.new(b.top.X, TOP_RING_Y, b.top.Z)

		createBeamBetween(
			"TopRing_" .. i,
			p1,
			p2,
			TOP_RING_WIDTH,
			TOP_RING_HEIGHT,
			Color3.fromRGB(255, 255, 255),
			Enum.Material.Marble
		)

		createArchBetween(
			"Arch_" .. i,
			a.top,
			b.top,
			COLUMN_TOP_Y,
			ARCH_HEIGHT,
			ARCH_THICKNESS,
			Color3.fromRGB(255, 255, 255),
			Enum.Material.Marble
		)
	end
end

--==================================================
-- BOOTHS
--==================================================

local northBoothPos = Vector3.new(CENTER.X, BOOTH_BASE_Y, CENTER.Z - BOOTH_OFFSET)
local southBoothPos = Vector3.new(CENTER.X, BOOTH_BASE_Y, CENTER.Z + BOOTH_OFFSET)

createSlantedBooth("PlayerBox_Blue", northBoothPos, CENTER, Color3.fromRGB(0, 170, 255))
createSlantedBooth("PlayerBox_Red", southBoothPos, CENTER, Color3.fromRGB(255, 60, 60))

-- Left stand
createCurvedTerracedStand("SpectatorStand_Left", 180)
createCurvedStandBackWall("SpectatorStand_Left", 180)

-- Right stand
createCurvedTerracedStand("SpectatorStand_Right", 0)
createCurvedStandBackWall("SpectatorStand_Right", 0)

makeInvisibleBlocker(
	"BoardBlocker_North",
	Vector3.new(BOARD_SIZE + 4, BLOCKER_HEIGHT, BLOCKER_THICKNESS),
	CFrame.new(CENTER + Vector3.new(0, BLOCKER_HEIGHT / 2, -(HALF + 1)))
)

makeInvisibleBlocker(
	"BoardBlocker_South",
	Vector3.new(BOARD_SIZE + 4, BLOCKER_HEIGHT, BLOCKER_THICKNESS),
	CFrame.new(CENTER + Vector3.new(0, BLOCKER_HEIGHT / 2, (HALF + 1)))
)

makeInvisibleBlocker(
	"BoardBlocker_West",
	Vector3.new(BLOCKER_THICKNESS, BLOCKER_HEIGHT, BOARD_SIZE + 4),
	CFrame.new(CENTER + Vector3.new(-(HALF + 1), BLOCKER_HEIGHT / 2, 0))
)

makeInvisibleBlocker(
	"BoardBlocker_East",
	Vector3.new(BLOCKER_THICKNESS, BLOCKER_HEIGHT, BOARD_SIZE + 4),
	CFrame.new(CENTER + Vector3.new((HALF + 1), BLOCKER_HEIGHT / 2, 0))
)

makeInvisibleBlocker(
	"ArenaBoundary_North",
	Vector3.new(ARENA_BOUNDARY * 2, OUTER_HEIGHT, OUTER_THICKNESS),
	CFrame.new(CENTER + Vector3.new(0, OUTER_HEIGHT / 2, -ARENA_BOUNDARY))
)

makeInvisibleBlocker(
	"ArenaBoundary_South",
	Vector3.new(ARENA_BOUNDARY * 2, OUTER_HEIGHT, OUTER_THICKNESS),
	CFrame.new(CENTER + Vector3.new(0, OUTER_HEIGHT / 2, ARENA_BOUNDARY))
)

makeInvisibleBlocker(
	"ArenaBoundary_West",
	Vector3.new(OUTER_THICKNESS, OUTER_HEIGHT, ARENA_BOUNDARY * 2),
	CFrame.new(CENTER + Vector3.new(-ARENA_BOUNDARY, OUTER_HEIGHT / 2, 0))
)

makeInvisibleBlocker(
	"ArenaBoundary_East",
	Vector3.new(OUTER_THICKNESS, OUTER_HEIGHT, ARENA_BOUNDARY * 2),
	CFrame.new(CENTER + Vector3.new(ARENA_BOUNDARY, OUTER_HEIGHT / 2, 0))
)

createReflectivePool("ReflectivePool_Left", 180)
createReflectivePool("ReflectivePool_Right", 0)

createPoolEdge("ReflectivePool_Left_InnerEdge", POOL_INNER_RADIUS, 180, POOL_ARC_DEGREES, 1.2, 1.2, Color3.fromRGB(235, 235, 240), Enum.Material.Marble)
createPoolEdge("ReflectivePool_Left_OuterEdge", POOL_OUTER_RADIUS, 180, POOL_ARC_DEGREES, 1.2, 1.2, Color3.fromRGB(235, 235, 240), Enum.Material.Marble)

createPoolEdge("ReflectivePool_Right_InnerEdge", POOL_INNER_RADIUS, 0, POOL_ARC_DEGREES, 1.2, 1.2, Color3.fromRGB(235, 235, 240), Enum.Material.Marble)
createPoolEdge("ReflectivePool_Right_OuterEdge", POOL_OUTER_RADIUS, 0, POOL_ARC_DEGREES, 1.2, 1.2, Color3.fromRGB(235, 235, 240), Enum.Material.Marble)

createContinuousLowerWall("ArenaLowerWall")

--==================================================
-- SPOTLIGHT SWEEP
--==================================================

local spotlightControl = Instance.new("BoolValue")
spotlightControl.Name = "PreMatchSweepEnabled"
spotlightControl.Value = true
spotlightControl.Parent = model

RunService.Heartbeat:Connect(function()
	for i, rig in ipairs(spotlightRigs) do
		local pos = rig.Pivot.Position

		if spotlightControl.Value then
			local t = tick()
			local offsetX = math.sin(t * 0.8 + i) * 20
			local offsetZ = math.cos(t * 0.6 + i) * 10
			local offsetY = 6 + math.sin(t * 1.2 + i) * 4

			local target = CENTER + Vector3.new(offsetX, offsetY, offsetZ)
			rig.Pivot.CFrame = CFrame.new(pos, target)
		else
			rig.Pivot.CFrame = CFrame.new(pos, CENTER)
		end

		syncSpotlightRig(rig)
	end
end)

print("Arena generated.")
