require 'world'
require 'player'
require 'drawing'

local vectors = {}
local intersections = {}

local segments = {}
local playerPos = {}

local OFFSET_ANGLE = 0.01

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function TableConcat(t1,t2)
  for i=1,#t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end

function calcVisible()
  vectors = {}
  intersections = {}

  local segments = getSegments()
  local playerPos = getPlayerPos()

  -- Add lines around screen border
  width, height = love.graphics.getDimensions()
  offsetx, offsety = getOffset()

  local topLeftx, topLefty = -offsetx, -offsety
  local topRightx, topRighty = width - offsetx, -offsety
  local bottomLeftx, bottomLefty = -offsetx, height - offsety
  local bottomRightx, bottomRighty = width - offsetx, height - offsety

  local borderLines = {}
  local playerPosx, playerPosy = playerPos
  if playerPos[2] > - offsety then
    table.insert(borderLines, {topLeftx, topLefty, topRightx, topRighty})
  end
  if playerPos[1] < width - offsetx then
    table.insert(borderLines, {topRightx, topRighty, bottomRightx, bottomRighty})
  end
  if playerPos[2] < height - offsety then
    table.insert(borderLines, {bottomRightx, bottomRighty, bottomLeftx, bottomLefty})
  end
  if playerPos[1] > 0 - offsetx then
    table.insert(borderLines, {bottomLeftx, bottomLefty, topLeftx, topLefty})
  end
  

  for i, segment in pairs(segments) do
    local startPoint = {segment[0], segment[1]}
    local vector = toVector(playerPos, startPoint)
    local polar = vecToPolar(vector)

    local posOffset = table.shallow_copy(polar)
    posOffset.arg = posOffset.arg + OFFSET_ANGLE
    posOffset.mag = 10000

    local negOffset = table.shallow_copy(polar)
    negOffset.arg = negOffset.arg - OFFSET_ANGLE
    negOffset.mag = 10000

    table.insert(vectors, vector)
    table.insert(vectors, polarToVec(posOffset))
    table.insert(vectors, polarToVec(negOffset))
  end
  
  for i, line in pairs(borderLines) do
    for j, coordinate in pairs(line) do
      if j % 2 == 1 and j < table.getn(line) then
          local points = { line[j], line[j + 1] }
          table.insert(vectors, toVector(playerPos, points))
      end
    end
  end

  -- TODO: Try to remove uneccessary "wiggle" rays for
  -- continuous line segments
  --
  -- Could be done by iterating through segments in a
  -- line and only wiggling when the delta of the angle from
  -- the player to a segment changes sign

  local allLines = {}
  TableConcat(allLines, segments)
  TableConcat(borderLines, segments)

  for i, vector in pairs(vectors) do
    -- Rasterize the vector onto the cell grid until it
    -- hits a segment

    local minT = 1
    for j, line in pairs(allLines) do
      for k, coordinate in pairs(line) do
        if k % 2 == 1 and k <= (table.getn(line) - 3) then
          local firstPoint = { line[k], line[k + 1] }
          local secondPoint = { line[k + 2], line[k + 3] }
          lineVec = toVector(firstPoint, secondPoint)

          tInt = calcIntersection(vector, lineVec)

          if tInt and tInt < minT then
            minT = tInt
          end
        end
      end
    end

    if minT then
      intX = playerPos[1] + (vector.dx) * minT
      intY = playerPos[2] + (vector.dy) * minT

      -- print("Vector source: " .. vector.x .. ", " .. vector.y)
      -- print("Vector dest: " .. (vector.x + vector.dx) .. ", " .. (vector.y + vector.dy))
-- 
      -- print("Segment source: " .. firstPoint[1] .. ", " .. firstPoint[2])
      -- print("Segment dest: " .. secondPoint[1] .. ", " .. secondPoint[2])
-- 
      -- print("T1: " .. minT)
      -- print("Int point: " .. intX .. ", " .. intY)

      -- table.insert(intersections, { intX, intY })
      vectors[i] = toVector({playerPos[1], playerPos[2]}, { intX, intY })
    end
  end

  vectors = removeNil(vectors)
  -- Sort vectors by angle from player
  table.sort(vectors, sortVec)
end

