local Class = require "libs.classic"

local Board = Class:extend()

function Board:new()
    self.width = Config.board.width
    self.height = Config.board.height

    self.cell = {
        width = Config.board.cell.width,
        height = Config.board.cell.height
    }
    self.colors = {
        black = { 181, 136, 99 },
        white = { 240, 217, 181 },
    }

    self.pieces = {
        image = love.graphics.newImage("assets/images/neo.png"),
        sprites = {},
    }

    self.pieces.width = self.pieces.image:getWidth() / 6
    self.pieces.height = self.pieces.image:getHeight() / 2

    -- Calculate the scale factor to fit the piece inside the cell
    local scale_x = self.cell.width / self.pieces.width
    local scale_y = self.cell.height / self.pieces.height

    self.pieces.scale = math.min(scale_x, scale_y)

    -- Create the sprites for each piece
    local white_pieces = {}
    local black_pieces = {}

    for i = 1, 6 do
        white_pieces[i] = love.graphics.newQuad(
            (i - 1) * self.pieces.width,
            0,
            self.pieces.width,
            self.pieces.height,
            self.pieces.image:getDimensions()
        )
    end

    for i = 1, 6 do
        black_pieces[i] = love.graphics.newQuad(
            (i - 1) * self.pieces.width,
            self.pieces.height,
            self.pieces.width,
            self.pieces.height,
            self.pieces.image:getDimensions()
        )
    end

    self.pieces.sprites = {
        -- White pieces
        K = white_pieces[1],
        Q = white_pieces[2],
        B = white_pieces[3],
        N = white_pieces[4],
        R = white_pieces[5],
        P = white_pieces[6],

        -- Black pieces
        k = black_pieces[1],
        q = black_pieces[2],
        b = black_pieces[3],
        n = black_pieces[4],
        r = black_pieces[5],
        p = black_pieces[6],
    }

    self.board = {
        { " ", " ", " ", " ", " ", " ", " ", " " }, -- Black's Goal
        { "r", "n", "b", "q", "k", "b", "n", "r" }, -- 8
        { "p", "p", "p", "p", "p", "p", "p", "p" }, -- 7
        { " ", " ", " ", " ", " ", " ", " ", " " }, -- 6
        { " ", " ", " ", " ", " ", " ", " ", " " }, -- 5
        { " ", " ", " ", " ", " ", " ", " ", " " }, -- 4
        { " ", " ", " ", " ", " ", " ", " ", " " }, -- 3
        { "P", "P", "P", "P", "P", "P", "P", "P" }, -- 2
        { "R", "N", "B", "Q", "K", "B", "N", "R" }, -- 1
        { " ", " ", " ", " ", " ", " ", " ", " " }, -- White's Goal
        -- A    B    C    D    E    F    G    H
    }

    self.highlightedSquares = {}
    self.highlightedPiece = {}

    self.turn = "w"
end

function Board:update(dt)
    local mouseX, mouseY = love.mouse.getPosition()

    if love.mouse.isDown(1) then -- Left mouse button is clicked
        -- Calculate the square coordinates based on the mouse position
        local squareX = math.floor(mouseX / self.cell.width) + 1
        local squareY = math.floor(mouseY / self.cell.height) + 1

        -- Check if the clicked square contains a piece
        local clickedPiece = self.board[squareY][squareX]

        if (clickedPiece ~= " ") and (
                (self.turn == "w" and string.upper(clickedPiece) == clickedPiece) or
                (self.turn == "b" and string.lower(clickedPiece) == clickedPiece)) then
            -- Calculate the possible moves for the clicked piece
            local possibleMoves = self:possibleMoves(squareY, squareX)

            -- Update the highlightedSquares with the possible moves
            self.highlightedSquares = possibleMoves
            self.highlightedPiece = { squareX, squareY }
        else
            -- If the click square is in the highlightedSquares, move the piece
            for i, v in ipairs(self.highlightedSquares) do
                if v[1] == squareY and v[2] == squareX then
                    self.board[squareY][squareX] = self.board[self.highlightedPiece[2]][self.highlightedPiece[1]]
                    self.board[self.highlightedPiece[2]][self.highlightedPiece[1]] = " "

                    -- Change the turn
                    if self.turn == "w" then
                        self.turn = "b"
                    else
                        self.turn = "w"
                    end
                end
            end

            -- Clear the highlightedSquares if an empty square is clicked
            self.highlightedSquares = {}
            self.highlightedPiece = {}
        end
    end
end

