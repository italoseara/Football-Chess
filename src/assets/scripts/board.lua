local Class = require "libs.classic"

local Board = Class:extend()

function Board:new()
    self.width = Config.board.width
    self.height = Config.board.height

    self.pieces = {}

    -- Castling
    self.pieces.castling = {
        w = {
            king = true,
            leftRook = true,
            rightRook = true,
        },
        b = {
            king = true,
            leftRook = true,
            rightRook = true,
        }
    }

    -- Load the image with all the pieces
    self.pieces.image = love.graphics.newImage("assets/images/neo.png")

    -- Calculate the width and height of each piece
    self.pieces.width = self.pieces.image:getWidth() / 6
    self.pieces.height = self.pieces.image:getHeight() / 2

    -- Calculate the scale factor to fit the piece inside the cell
    self.pieces.scale = math.min(
        Config.board.cell.width / self.pieces.width,
        Config.board.cell.height / self.pieces.height
    )

    -- Load the sprites for each piece
    local images = { white = {}, black = {} }

    for i = 1, 6 do
        images.white[i] = love.graphics.newQuad(
            (i - 1) * self.pieces.width,
            0,
            self.pieces.width,
            self.pieces.height,
            self.pieces.image:getDimensions()
        )
    end

    for i = 1, 6 do
        images.black[i] = love.graphics.newQuad(
            (i - 1) * self.pieces.width,
            self.pieces.height,
            self.pieces.width,
            self.pieces.height,
            self.pieces.image:getDimensions()
        )
    end

    -- Create the sprites for each piece
    self.pieces.sprites = {
        -- White pieces
        K = images.white[1],
        Q = images.white[2],
        B = images.white[3],
        N = images.white[4],
        R = images.white[5],
        P = images.white[6],

        -- Black pieces
        k = images.black[1],
        q = images.black[2],
        b = images.black[3],
        n = images.black[4],
        r = images.black[5],
        p = images.black[6],
    }

    self.ball = {
        position = { 9, 5 },
        image = love.graphics.newImage("assets/images/ball.png"),
    }
    self.ball.width = self.ball.image:getWidth()
    self.ball.height = self.ball.image:getHeight()
    self.ball.scale = math.min(
        Config.board.cell.width / self.ball.width,
        Config.board.cell.height / self.ball.height
    ) / 2

    -- Create font
    self.font = love.graphics.newFont("assets/fonts/RobotoMono-SemiBold.ttf", 18)
    self.goalFont = love.graphics.newFont("assets/fonts/RobotoMono-SemiBold.ttf", 24)

    -- Create the board
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

    -- Utility
    self.highlightedSquares = {}
    self.highlightedPiece = {}

    -- Logic
    self.turn = "w"
    self.lastMove = {
        from = {},
        to = {}
    }
end

function Board:move(x1, y1, x2, y2)
    if self.turn == "ball" then
        self.ball.position[1] = x2
        self.ball.position[2] = y2
        return
    end

    -- If the moved piece is a king:
    local piece = self.board[x1][y1]

    -- Handle castling
    if piece == "K" or piece == "k" then
        self.pieces.castling[self:getColor(piece)].king = false

        -- If the king is castling, move the rook
        if y2 - y1 == 2 then
            self:move(x2, y2 + 1, x2, y2 - 1)
        elseif y2 - y1 == -2 then
            self:move(x2, y2 - 2, x2, y2 + 1)
        end
    elseif piece == "R" or piece == "r" then
        if x1 == 1 then
            self.pieces.castling[self:getColor(piece)].leftRook = false
        elseif x1 == 8 then
            self.pieces.castling[self:getColor(piece)].rightRook = false
        end
    elseif piece == "P" then
        -- Handle promotion
        if x2 == 2 then
            self.board[x1][y1] = "Q"
        end

        -- Handle en passant
        if y2 ~= y1 and self.board[x2][y2] == " " then
            self.board[x2 + 1][y2] = " "
        end
    elseif piece == "p" then
        -- Handle promotion
        if x2 == 9 then
            self.board[x1][y1] = "q"
        end

        -- Handle en passant
        if y2 ~= y1 and self.board[x2][y2] == " " then
            self.board[x2 - 1][y2] = " "
        end
    end

    self.board[x2][y2] = self.board[x1][y1]
    self.board[x1][y1] = " "

    self.lastMove.from = { x1, y1 }
    self.lastMove.to = { x2, y2 }
    self.lastMove.piece = piece