function castVector(vec)
  blueSquares = {}

  x0 = vec.x
  y0 = vec.y

  dx = vec.dx
  dy = vec.dy

  if not dx == 0 then
    gradient = dy / dx
  end
  
  if dx > 0 and dy > 0 and gradient > 0 and gradient <= 1 then
    local cellx = getCellPoint(x0, y0)

    -- Convert cell index to world coordinates
    local cellxCoord = cellx * CELL_SIZE 

    for cellEdgeX = cellxCoord, x0 + dx, CELL_SIZE do
      y = y0 + gradient * (cellEdgeX - x0)   
      local _, celly = getCellPoint(cellEdgeX, y) 

      table.insert(blueSquares, {cellxCoord
    end
  end

function removeNil(arr) 
  local newArr = {}
  for i, val in pairs(arr) do
    if not (val == nil) then
      table.insert(newArr, val)
    end
  end
  return newArr
end

function clamp(val, lower, upper)
  if val < lower then
    return lower
  elseif val > upper then
    return upper
  else
    return val
  end
end

function sortVec(vec1, vec2)
  return vecArg(vec1) < vecArg(vec2)
end

function toVector(point1, point2)
  local newVec = {}
  newVec.x = point1[1]
  newVec.y = point1[2]
  newVec.dx = point2[1] - point1[1]
  newVec.dy = point2[2] - point1[2]
  return newVec
end

function vecToPoints(vec)
  return { vec.x, vec.y, vec.x + vec.dx, vec.y + vec.dy }
end

function vecArg(vec)
  return math.atan2(vec.dx, -vec.dy) - math.pi / 2
end

function vecMag(vec)
  return math.sqrt(math.pow(vec.dx, 2) + math.pow(vec.dy, 2))
end

function vecToPolar(vec)
  local polar = {}
  polar.x = vec.x
  polar.y = vec.y

  polar.arg = vecArg(vec)
  polar.mag = vecMag(vec)
  
  return polar
end

function polarToVec(polar)
  local vec = {}
  vec.x = polar.x
  vec.y = polar.y

  vec.dx = math.cos(polar.arg) * polar.mag
  vec.dy = math.sin(polar.arg) * polar.mag

  return vec
end

function calcIntersection(vec1, vec2)
  t2 = (vec1.dx*(vec2.y-vec1.y) + vec1.dy*(vec1.x-vec2.x))/(vec2.dx*vec1.dy - vec2.dy*vec1.dx)
  t1 = (vec2.x+vec2.dx*t2-vec1.x)/vec1.dx

  if t1 > 0 and t2 > 0 and t2 < 1 then
    return t1
  end

  return nil
end

function drawVectors()
  love.graphics.setColor(1, 0, 0)

  for i, vector in pairs(vectors) do
    love.graphics.line(vecToPoints(vector))
    love.graphics.circle("fill", vector.x + vector.dx, vector.y + vector.dy, 5)
  end
end

function drawVision()
  local playerPos = getPlayerPos()

  love.graphics.setColor(1, 1, 1)

  for i = 1,(table.getn(vectors) - 1) do
    love.graphics.polygon("fill", {playerPos[1], playerPos[2], 
      vectors[i].x + vectors[i].dx, vectors[i].y + vectors[i].dy, 
      vectors[i + 1].x + vectors[i + 1].dx, vectors[i + 1].y + vectors[i + 1].dy})
  end
  local width, height = love.graphics.getDimensions()

  local offsetx, offsety = getOffset()

  if not ((playerPos[1] < - offsetx and playerPos[2] < - offsety) or
          (playerPos[1] > width - offsetx and playerPos[2] < - offsety) or
          (playerPos[1] < - offsetx and playerPos[2] > height - offsety) or
          (playerPos[1] > width - offsetx and playerPos[2] > height - offsety)) then
    local last = table.getn(vectors)
    love.graphics.polygon("fill", {playerPos[1], playerPos[2], 
                                        vectors[last].x + vectors[last].dx, vectors[last].y + vectors[last].dy, 
                                        vectors[1].x + vectors[1].dx, vectors[1].y + vectors[1].dy})
  end

--  for i, int in pairs(intersections) do
--    love.graphics.circle("fill" , int[1], int[2], 3)
--  end

  love.graphics.setColor(0, 0, 0)
end
