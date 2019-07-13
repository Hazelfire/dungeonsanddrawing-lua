require 'pickle'
require 'player'
require 'world'
require 'drawing'

function love.load() 
  love.window.setFullscreen(true)
  love.mouse.setVisible(false)

  if love.filesystem.getInfo("save") then
    local state = unpickle(love.filesystem.read("save"))
    loadWorld(state)
  end
end



function love.update(dt)
  updatePlayers(dt)
  updateDraw(dt)
end


function love.draw()

  drawDraw()
  

  drawWorld()


  drawPlayers()

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
    love.filesystem.write("save", pickle(saveWorld()))
  else
    drawKey(key)
  end
end