end

function Board:gameLogic()
    local mouseX, mouseY = love.mouse.getPosition()

    if love.mouse.isDown(1) then -- Left mouse button is clicked
        -- Calculate the square coordinates based on the mouse position
        local squareY = math.floor(mouseY / Config.board.cell.height) + 1
        local squareX = math.floor(mouseX / Config.board.cell.width) + 1

        -- Check if the clicked square contains a piece
        local clickedPiece = self.board[squareY][squareX]

        if (self:isPiece(squareY, squareX) and self:getColor(clickedPiece) == self.turn) or
            (self.turn == "ball" and self:isBall(squareX, squareY)) then
            -- Calculate the possible moves for the clicked piece
            local legalMoves = self:legalMoves(squareY, squareX)

            -- Update the highlightedSquares with the possible moves
            self.highlightedSquares = legalMoves
            self.highlightedPiece = { squareX, squareY }
        else
            -- If the click square is in the highlightedSquares, move the piece
            for i, v in ipairs(self.highlightedSquares) do
                if v[1] == squareY and v[2] == squareX then
                    -- Move the piece
                    self:move(self.highlightedPiece[2], self.highlightedPiece[1], squareY, squareX)

                    -- Change the turn
                    if self:ballPossession() == self.turn then
                        self.turn = "ball"
                    elseif self.turn == "w" then
                        self.turn = "b"
                    elseif self.turn == "b" then
                        self.turn = "w"
                    elseif self.turn == "ball" then
                        if self:getColor(self.lastMove.piece) == "w" then
                            self.turn = "b"
                        else
                            self.turn = "w"
                        end
                    end
                end
            end

            -- Clear the highlightedSquares if an empty square is clicked
            self.highlightedSquares = {}
            self.highlightedPiece = {}
        end
    end
end

function Board:update(dt)
    self:gameLogic()
end

function Board:isPiece(x, y)
    return self.board[x][y] ~= " "
end

function Board:isBall(x, y)
    return self.ball.position[1] == y and self.ball.position[2] == x
end

function Board:getColor(piece)
    if string.lower(piece) == piece then
        return "b"
    else
        return "w"
    end
end

function Board:isSameColor(piece1, piece2)
    return self:getColor(piece1) == self:getColor(piece2)
end

function Board:getKingPosition(color)
    for i = 1, 8 do
        for j = 1, 8 do
            if self.board[i][j] == "K" and color == "w" then
                return i, j
            elseif self.board[i][j] == "k" and color == "b" then
                return i, j
            end
        end
    end
end

function Board:ballPossession()
    local ballX, ballY = self.ball.position[1], self.ball.position[2]

    if self:isPiece(ballX, ballY) then
        return self:getColor(self.board[ballX][ballY])
    end
    return false
end

