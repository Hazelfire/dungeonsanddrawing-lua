
local currentline = {}

local offsetx = 0
local offsety = 0

local lastGrabx = 0
local lastGraby = 0
local grabDown = false

local mode = "drawing"
local startSelect = false
local selectStartx = 0
local selectStarty = 0
local selectEndx = 0
local selectEndy = 0
local buffer = {}
local down = false

local scale = 1

function getOffset()
  return offsetx, offsety
end

function translateBuffer(lines, offsetx, offsety)
  local newlines = {}
  for i, line in pairs(lines) do
    local newline = {}
    for i, coordinate in pairs(line) do
      if i % 2 == 1 then
        table.insert(newline, coordinate + offsetx)        
      else
        table.insert(newline, coordinate + offsety)
      end
    end
    table.insert(newlines, newline)
  end
  return newlines
end

function updateDraw(dt)
  x, y = love.mouse.getPosition()
  if love.mouse.isDown(1) then
    down = true
    if mode == "select" then
      if not startSelect then
        selectStartx = x - offsetx
        selectStarty = y - offsety
        startSelect = true
      else
        selectEndx = x - offsetx
        selectEndy = y - offsety
      end
    else
      if not (mode == "paste") then
        table.insert(currentline, x - offsetx)
        table.insert(currentline, y - offsety)
      end
    end
  else
    if mode == "select" then
      startSelect = false
    end
    if down then 
      down = false
      if table.getn(currentline) > 3 then
        addLine(currentline)
      end
      currentline = {}
      if mode == "paste" then
        local translated = translateBuffer(buffer, x - offsetx, y - offsety)
        addObject(translated)
      end
    end
  end 
  -- If right is down
  if love.mouse.isDown(2) then
    local mousex, mousey = love.mouse.getPosition()
    mousex = mousex - offsetx
    mousey = mousey - offsety
    
    function closeToCursor(line)
      return math.sqrt((line[1] - mousex) ^ 2 + (line[2] - mousey) ^ 2) < 10 
    end

    circleSelector.func = closeToCursor
    circleSelector.boundingMin = {mousex - 10, mousey - 10}
    circleSelector.boundingMax = {mousex + 10, mousex + 10}

    eraseLines(circleSelector)
  end


  -- Grab
  if love.mouse.isDown(3) then
    if not grabDown then
      lastGrabx, lastGraby = love.mouse.getPosition()
      grabDown = true
    else
      local mousex, mousey = love.mouse.getPosition()
      offsetx = offsetx + (mousex - lastGrabx)
      offsety = offsety + (mousey - lastGraby)
      lastGrabx, lastGraby = mousex, mousey
    end
  else
    grabDown = false
  end

   

  local scrollspeed = 400
  if love.keyboard.isDown("left") then
    offsetx = offsetx + scrollspeed * dt;
  end

  if love.keyboard.isDown("right") then
    offsetx = offsetx - scrollspeed * dt;
  end

  if love.keyboard.isDown("up") then
    offsety = offsety + scrollspeed * dt;
  end

  if love.keyboard.isDown("down") then
    offsety = offsety - scrollspeed * dt;
  end

end

function drawDraw()
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print(mode .. " mode")
  love.graphics.translate(offsetx, offsety)
  love.graphics.scale(scale, scale)
  love.graphics.setBackgroundColor(0, 0, 0, 1)
  love.graphics.setColor(0, 0, 0, 1)

  local mousex, mousey = love.mouse.getPosition()

  if table.getn(currentline) > 3 then
    love.graphics.line(currentline)
  end

  if mode == "paste" then
    drawLines(translateBuffer(buffer, mousex - offsetx, mousey - offsety))
  end

  if love.mouse.isDown(2) then
    love.graphics.circle("line", mousex - offsetx, mousey - offsety, 10)
  else
    love.graphics.circle("fill", mousex - offsetx, mousey - offsety, 2)
  end

  

  if mode == "select" then
    love.graphics.rectangle("line", selectStartx, selectStarty, selectEndx - selectStartx, selectEndy - selectStarty)
  end
end

function drawKey(key)
  if key == "c" then
    mode = "select"
  elseif key == "y" then
    buffer = selectObject(selectStartx, selectStarty, selectEndx, selectEndy)
    mode = "paste"
  elseif key == "escape" then
    mode = "drawing"
  elseif key == "+" then
    scale = scale * 2
  elseif key == "-" then
    scale = scale / 2
  end

end
