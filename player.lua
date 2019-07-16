
local players = {}

function getPlayerPos()
  return { players[1].x, players[1].y }
end

function drawPlayers()
  love.graphics.setColor(1, 0, 0, 1)
  for i, player in pairs(players) do
    love.graphics.circle("fill", player.x, player.y, 10)
  end
end

function updatePlayers(dt)
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
end

function love.joystickadded(joystick)
  player = {}
  player.x = 0
  player.y = 0
  player.joystick = joystick
  table.insert(players, player)
end
