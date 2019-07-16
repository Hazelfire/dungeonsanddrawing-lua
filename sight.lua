require 'world'
require 'player'

local vectors = {}
local intersections = {}

local lines = {}
local playerPos = {}

function calcVisible()
  vectors = {}
  intersections = {}

  local lines = getLines()
  local playerPos = getPlayerPos()

  for i, line in pairs(lines) do
    for j, coordinate in pairs(line) do
      if j % 2 == 1 and j < table.getn(line) then
          local points = { line[j], line[j + 1] }
          table.insert(vectors, toVector(playerPos, points))
      end
    end
  end

  local printed = false

  for i, vector in pairs(vectors) do
    for j, line in pairs(lines) do
      for k, coordinate in pairs(line) do
        if j % 2 == 1 and j <= table.getn(line) - 3 then
          local firstPoint = { line[j], line[j + 1] }
          local secondPoint = { line[j + 2], line[j + 3] }
          lineVec = toVector(firstPoint, secondPoint)

          tInt = calcIntersection(vector, lineVec)

          if tInt then
           
            if not printed then
              intX = vector.x + (vector.dx) * tInt
              intY = vector.y + (vector.dy) * tInt

              print("Vector source: " .. vector.x .. ", " .. vector.y)
              print("Vector dest: " .. (vector.x + vector.dx) .. ", " .. (vector.y + vector.dy))

              print("Segment source: " .. firstPoint[1] .. ", " .. firstPoint[2])
              print("Segment dest: " .. secondPoint[1] .. ", " .. secondPoint[2])

              print("T1: " .. tInt)
              print("Int point: " .. intX .. ", " .. intY)

              printed = true
            end

            table.insert(intersections, { intX, intY })
          end
        end
      end
    end
  end
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

function drawVectors()
  for i, vector in pairs(vectors) do
    love.graphics.line(vecToPoints(vector))
  end

  love.graphics.setColor(0, 0, 1)

  for i, int in pairs(intersections) do
    love.graphics.circle("fill" , int[1], int[2], 3)
  end
end

function calcIntersection(vec1, vec2)
  t2 = (vec1.dx*(vec2.y-vec1.y) + vec1.dy*(vec1.x-vec2.x))/(vec2.dx*vec1.dy - vec2.dy*vec1.dx)
  t1 = (vec2.x+vec2.dx*t2-vec1.x)/vec1.dx

  if t1 > 0 and t2 > 0 and t2 < 1 then
    return t1
  end

  return nil
end
