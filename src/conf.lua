function love.conf(t)
    t.title = "Football Chess"
    t.author = "Italo Seara"
    t.window.icon = "assets/images/icon.png"
    
    t.console = false
    t.window.vsync = true

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
