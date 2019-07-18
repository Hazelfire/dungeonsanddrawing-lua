
local players = {}

playerColors = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 0}, {1, 0, 1}, {0, 1, 1}}

function drawPlayers()
  for i, player in pairs(players) do
    love.graphics.setColor(player.color[1], player.color[2], player.color[3], 1)
    love.graphics.circle("fill", player.x, player.y, 10)
  end
end

function updatePlayers(dt)
  for i, player in pairs(players) do
    local nx = player.joystick:getGamepadAxis("leftx")
    local ny = player.joystick:getGamepadAxis("lefty")
    if nx * nx + ny * ny > 0.09 then
      local speed = 100
      if player.joystick:getGamepadAxis("triggerright") > 0.5 then
        speed = 200
      end
      player.x = player.x + nx * speed * dt;
      player.y = player.y + ny * speed * dt;
    end
  end
end

function love.joystickadded(joystick)
  for i, player in pairs(players) do
    if player.joystick:getID() == joystick:getID() then
      return
    end
  end
  player = {}
  player.x = 0
  player.y = 0
  player.color = playerColors[(table.getn(players) % 6) + 1]
  player.joystick = joystick
  table.insert(players, player)
end