function Board:isInCheck(x, y)
    -- Check for all the opponent's pieces possible moves
    local opponentColor
    if self.turn == "w" then
        opponentColor = "b"
    else
        opponentColor = "w"
    end

    for i = 1, 8 do
        for j = 1, 8 do
            if self:getColor(self.board[i][j]) == opponentColor then
                local legalMoves = self:legalMoves(i, j, true)

                -- Check if the king is in the opponent's possible moves
                for k, v in ipairs(legalMoves) do
                    if v[1] == x and v[2] == y then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function Board:legalMoves(x, y, flag)
    local piece = self.board[x][y]
    local legalMoves = {}

    if piece == "P" then -- White Pawn
        -- Calculate possible moves for a white pawn

        -- Check if the tile in front is empty
        if x > 2 and not self:isPiece(x - 1, y) then
            table.insert(legalMoves, { x - 1, y })
        end

        -- Check if the pawn is on its starting position and the two tiles in front are empty
        if x == 8 and not self:isPiece(x - 1, y) and not self:isPiece(x - 2, y) then
            table.insert(legalMoves, { x - 2, y })
        end

        -- Check for capturing opponent's pieces diagonally
        if y > 1 and self:isPiece(x - 1, y - 1) then
            table.insert(legalMoves, { x - 1, y - 1 })
        end
        if y < 9 and self:isPiece(x - 1, y + 1) then
            table.insert(legalMoves, { x - 1, y + 1 })
        end

        -- Check for en passant
        if self.lastMove.piece == "p" and self.lastMove.from[1] == 3 and self.lastMove.to[1] == 5 then
            if self.lastMove.to[1] == x and self.lastMove.to[2] == y - 1 then
                table.insert(legalMoves, { x - 1, y - 1 })
            elseif self.lastMove.to[1] == x and self.lastMove.to[2] == y + 1 then
                table.insert(legalMoves, { x - 1, y + 1 })
            end
        end
    elseif piece == "p" then -- Black Pawn
        -- Calculate possible moves for a black pawn
        -- Similar to the white pawn logic but with different movement direction

        -- Check if the tile in front is empty
        if x < 9 and not self:isPiece(x + 1, y) then
            table.insert(legalMoves, { x + 1, y })
        end

        -- Check if the pawn is on its starting position and the two tiles in front are empty
        if x == 3 and not self:isPiece(x + 1, y) and not self:isPiece(x + 2, y) then
            table.insert(legalMoves, { x + 2, y })
        end

        -- Check for capturing opponent's pieces diagonally
        if y > 1 and self:isPiece(x + 1, y - 1) then
            table.insert(legalMoves, { x + 1, y - 1 })
        end
        if y < 9 and self:isPiece(x + 1, y + 1) then
            table.insert(legalMoves, { x + 1, y + 1 })
        end

        -- Check for en passant
        if self.lastMove.piece == "P" and self.lastMove.from[1] == 8 and self.lastMove.to[1] == 6 then
            if self.lastMove.to[1] == x and self.lastMove.to[2] == y - 1 then
                table.insert(legalMoves, { x + 1, y - 1 })
            elseif self.lastMove.to[1] == x and self.lastMove.to[2] == y + 1 then
                table.insert(legalMoves, { x + 1, y + 1 })
            end
        end
    elseif piece == "R" or piece == "r" then -- Rook
        -- Calculate possible moves for a rook

        -- Check for possible moves in the same row
        for i = x - 1, 1, -1 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                break
            end

            table.insert(legalMoves, { i, y })
            if self:isPiece(i, y) then
                break
            end
        end

        for i = x + 1, 10 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                break
            end

            table.insert(legalMoves, { i, y })
            if self:isPiece(i, y) then
                break
            end
        end

        -- Check for possible moves in the same column
        for j = y - 1, 1, -1 do
            table.insert(legalMoves, { x, j })
            if self:isPiece(x, j) then
                break
            end
        end

        for j = y + 1, 9 do
            table.insert(legalMoves, { x, j })
            if self:isPiece(x, j) then
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
            if i >= 1 and i <= 10 and j >= 1 and j <= 8 then
                if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                    break
                end
                if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                    break
                end

                table.insert(legalMoves, { i, j })
            end
        end
    elseif piece == "B" or piece == "b" then -- Bishop
        -- Calculate possible moves for a bishop
        -- Check valid moves in the top left direction
        for i = x - 1, 1, -1 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                break
            end

            local j = y - (x - i)
            if j < 1 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
                break
            end
        end

        -- Check valid moves in the top right direction
        for i = x - 1, 1, -1 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                break
            end

            local j = y + (x - i)
            if j > 9 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
                break
            end
        end

        -- Check valid moves in the bottom left direction
        for i = x + 1, 10 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                break
            end

            local j = y - (i - x)
            if j < 1 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
                break
            end
        end

        -- Check valid moves in the bottom right direction
        for i = x + 1, 10 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                break
            end

            local j = y + (i - x)
            if j > 9 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
                break
            end
        end
    elseif piece == "Q" or piece == "q" then
        -- Check valid moves in the vertical and horizontal directions (rook-like moves)
        for i = x - 1, 1, -1 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                break
            end

            table.insert(legalMoves, { i, y })
            if self:isPiece(i, y) then
                break
            end
        end

        for i = x + 1, 10 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                break
            end

            table.insert(legalMoves, { i, y })
            if self:isPiece(i, y) then
                break
            end
        end

        for j = y - 1, 1, -1 do
            table.insert(legalMoves, { x, j })
            if self:isPiece(x, j) then
                break
            end
        end

        for j = y + 1, 9 do
            table.insert(legalMoves, { x, j })
            if self:isPiece(x, j) then
                break
            end
        end

        -- Check valid moves in the diagonal directions (bishop-like moves)
        for i = x - 1, 1, -1 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                break
            end

            local j = y - (x - i)
            if j < 1 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
                break
            end
        end

        -- Check valid moves in the top right direction
        for i = x - 1, 1, -1 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                break
            end

            local j = y + (x - i)
            if j > 9 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
                break
            end
        end

        -- Check valid moves in the bottom left direction
        for i = x + 1, 10 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                break
            end

            local j = y - (i - x)
            if j < 1 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
                break
            end
        end

        -- Check valid moves in the bottom right direction
        for i = x + 1, 10 do
            if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                break
            end

            local j = y + (i - x)
            if j > 9 then
                break
            end

            table.insert(legalMoves, { i, j })
            if self:isPiece(i, j) then
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
            if i >= 1 and i <= 10 and j >= 1 and j <= 8 then
                if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "b")) and i == 1) then
                    break
                end
                if ((self.turn ~= "ball" or (self.turn == "ball" and self:ballPossession() == "w")) and i == 10) then
                    break
                end

                -- Check if the king is not in check after the move
                if flag or not self:isInCheck(i, j) then
                    table.insert(legalMoves, { i, j })
                end
            end
        end

        -- Check if castling is possible

        -- Short castle
        if not self:isPiece(x, y + 1) and not self:isPiece(x, y + 2) and
            not self:isInCheck(x, y + 1) and not self:isInCheck(x, y + 2) then
            local rook = self.board[x][y + 3]

            if rook ~= nil and self:getColor(piece) == self:getColor(rook) and
                self.pieces.castling[self:getColor(piece)].rightRook and
                self.pieces.castling[self:getColor(piece)].king then
                table.insert(legalMoves, { x, y + 2 })
            end
        end

        -- Long castle
        if not self:isPiece(x, y - 1) and not self:isPiece(x, y - 2) and not self:isPiece(x, y - 3) and
            not self:isInCheck(x, y - 1) and not self:isInCheck(x, y - 2) then
            local rook = self.board[x][y - 4]

            if rook ~= nil and self:getColor(piece) == self:getColor(rook) and
                self.pieces.castling[self:getColor(piece)].leftRook and
                self.pieces.castling[self:getColor(piece)].king then
                table.insert(legalMoves, { x, y - 2 })
            end
        end
    end

    return legalMoves
