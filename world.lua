require 'drawing'

local segments = {{300, 100, 500, 200, 300, 400}}

local hashTable = {}
local CELL_SIZE = 10

function getCellLabel(x, y)
  local cellx, celly = getCellPoint(x, y)
  return cellx .. "," .. celly
end

function getCellPoint(x, y)
  local cellx = math.floor(x / CELL_SIZE)
  local celly = math.floor(y / CELL_SIZE)

  return cellx, celly
end

function drawSegments(segments)
  -- TODO: Compare this to checking all cells to see if they are
  -- on screen, instead of generating all hashes that are on 
  -- screen
  --
  -- TODO: Possible issue of segments being drawn multiple times 
  -- if in multiple buckets

  width, height = love.graphics.getDimensions()
  offsetX, offsetY = getOffsets()

  minCellx, minCelly = getCellPoint(-offsetX, -offsetY)
  maxCellx, maxCelly = getCellPoint(-offsetX + width, -offsetY + height)

  for cellx = minCellx, maxCellx do
    for celly = minCelly, maxCelly do
      local cellLabel = cellx .. "," .. celly
      
      if hashTable[cellLabel] then
        for i, segment in pairs(hashTable[cellLabel]) do
          love.graphics.line(segment)
        end
      end
    end
  end
end

function addSegment(segment)
  table.insert(segments, segment)

  startCellx, startCelly = getCellPoint(segment.startx, segment.starty)
  endCellx, endCelly = getCellPoint(segment.endx, segment.endy)

  for cellx = startCellx, endCellx do
    for celly = startCelly, endCelly do
      local cellLabel = cellx .. "," .. celly
      
      if hashTable[cellLabel] then
        table.insert(hashTable[cellLabel], segment)
      else
        hashTable[cellLabel] = {segment}
      end
    end
  end
end

function getSegments()
  return segments
end

function getSegmentsInCell(x, y)
  local cellLable = getCellLable(x, y)
  
  if hashTable[cellLable] then
    return hashTable[cellLable]
  else
    return {}
  end
end

function addObject(object)
  for i, segment in pairs(object) do
    table.insert(segments, segment)
  end
end

function drawWorld()
  love.graphics.setColor(0, 0, 0)
  drawSegments(segments)
end

function loadWorld(state)
  for i, segment in pairs(state.segments) do
    table.insert(segments, segment)  
  end
end

function selectObject(startx, starty, endx, endy)
  minx = math.min(startx, endx)
  miny = math.min(starty, endy)
  maxx = math.max(startx, endx)
  maxy = math.max(starty, endy)

  minCellx, minCelly = getCellPoint(-offsetX + minx, -offsetY + miny)
  maxCellx, maxCelly = getCellPoint(-offsetX + maxx, -offsetY + maxy)

  local bufferSegments = {}
  for cellx = minCellx, maxCellx do
    for celly = minCelly, maxCelly do
      local cellLabel = cellx .. "," .. celly
      if hashTable[cellLabel] then
        for i, segment in pairs(hashTable[cellLabel]) do
          local x = segment[0]
          local y = segment[1]

          if not (x == nil) and not (y == nil) and x >= minx and x <= maxx and y >= miny and y <= maxy then
            table.insert(bufferSegments, segment)
          end
        end
      end
    end
  end

  return bufferSegments
end

function saveWorld()
  local state = {}
  state.segments = {}
  for i, segment in pairs(segments) do
    table.insert(state.segments, segments)
  end
  return state
end

function eraseSegments(selector)
  boundingMin = selector.boundingMin
  boundingMax = selector.boundingMax
  minCellx, minCelly = getCellPoint(boundingMin[1], boundingMin[2])
  maxCellx, maxCelly = getCellPoint(boundingMax[1], boundingMax[2])

  for cellx = minCellx, maxCellx do
    for celly = minCelly, maxCelly do
      local cellLabel = cellx .. "," .. celly

      if hashTable[cellLabel] then
        for i, segment in pairs(hashTable[cellLabel]) do
          if selector.func(segment) then
            table.remove(hashTable[cellLabel], i)
          end
        end
      end
    end
  end
end
