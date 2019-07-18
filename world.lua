local lines = {{300, 100, 500, 200, 300, 400}}

function drawLines(lines)
  for i, line in pairs(lines) do
    if table.getn(line) > 3 then
      love.graphics.line(line)
    end
  end
end

function addLine(line)
  table.insert(lines, line)
end

function getLines()
  return lines
end

function addObject(object)
  for i, line in pairs(object) do
    table.insert(lines, line)
  end
end

function drawWorld()
  love.graphics.setColor(0, 0, 0)
  drawLines(lines)
end

function loadWorld(state)
  for i, line_data in pairs(state.lines) do
    table.insert(lines, line_data.points)  
  end
end

function selectObject(startx, starty, endx, endy)
  minx = math.min(startx, endx)
  miny = math.min(starty, endy)
  maxx = math.max(startx, endx)
  maxy = math.max(starty, endy)
  local bufferLines = {}
  for i, line in pairs(lines) do
    local x, y
    local bufferLine = {}
    for i, coordinate in pairs(line) do
      if i % 2 == 1 then
        x = coordinate
      else
        y = coordinate
        if not (x == nil) and not (y == nil) and x >= minx and x <= maxx and y >= miny and y <= maxy then
          table.insert(bufferLine, x - minx)                    
          table.insert(bufferLine, y - miny) 
        else
          if table.getn(bufferLine) > 3 then
            table.insert(bufferLines, bufferLines)
          end
          bufferLine = {}
        end
      end
    end
    if table.getn(bufferLine) > 3 then
      table.insert(bufferLines, bufferLine)
    end
  end

  return bufferLines
end

function saveWorld()
  local state = {}
  state.lines = {}
  for i, line in pairs(lines) do
    local line_data = {}
    line_data.points = line
    table.insert(state.lines, line_data)
  end
  return state
end

function eraseLines(selector)
  local newLines = {}
  for i, line in pairs(lines) do
    local newline = {}
    local x, y
    for j, coordinate in pairs(line) do
      if j % 2 == 1 then
        x = coordinate
      else
        y = coordinate
        local data = {}
        data.x = x
        data.y = y
        if (not (x == nil) and not (y == nil)) and selector(data) then
          if table.getn(newline) > 3 then
            table.insert(newLines, newline)
            newline = {}
          end
        else
          -- Include this point in the line
          table.insert(newline, x)
          table.insert(newline, y)
        end
      end
    end
    if table.getn(newline) > 3 then
      table.insert(newLines, newline)
    end
  end
  lines = newLines
end