end

function Board:drawBoard()
    -- Draw the squares
    for i = 1, self.width do
        for j = 1, self.height do
            local x = (i - 1) * Config.board.cell.width
            local y = (j - 1) * Config.board.cell.height
            local color = Config.board.color.light
            if (i + j) % 2 == 0 then
                color = Config.board.color.dark
            end
            love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255)
            love.graphics.rectangle(
                "fill",
                x, y,
                Config.board.cell.width,
                Config.board.cell.height
            )
        end
    end

    -- Draw the row labels
    for i = 2, self.height - 1 do
        local x = 0
        local y = (i - 1) * Config.board.cell.height

        local color = Config.board.color.light
        if i % 2 == 0 then
            color = Config.board.color.dark
        end
        love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255)

        local text = love.graphics.newText(self.font, tostring(self.height - i))
        love.graphics.draw(
            text,
            x - text:getWidth() + 15,
            y + 2
        )
    end

    love.graphics.setColor(1, 1, 1)

    -- Draw the column labels
    for i = 1, self.width do
        local x = (i - 1) * Config.board.cell.width
        local y = (self.height - 2) * Config.board.cell.height

        local color = Config.board.color.light
        if i % 2 == 0 then
            color = Config.board.color.dark
        end
        love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255)

        local text = love.graphics.newText(self.font, string.char(96 + i))
        love.graphics.draw(
            text,
            x + Config.board.cell.width - text:getWidth() - 2,
            y + Config.board.cell.height - text:getHeight() - 2
        )
    end

    love.graphics.setColor(1, 1, 1)