function Board:possibleMoves(x, y)
    local piece = self.board[x][y]
    local possibleMoves = {}

    if piece == "P" then -- White Pawn
        -- Calculate possible moves for a white pawn
        -- Check if the tile in front is empty
        if self.board[x - 1][y] == " " then
            table.insert(possibleMoves, { x - 1, y })
        end

        -- Check if the pawn is on its starting position and the two tiles in front are empty
        if x == 8 and self.board[x - 1][y] == " " and self.board[x - 2][y] == " " then
            table.insert(possibleMoves, { x - 2, y })
        end

        -- Check for capturing opponent's pieces diagonally
        if y > 1 and self.board[x - 1][y - 1] ~= " " then
            table.insert(possibleMoves, { x - 1, y - 1 })
        end
        if y < 9 and self.board[x - 1][y + 1] ~= " " then
            table.insert(possibleMoves, { x - 1, y + 1 })
        end
    elseif piece == "p" then -- Black Pawn
        -- Calculate possible moves for a black pawn
        -- Similar to the white pawn logic but with different movement direction
        -- Check if the tile in front is empty
        if self.board[x + 1][y] == " " then
            table.insert(possibleMoves, { x + 1, y })
        end

        -- Check if the pawn is on its starting position and the two tiles in front are empty
        if x == 3 and self.board[x + 1][y] == " " and self.board[x + 2][y] == " " then
            table.insert(possibleMoves, { x + 2, y })
        end

        -- Check for capturing opponent's pieces diagonally
        if y > 1 and self.board[x + 1][y - 1] ~= " " then
            table.insert(possibleMoves, { x + 1, y - 1 })
        end
        if y < 9 and self.board[x + 1][y + 1] ~= " " then
            table.insert(possibleMoves, { x + 1, y + 1 })
        end
    elseif piece == "R" or piece == "r" then -- Rook
        -- Calculate possible moves for a rook
        -- Check for possible moves in the same row
        for i = x - 1, 2, -1 do
            table.insert(possibleMoves, { i, y })
            if self.board[i][y] ~= " " then
                break
            end
        end

        for i = x + 1, 9 do
            table.insert(possibleMoves, { i, y })
            if self.board[i][y] ~= " " then
                break
            end
        end

        for j = y - 1, 1, -1 do
            table.insert(possibleMoves, { x, j })
            if self.board[x][j] ~= " " then
                break
            end
        end

        for j = y + 1, 9 do
            table.insert(possibleMoves, { x, j })
            if self.board[x][j] ~= " " then
                break
            end
        end
    elseif piece == "N" or piece == "n" then -- Knight
        -- Calculate possible moves for a knight
        local knightMoves = {
            { x - 2, y - 1 }, { x - 2, y + 1 },
            { x - 1, y - 2 }, { x - 1, y + 2 },
            { x + 1, y - 2 }, { x + 1, y + 2 },
            { x + 2, y - 1 }, { x + 2, y + 1 }
        }

        for _, move in ipairs(knightMoves) do
            local i, j = move[1], move[2]
            if i >= 2 and i <= 9 and j >= 2 and j <= 9 then
                table.insert(possibleMoves, { i, j })
            end
        end
    elseif piece == "B" or piece == "b" then -- Bishop
        -- Calculate possible moves for a bishop
        -- Check valid moves in the top left direction
        for i = x - 1, 2, -1 do
            local j = y - (x - i)
            if j < 1 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end

        -- Check valid moves in the top right direction
        for i = x - 1, 2, -1 do
            local j = y + (x - i)
            if j > 9 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end

        -- Check valid moves in the bottom left direction
        for i = x + 1, 9 do
            local j = y - (i - x)
            if j < 1 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end

        -- Check valid moves in the bottom right direction
        for i = x + 1, 9 do
            local j = y + (i - x)
            if j > 9 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end
    elseif piece == "Q" or piece == "q" then
        -- Check valid moves in the vertical and horizontal directions (rook-like moves)
        for i = x - 1, 2, -1 do
            table.insert(possibleMoves, { i, y })
            if self.board[i][y] ~= " " then
                break
            end
        end

        for i = x + 1, 9 do
            table.insert(possibleMoves, { i, y })
            if self.board[i][y] ~= " " then
                break
            end
        end

        for j = y - 1, 1, -1 do
            table.insert(possibleMoves, { x, j })
            if self.board[x][j] ~= " " then
                break
            end
        end

        for j = y + 1, 9 do
            table.insert(possibleMoves, { x, j })
            if self.board[x][j] ~= " " then
                break
            end
        end

        -- Check valid moves in the diagonal directions (bishop-like moves)
        for i = x - 1, 2, -1 do
            local j = y - (x - i)
            if j < 1 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end

        -- Check valid moves in the top right direction
        for i = x - 1, 2, -1 do
            local j = y + (x - i)
            if j > 9 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end

        -- Check valid moves in the bottom left direction
        for i = x + 1, 9 do
            local j = y - (i - x)
            if j < 1 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end

        -- Check valid moves in the bottom right direction
        for i = x + 1, 9 do
            local j = y + (i - x)
            if j > 9 then
                break
            end

            table.insert(possibleMoves, { i, j })
            if self.board[i][j] ~= " " then
                break
            end
        end
    elseif piece == "K" or piece == "k" then -- King
        -- Calculate possible moves for a king
        local kingMoves = {
            { x - 1, y - 1 }, { x - 1, y }, { x - 1, y + 1 },
            { x,     y - 1 }, { x, y + 1 },
            { x + 1, y - 1 }, { x + 1, y }, { x + 1, y + 1 }
        }

        for _, move in ipairs(kingMoves) do
            local i, j = move[1], move[2]
            if i >= 2 and i <= 9 and j >= 2 and j <= 9 then
                table.insert(possibleMoves, { i, j })
            end
        end
    end

    return possibleMoves
