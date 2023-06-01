local Board = require "assets.scripts.board"
require "conf"

local board

function love.load()
    love.window.setMode(
        Config.board.width * Config.board.cell.width,
        Config.board.height * Config.board.cell.height
    )

    board = Board()
end

function love.update(dt)
    board:update()
end

function love.draw()
    board:draw()
end