end

function Board:drawHighlighted()
    love.graphics.setColor(0, 0, 0, 0.1)

    for _, move in ipairs(self.highlightedSquares) do
        local x = (move[2] - 1) * Config.board.cell.width
        local y = (move[1] - 1) * Config.board.cell.height

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
                x + Config.board.cell.width / 2,
                y + Config.board.cell.height / 2,
                Config.board.cell.width / 2.5
            )
            love.graphics.setLineWidth(1)
        else
            -- Draw a gray transparent circle in the center of the cell
            love.graphics.circle(
                "fill",
                x + Config.board.cell.width / 2,
                y + Config.board.cell.height / 2,
                Config.board.cell.width / 6
            )
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1)
end

function Board:drawPieces()
    for i = 1, self.width do
        for j = 1, self.height do
            local x = (i - 1) * Config.board.cell.width
            local y = (j - 1) * Config.board.cell.height
            local piece = self.board[j][i]
            if piece ~= " " then
                -- Draw the piece centralised in the cell (horizontally)
                local piece_x = x + (Config.board.cell.width - self.pieces.width * self.pieces.scale) / 2
                local piece_y = y + (Config.board.cell.height - self.pieces.height * self.pieces.scale) / 2

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
    -- Draw Goal String
    local str = "GOAL"

    for i = 1, #str do
        local x = (i + 1) * Config.board.cell.width

        -- Draw the top goal
        local color1 = Config.board.color.light
        if i % 2 == 0 then
            color1 = Config.board.color.dark
        end

        love.graphics.setColor(color1[1] / 255, color1[2] / 255, color1[3] / 255)
        local text = love.graphics.newText(self.goalFont, string.sub(str, i, i))
        love.graphics.draw(
            text,
            x + Config.board.cell.width / 2 - text:getWidth() / 2,
            Config.board.cell.height / 2 - text:getHeight() / 2
        )

        -- Draw the bottom goal
        local color2 = Config.board.color.light
        if (i + 1) % 2 == 0 then
            color2 = Config.board.color.dark
        end

        love.graphics.setColor(color2[1] / 255, color2[2] / 255, color2[3] / 255)
        local text = love.graphics.newText(self.goalFont, string.sub(str, i, i))
        love.graphics.draw(
            text,
            x + Config.board.cell.width / 2 - text:getWidth() / 2,
            (self.height - 1) * Config.board.cell.height + Config.board.cell.height / 2 - text:getHeight() / 2
        )
    end

    love.graphics.setColor(1, 1, 1)
end

function Board:drawBall()
    local x = (self.ball.position[2] - 1) * Config.board.cell.width
    local y = (self.ball.position[1] - 1) * Config.board.cell.height

    love.graphics.draw(
        self.ball.image,
        x + (Config.board.cell.width - self.ball.width * self.ball.scale),
        y + (Config.board.cell.height - self.ball.height * self.ball.scale),
        0,
        self.ball.scale,
        self.ball.scale
    )
end

function Board:draw()
    -- Draw the 8x8 board
    self:drawBoard()

    -- Draw highlightedSquares
    self:drawHighlighted()

    -- Draw goal lines
    self:drawGoal()

    -- Draw the pieces
    self:drawPieces()

    -- Draw the ball
    self:drawBall()
end

return Board