end

function Board:drawBoard()
    for i = 1, self.width do
        for j = 1, self.height do
            local x = (i - 1) * self.cell.width
            local y = (j - 1) * self.cell.height
            local color = self.colors.white
            if (i + j) % 2 == 0 then
                color = self.colors.black
            end
            love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255)
            love.graphics.rectangle(
                "fill",
                x, y,
                self.cell.width,
                self.cell.height
            )
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Board:drawHighlighted()
    love.graphics.setColor(0, 0, 0, 0.1)

    for _, move in ipairs(self.highlightedSquares) do
        local x = (move[2] - 1) * self.cell.width
        local y = (move[1] - 1) * self.cell.height

        -- If there is a piece in the cell, and it is in the same team, don't highlight it
        if self.board[move[1]][move[2]] ~= " " and self.board[move[1]][move[2]] and (
                (self.turn == "w" and self.board[move[1]][move[2]] == string.upper(self.board[move[1]][move[2]])) or
                (self.turn == "b" and self.board[move[1]][move[2]] == string.lower(self.board[move[1]][move[2]]))) then
            goto continue
        end

        -- If there is a piece in the cell, draw a hollow circle around it
        if self.board[move[1]][move[2]] ~= " " then
            -- Make it thicker
            love.graphics.setLineWidth(5)
            love.graphics.circle(
                "line",
                x + self.cell.width / 2,
                y + self.cell.height / 2,
                self.cell.width / 2.5
            )
            love.graphics.setLineWidth(1)
        else
            -- Draw a gray transparent circle in the center of the cell
            love.graphics.circle(
                "fill",
                x + self.cell.width / 2,
                y + self.cell.height / 2,
                self.cell.width / 6
            )
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1)
end

function Board:drawPieces()
    for i = 1, self.width do
        for j = 1, self.height do
            local x = (i - 1) * self.cell.width
            local y = (j - 1) * self.cell.height
            local piece = self.board[j][i]
            if piece ~= " " then
                -- Draw the piece centralised in the cell (horizontally)
                local piece_x = x + (self.cell.width - self.pieces.width * self.pieces.scale) / 2
                local piece_y = y + (self.cell.height - self.pieces.height * self.pieces.scale) / 2

                love.graphics.draw(
                    self.pieces.image,
                    self.pieces.sprites[piece],
                    piece_x, piece_y,
                    0,
                    self.pieces.scale,
                    self.pieces.scale
                )
            end
        end
    end
end

function Board:drawGoal()
    love.graphics.setColor(1, 0, 0)

    -- Black's goal
    love.graphics.line(
        0, self.cell.height,
        self.width * self.cell.width,
        self.cell.height
    )

    -- White's goal
    love.graphics.line(
        0, (self.height - 1) * self.cell.height,
        self.width * self.cell.width,
        (self.height - 1) * self.cell.height
    )

    love.graphics.setColor(1, 1, 1)
end

function Board:draw()
    -- Draw the 8x8 board
    self:drawBoard()

    -- Draw the pieces
    self:drawPieces()

    -- Draw highlightedSquares
    self:drawHighlighted()

    -- Draw goal lines
    self:drawGoal()
end

return Board
