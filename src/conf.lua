function love.conf(t)
    t.title = "Football Chess" -- The title of the window the game is in (string)
    t.author = "Italo Seara"   -- The author of the game (string)
    t.console = true           -- Attach a console (boolean, Windows only)
    t.window.vsync = true      -- Enable vertical sync (boolean)

    Config = {
        board = {
            width = 8,
            height = 10,
            cell = {
                width = 80,
                height = 80
            },
            color = {
                light = { 240, 217, 181 },
                dark = { 181, 136, 99 },
            }
        },
    }
end
