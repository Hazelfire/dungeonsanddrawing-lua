lines = {}
currentline = {}
startx = 0
starty = 0
down = false

players = {}

offsetx = 0
offsety = 0

lastGrabx = 0
lastGraby = 0
grabDown = false
----------------------------------------------
-- Pickle.lua
-- A table serialization utility for lua
-- Steve Dekorte, http://www.dekorte.com, Apr 2000
-- Freeware
----------------------------------------------

function pickle(t)
  return Pickle:clone():pickle_(t)
end

Pickle = {
  clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end 
}

function Pickle:pickle_(root)
  if type(root) ~= "table" then 
    error("can only pickle tables, not ".. type(root).."s")
  end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""

  while table.getn(self._refToTable) > savecount do
    savecount = savecount + 1
    local t = self._refToTable[savecount]
    s = s.."{\n"
    for i, v in pairs(t) do
        s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
    end
    s = s.."},\n"
  end

  return string.format("{%s}", s)
end

function Pickle:value_(v)
  local vtype = type(v)
  if     vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else --error("pickle a "..type(v).." is not supported")
  end  
end

function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then 
    if t == self then error("can't pickle the pickle class") end
    table.insert(self._refToTable, t)
    ref = table.getn(self._refToTable)
    self._tableToRef[t] = ref
  end
  return ref
end

----------------------------------------------
-- unpickle
----------------------------------------------

function unpickle(s)
  if type(s) ~= "string" then
    error("can't unpickle a "..type(s)..", only strings")
  end
  local gentables = loadstring("return "..s)
  local tables = gentables()
  
  for tnum = 1, table.getn(tables) do
    local t = tables[tnum]
    local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
    for i, v in pairs(tcopy) do
      local ni, nv
      if type(i) == "table" then ni = tables[i[1]] else ni = i end
      if type(v) == "table" then nv = tables[v[1]] else nv = v end
      t[i] = nil
      t[ni] = nv
    end
  end
  return tables[1]
end



function love.load() 
  love.window.setFullscreen(true)
  love.mouse.setVisible(false)

  if love.filesystem.getInfo("save") then
    local state = unpickle(love.filesystem.read("save"))
    for i, line_data in pairs(state.lines) do
      table.insert(lines, line_data.points)  
    end
  end
end

function love.update(dt)
  if love.mouse.isDown(1) then
    down = true
    x, y = love.mouse.getPosition()
    table.insert(currentline, x - offsetx)
    table.insert(currentline, y - offsety)
  else
    if down then 
      down = false
      table.insert(lines, currentline)
      currentline = {}
    end
  end 
  -- If right is down
  if love.mouse.isDown(2) then
    local mousex, mousey = love.mouse.getPosition()
    mousex = mousex - offsetx
    mousey = mousey - offsety
    local newLines = {}
    -- For every line
    for i, line in pairs(lines) do
      local newline = {}
      local x = 0
      local y = 0
      for j, coordinate in pairs(line) do
        if j % 2 == 1 then
          x = coordinate
        else
          y = coordinate
          -- If we should erase
          if math.sqrt((x - mousex) ^ 2 + (y - mousey) ^ 2) < 10 then
            -- Don't include current point
            -- Add line if it's big enough
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

  for i, player in pairs(players) do
    local nx = player.joystick:getGamepadAxis("leftx")
    local ny = player.joystick:getGamepadAxis("lefty")

    local speed = 100
    if player.joystick:getGamepadAxis("triggerright") > 0.5 then
      speed = 200
    end
    player.x = player.x + nx * speed * dt;
    player.y = player.y + ny * speed * dt;
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

function love.draw()
  love.graphics.translate(offsetx, offsety)
  love.graphics.setBackgroundColor(1, 1, 1, 1)
  love.graphics.setColor(0, 0, 0, 1)

  if table.getn(currentline) > 3 then
    love.graphics.line(currentline)
  end
  

  for i, line in pairs(lines) do
    if table.getn(line) > 3 then
      love.graphics.line(line)
    end
  end

  love.graphics.setColor(1, 0, 0, 1)
  for i, player in pairs(players) do
    love.graphics.circle("fill", player.x, player.y, 10)
  end


  local mousex, mousey = love.mouse.getPosition()
  love.graphics.setColor(0, 0, 0, 1)

  if love.mouse.isDown(2) then
    love.graphics.circle("line", mousex - offsetx, mousey - offsety, 10)
  else
    love.graphics.circle("fill", mousex - offsetx, mousey - offsety, 2)
  end



end


function love.joystickadded(joystick)
  player = {}
  player.x = 0
  player.y = 0
  player.joystick = joystick
  table.insert(players, player)
end

function map(tbl, f)
  local t = {}
  for k,v in pairs(tbl) do
      t[k] = f(v)
  end
  return t
end

function love.keypressed(key)
  if key == "s" then
    local state = {}
    state.lines = {}
    for i, line in pairs(lines) do
      local line_data = {}
      line_data.points = line
      table.insert(state.lines, line_data)
    end
    love.filesystem.write("save", pickle(state))
  end
end
