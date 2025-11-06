--[[

Game made for our CTE Task.

Made by:
Aayush
Shaunak
Nikhil

]]

local gameInfo = { -- Stores all the memory and information for the game.
    Background = { Image = nil, Scale = 1, Width = 0, X = 0 },

    StaticImages = {},
    Obstacles = {}, -- Table which will store all the obstacles.
    ObstacleImages = {},
    ObstacleSpawnTimer = 0, -- Interval for obstacle spawn rate.

    GarbageTruckImage = nil,

    ObstacleConfig = { -- All settings for obstacles.
        Scale = 0.25,
        HitboxScale = 0.5,
        YRange = { min = 300, max = 400 },
        BaseSpeed = 400,
        SpinSpeedRange = { min = 120, max = 240 },
        Count = 1,
    },

    PlayerConfig = { -- All Settings for player objects.
        BaseAnimationSpeed = 0.15,
        MovementRange = { minX = 100, maxX = 700 },
        Hitbox = { wScale = 0.6, hScale = 0.7 },
        GroundY = 450,
        JumpForce = -700,
        Gravity = 1000,
        Speed = 300,
    },

    PlayerInfo = { -- All player information including keybinds, position and velocity.
        [1] = { Keybinds = { Jump = "w", Left = "a", Right = "d" }, ImgID = "assets/player1.png", Image = nil, Quads = {},
            Position = { x = 175, y = 450 }, StartingPosition = { x = 175, y = 450 },
            Dead = false, Velocity = { x = 0, y = 0 }, IsJumping = false,
            CurrentFrame = 1, AnimationTimer = 0
        },

        [2] = { Keybinds = { Jump = "up", Left = "left", Right = "right" }, FormattedKeybings = { Jump = "Up Arrow", Left = "Left Arrow", Right = "Right Arrow" }, ImgID = "assets/player2.png", Image = nil, Quads = {},
            Position = { x = 350, y = 450 }, StartingPosition = { x = 350, y = 450 },
            Dead = false, Velocity = { x = 0, y = 0 }, IsJumping = false,
            CurrentFrame = 1, AnimationTimer = 0
        },

        [3] = { Keybinds = { Jump = "i", Left = "j", Right = "l" }, ImgID = "assets/player3.png", Image = nil, Quads = {},
            Position = { x = 525, y = 450 }, StartingPosition = { x = 525, y = 450 },
            Dead = false, Velocity = { x = 0, y = 0 }, IsJumping = false,
            CurrentFrame = 1, AnimationTimer = 0
        },

        [4] = { Keybinds = { Jump = "kp8", Left = "kp4", Right = "kp6" }, FormattedKeybings = { Jump = "Keypad 8", Left = "Keypad 4", Right = "Keypad 6" }, ImgID = "assets/player4.png", Image = nil, Quads = {},
            Position = { x = 700, y = 450 }, StartingPosition = { x = 700, y = 450 },
            Dead = false, Velocity = { x = 0, y = 0 }, IsJumping = false,
            CurrentFrame = 1, AnimationTimer = 0
        }
    },

    PlayersPlaying = {}, -- Stores all the current players playing
    LastPlayerCount = 0,
    WorldScrollSpeed = 300,

    Score = 0,
    ScoreRate = 10,

    Difficulty = {
        Sections = { -- All difficulty data.
            { name = "Easy", speed = 300, obstacleSpeed = 400, spawnDelay = 2.0, spinMultiplier = 1.2, count = 1, img = "assets/Easy.png" },
            { name = "Medium", speed = 400, obstacleSpeed = 500, spawnDelay = 1.5, spinMultiplier = 1.5, count = 1.1, img = "assets/Medium.png" },
            { name = "Hard", speed = 500, obstacleSpeed = 650, spawnDelay = 1.2, spinMultiplier = 2.0, count = 1.25, img = "assets/Hard.png" },
            { name = "Extreme", speed = 600, obstacleSpeed = 800, spawnDelay = 1.0, spinMultiplier = 2.5, count = 1.5, img = "assets/Extreme.png" },
        },
        CurrentIndex = 1,
        Timer = 0,
        TransitionDuration = 3,
        TransitionProgress = 0,
        NextSection = nil,
        ImageObjects = {},
    },

    CurrentDifficultyName = "",
    UIFont = love.graphics.newFont("assets/Arial-Bold.ttf", 20), -- The font some parts of the game will use.

    GameState = "menu",
    MenuBgSpeed = 60,
    MenuButtons = { -- All the information regarding buttons on the menu.
        { text = "Start", action = "start", x = 850 - 150, y = 275, width = 300, height = 80 },
        { text = "Controls", action = "controls", x = 850 - 150, y = 375, width = 300, height = 80 }
    },
    MenuLogo = nil,

    PlayerSelectButtons = { -- All the information regarding buttons on the player-select menu.
        { text = "1 Player", players = 1, x = 650, y = 100, width = 400, height = 70 },
        { text = "2 Players", players = 2, x = 650, y = 190, width = 400, height = 70 },
        { text = "3 Players", players = 3, x = 650, y = 280, width = 400, height = 70 },
        { text = "4 Players", players = 4, x = 650, y = 370, width = 400, height = 70 },
    },

    GameOverButtons = { -- All the information regarding buttons on the game over screen.
        { text = "Play Again", action = "play_again", x = 650, y = 350, width = 400, height = 80 },
        { text = "Main Menu", action = "menu", x = 650, y = 450, width = 400, height = 80 },
    },

    GameOverLogo = nil,
    ControlsBackButton = { text = "Back", x = 850 - 100, y = 500, width = 200, height = 70 }, -- The back button which returns the player back to the menu.
}

local function CreatePlayerImage(idx)
    --[[
    This function will take in a number and will generate all the player information and images for it.

    The Quads table stores all the animations for the player, it is the machine's job to iterate through them to illustrate player movement.
    ]]

    local data = gameInfo.PlayerInfo[idx]
    if not data then return end
    data.Quads = {}
    data.Dead = false
    local success, sheet = pcall(function() return love.graphics.newImage(data.ImgID) end) -- Pcall ensures that if an error occurs, the entire code will not stop running.
    if success and sheet then
        data.Image = sheet
        local sheetWidth, sheetHeight = sheet:getDimensions()
        local frameWidth, frameHeight = sheetWidth / 4, sheetHeight / 4

        -- The 'sheet' is in a grid pattern.
        for i = 0, 3 do
            data.Quads[i + 1] = love.graphics.newQuad(i * frameWidth, 1 * frameHeight + 10,
                frameWidth, frameHeight + 8, sheetWidth, sheetHeight)
        end
        data.Position = { x = data.StartingPosition.x, y = data.StartingPosition.y }
    end
end

-- Function to reset all the game data, this function is usually called at the start and end of a game.
local function ResetGame()
    gameInfo.Obstacles = {}
    gameInfo.ObstacleSpawnTimer = 0
    gameInfo.Score = 0
    gameInfo.Difficulty.CurrentIndex = 1
    gameInfo.Difficulty.Timer = 0
    gameInfo.Difficulty.NextSection = nil
    gameInfo.Difficulty.TransitionProgress = 0
    gameInfo.CurrentDifficultyName = ""
    for _, idx in ipairs(gameInfo.PlayersPlaying) do
        local p = gameInfo.PlayerInfo[idx]
        p.Position = { x = p.StartingPosition.x, y = p.StartingPosition.y }
        p.Velocity = { x = 0, y = 0 }
        p.IsJumping = false
        p.Dead = false
    end
end

-- Adds an obstacle into memory, doesn't actually handle the visuals.
local function SpawnObstacle()
    local config = gameInfo.ObstacleConfig
    local section = gameInfo.Difficulty.Sections[gameInfo.Difficulty.CurrentIndex]
    for i = 1, section.count do
        local y = math.random(config.YRange.min, config.YRange.max)
        --local img = gameInfo.ObstacleImage
        local img = gameInfo.ObstacleImages[math.random(1, #gameInfo.ObstacleImages)] -- Randomly select an image from the table.

        local w, h = img:getWidth() * config.Scale, img:getHeight() * config.Scale
        table.insert(gameInfo.Obstacles, { 
            image = img,
            x = 1700 + math.random(50, 300),
            y = y,
            width = w,
            height = h,
            speed = section.obstacleSpeed * (0.9 + math.random() * 0.2),
            rotation = 0,
            rotationSpeed = math.rad(math.random(config.SpinSpeedRange.min, config.SpinSpeedRange.max) * section.spinMultiplier)
        })
    end
end

--[[
The intial load when the game is booted up.

Sets the screen size, and intitialises certain images.
]]
function love.load()
    love.window.setMode(1700, 600, { resizable = false })
    love.graphics.setBackgroundColor(0.8, 0.9, 1)

    local bgImage = love.graphics.newImage("assets/Background.png")
    gameInfo.Background.Image = bgImage

    local w, h = love.graphics.getDimensions()
    local bw, bh = bgImage:getDimensions()

    gameInfo.Background.Scale = h / bh
    gameInfo.Background.Width = bw * gameInfo.Background.Scale

    --gameInfo.ObstacleImage = love.graphics.newImage("GarbageBag.png")
    table.insert(gameInfo.ObstacleImages, love.graphics.newImage("assets/GarbageBag.png"))
    table.insert(gameInfo.ObstacleImages, love.graphics.newImage("assets/BananaPeel.png"))
    table.insert(gameInfo.ObstacleImages, love.graphics.newImage("assets/GarbageCan.png"))

    gameInfo.GarbageTruckImage = love.graphics.newImage("assets/GarbageTruck.png")
    gameInfo.GameOverLogo = love.graphics.newImage("assets/GameOver.png")

    for _, sec in ipairs(gameInfo.Difficulty.Sections) do
        local success, img = pcall(function() return love.graphics.newImage(sec.img) end)
        if success then gameInfo.Difficulty.ImageObjects[sec.name] = img end
    end

    gameInfo.HighScore = 0
    gameInfo.MenuLogo = love.graphics.newImage("assets/GoOnARun.png")
end

--[[

This function will run every frame and will update the game's memory and state depending on current actions.

dt stands for Delta Time, a specific variable that represents the time interval in seconds it took from the last frame to the current frame.

]]
function love.update(dt)
    -- Updates the background depending on the GameState.
    if gameInfo.GameState == "menu" or gameInfo.GameState == "select_players" or gameInfo.GameState == "gameover" or gameInfo.GameState == "controls" then
        gameInfo.Background.X = gameInfo.Background.X - gameInfo.MenuBgSpeed * dt
        if gameInfo.Background.X <= -gameInfo.Background.Width then
            gameInfo.Background.X = gameInfo.Background.X + gameInfo.Background.Width
        end
        return
    end

    -- Existing gameplay update logic.
    local difficulty = gameInfo.Difficulty
    local currentSection = difficulty.Sections[difficulty.CurrentIndex]
    difficulty.Timer = difficulty.Timer + dt
    local nextIndex = difficulty.CurrentIndex + 1
    local nextSection = difficulty.Sections[nextIndex]

    if nextSection and difficulty.Timer >= 20 then
        difficulty.Timer = 0
        difficulty.NextSection = nextSection
        difficulty.TransitionProgress = 0
    end

    if difficulty.NextSection then
        difficulty.TransitionProgress = difficulty.TransitionProgress + dt / difficulty.TransitionDuration
        local t = math.min(difficulty.TransitionProgress, 1)
        gameInfo.WorldScrollSpeed = currentSection.speed * (1 - t) + nextSection.speed * t
        gameInfo.ObstacleConfig.Speed = currentSection.obstacleSpeed * (1 - t) + nextSection.obstacleSpeed * t
        gameInfo.ObstacleConfig.Count = math.floor(currentSection.count * (1 - t) + nextSection.count * t)
        if t >= 1 then
            difficulty.CurrentIndex = nextIndex
            difficulty.NextSection = nil
        end
    else
        gameInfo.WorldScrollSpeed = currentSection.speed
        gameInfo.ObstacleConfig.Speed = currentSection.obstacleSpeed
        gameInfo.ObstacleConfig.Count = currentSection.count
    end

    gameInfo.CurrentDifficultyName = currentSection.name
    for _, playerIdx in ipairs(gameInfo.PlayersPlaying) do
        local player = gameInfo.PlayerInfo[playerIdx]
        if player and not player.Dead then
            gameInfo.Score = gameInfo.Score + gameInfo.ScoreRate * dt / #gameInfo.PlayersPlaying
        end
    end

    gameInfo.Background.X = gameInfo.Background.X - gameInfo.WorldScrollSpeed * dt
    if gameInfo.Background.X <= -gameInfo.Background.Width then
        gameInfo.Background.X = gameInfo.Background.X + gameInfo.Background.Width
    end

    gameInfo.ObstacleSpawnTimer = gameInfo.ObstacleSpawnTimer + dt
    if gameInfo.ObstacleSpawnTimer >= currentSection.spawnDelay then -- Checks the obstacle interval and depending on whether it has passed it or not, will call a function to spawn an obstacle
        gameInfo.ObstacleSpawnTimer = 0
        SpawnObstacle()
    end

    -- Rotates all the obstacles depending on their rotation speed and current delta time.
    for i = #gameInfo.Obstacles, 1, -1 do
        local obs = gameInfo.Obstacles[i]
        obs.x = obs.x - obs.speed * dt
        obs.rotation = obs.rotation + obs.rotationSpeed * dt
        if obs.x + obs.width < 0 then table.remove(gameInfo.Obstacles, i) end
    end

    -- Listens to player movement and acts depending on keybinds and player state.
    local aliveCount = 0
    for _, playerIdx in ipairs(gameInfo.PlayersPlaying) do
        local player = gameInfo.PlayerInfo[playerIdx]

        if player and not player.Dead then
            aliveCount = aliveCount + 1
            if player.IsJumping then
                player.Velocity.y = player.Velocity.y + gameInfo.PlayerConfig.Gravity * dt
                player.Position.y = player.Position.y + player.Velocity.y * dt
                if player.Position.y >= gameInfo.PlayerConfig.GroundY then
                    player.Position.y = gameInfo.PlayerConfig.GroundY
                    player.Velocity.y = 0
                    player.IsJumping = false
                end
            end

            local moveInput = 0
            if love.keyboard.isDown(player.Keybinds.Left) then moveInput = moveInput - 1 end
            if love.keyboard.isDown(player.Keybinds.Right) then moveInput = moveInput + 1 end

            player.Velocity.x = moveInput * gameInfo.PlayerConfig.Speed
            player.Position.x = math.max(gameInfo.PlayerConfig.MovementRange.minX, math.min(player.Position.x + player.Velocity.x * dt, gameInfo.PlayerConfig.MovementRange.maxX))
            player.AnimationTimer = player.AnimationTimer + dt

            if player.AnimationTimer >= gameInfo.PlayerConfig.BaseAnimationSpeed then
                player.CurrentFrame = player.CurrentFrame + 1
                if player.CurrentFrame > #player.Quads then player.CurrentFrame = 1 end
                player.AnimationTimer = 0
            end

            local _, _, fw, fh = player.Quads[player.CurrentFrame]:getViewport()
            local px, py = player.Position.x - fw / 2, player.Position.y - fh / 2
            local hitW, hitH = fw * gameInfo.PlayerConfig.Hitbox.wScale, fh * gameInfo.PlayerConfig.Hitbox.hScale
            local hitX, hitY = px + (fw - hitW)/2, py + (fh - hitH)/2

            for _, obs in ipairs(gameInfo.Obstacles) do
                local oW = obs.width * gameInfo.ObstacleConfig.HitboxScale
                local oH = obs.height * gameInfo.ObstacleConfig.HitboxScale
                local oX = obs.x + (obs.width - oW)/2
                local oY = obs.y + (obs.height - oH)/2
                if hitX < oX + oW and hitX + hitW > oX and hitY < oY + oH and hitY + hitH > oY then -- This line checks if a player is touching the obstacle's hitbox, and will set the player as dead if they are.
                    player.Dead = true
                end
            end
        end
    end

    -- Checks if there are no players alive and if there aren't, it will finish the game.
    if aliveCount == 0 and gameInfo.GameState == "playing" then
        gameInfo.GameState = "gameover"

        if gameInfo.HighScore < gameInfo.Score then
            gameInfo.HighScore = gameInfo.Score            
        end
    end
end

-- Listens to if the mouse is pressed, and if the mouse is over a button's area it will change the game's state.
function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    if gameInfo.GameState == "menu" then
        for _, btn in ipairs(gameInfo.MenuButtons) do
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                if btn.action == "start" then
                    gameInfo.GameState = "select_players"
                elseif btn.action == "controls" then
                    gameInfo.GameState = "controls"
                end
            end
        end

    elseif gameInfo.GameState == "controls" then
        local b = gameInfo.ControlsBackButton
        if x >= b.x and x <= b.x + b.width and y >= b.y and y <= b.y + b.height then
            gameInfo.GameState = "menu"
        end

    elseif gameInfo.GameState == "select_players" then
        local b = gameInfo.ControlsBackButton
        if x >= b.x and x <= b.x + b.width and y >= b.y and y <= b.y + b.height then
            gameInfo.GameState = "menu"
        end

        for _, btn in ipairs(gameInfo.PlayerSelectButtons) do
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                gameInfo.PlayersPlaying = {}
                for i = 1, btn.players do
                    table.insert(gameInfo.PlayersPlaying, i)
                    CreatePlayerImage(i)
                end
                gameInfo.LastPlayerCount = btn.players
                ResetGame()
                gameInfo.GameState = "playing"
            end
        end

    elseif gameInfo.GameState == "gameover" then
        for _, btn in ipairs(gameInfo.GameOverButtons) do
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                if btn.action == "play_again" then
                    gameInfo.PlayersPlaying = {}

                    for i = 1, gameInfo.LastPlayerCount do
                        table.insert(gameInfo.PlayersPlaying, i)
                        CreatePlayerImage(i)
                    end

                    ResetGame()
                    gameInfo.GameState = "playing"

                elseif btn.action == "menu" then
                    gameInfo.GameState = "menu"
                end
            end
        end
    end
end

function love.keypressed(key) -- Listens to if any jump keys were pressed.
    for _, playerIdx in ipairs(gameInfo.PlayersPlaying) do
        local player = gameInfo.PlayerInfo[playerIdx]
        if player and not player.Dead and key == player.Keybinds.Jump and not player.IsJumping then
            player.Velocity.y = gameInfo.PlayerConfig.JumpForce
            player.IsJumping = true
        end
    end
end

--[[

Similar to love.update, except instead of editing memory, it will read it and draw visuals depending on what is being stored.
This function also runs every frame.

]]
function love.draw()
    local bg = gameInfo.Background
    love.graphics.draw(bg.Image, bg.X, 0, 0, bg.Scale, bg.Scale)
    love.graphics.draw(bg.Image, bg.X + bg.Width, 0, 0, bg.Scale, bg.Scale)

    -- This section of the code checks the game's state and will show data depending on which page is open at the moment.
    if gameInfo.GameState == "menu" then
        local scale = 0.35
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", 0, 0, 1700, 600)

        love.graphics.setColor(1, 1, 1)
        local scale = 0.35
        love.graphics.draw(gameInfo.MenuLogo, 850 - (gameInfo.MenuLogo:getWidth() * scale) / 2, 60, 0, scale, scale)
        love.graphics.setFont(love.graphics.newFont(25))

        love.graphics.printf("A Computing Technology Assignment", 0, 540, 1700, "center")

        love.graphics.setFont(love.graphics.newFont(36))
        for _, btn in ipairs(gameInfo.MenuButtons) do
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 10, 10)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + 20, btn.width, "center")
        end

        return

    elseif gameInfo.GameState == "select_players" then
        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", 0, 0, 1700, 600)

        love.graphics.setFont(love.graphics.newFont(34))
        for _, btn in ipairs(gameInfo.PlayerSelectButtons) do
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 12, 12)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + 20, btn.width, "center")
        end

        love.graphics.setFont(love.graphics.newFont(26))
        local b = gameInfo.ControlsBackButton
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 10, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(b.text, b.x, b.y + 20, b.width, "center")

        return
    elseif gameInfo.GameState == "gameover" then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, 1700, 600)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(60))

        local logo = gameInfo.GameOverLogo
        if logo then
            local winWidth = love.graphics.getWidth()
            local imgWidth = logo:getWidth() * 0.2 
            local x = (winWidth - imgWidth) / 2
            love.graphics.draw(logo, x, 60, 0, 0.2, 0.2)
        else
            love.graphics.printf("GAME OVER", 0, 100, 1700, "center")
        end

        love.graphics.setFont(love.graphics.newFont(36))
        for _, btn in ipairs(gameInfo.GameOverButtons) do
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 12, 12)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + 20, btn.width, "center")
        end

        love.graphics.printf("Score: " .. math.floor(gameInfo.Score), 0, 180, 1700, "center")
        love.graphics.printf("High Score: " .. math.floor(gameInfo.HighScore), 0, 250, 1700, "center")

        return
    elseif gameInfo.GameState == "controls" then
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", 0, 0, 1700, 600)

        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Player Controls", 0, 80, 1700, "center")

        love.graphics.setFont(love.graphics.newFont(26))
        local startY = 160
        for i = 1, 4 do
            local p = gameInfo.PlayerInfo[i]
            local y = startY + (i - 1) * 80

            local keybindsTable = p.FormattedKeybings or p.Keybinds

            love.graphics.printf(string.format("Player %d:  Jump: %s   Left: %s   Right: %s", i, keybindsTable.Jump, keybindsTable.Left, keybindsTable.Right),
                0, y, 1700, "center")
        end

        local b = gameInfo.ControlsBackButton
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 10, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(b.text, b.x, b.y + 20, b.width, "center")
        return
    end

    -- Everything under this comment is used to draw gameplay.
    local config = gameInfo.ObstacleConfig
    for _, obs in ipairs(gameInfo.Obstacles) do
        local ox, oy = obs.width / 2, obs.height / 2
        love.graphics.draw(obs.image, obs.x + ox, obs.y + oy, -obs.rotation, config.Scale, config.Scale,
            gameInfo.ObstacleImages[1]:getWidth() / 2, gameInfo.ObstacleImages[1]:getHeight() / 2)
    end

    -- This loop will draw the player and will check extra information (if they are dead or not).
    for _, playerIdx in ipairs(gameInfo.PlayersPlaying) do
        local player = gameInfo.PlayerInfo[playerIdx]
        if player and player.Image and player.Quads[player.CurrentFrame] then
            love.graphics.setColor(player.Dead and {1, 0.4, 0.4} or {1, 1, 1})
            local _, _, fw, fh = player.Quads[player.CurrentFrame]:getViewport()

            love.graphics.draw(
                player.Image,
                player.IsJumping and player.Quads[2] or player.Quads[player.CurrentFrame],
                player.Position.x,
                player.Position.y,
                0,
                1,
                1,
               fw / 2,
               fh / 2
            )

            -- Draw player label above their head.
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(22))
            love.graphics.printf(
                "Player " .. playerIdx,
                player.Position.x - 50,
                player.Position.y - fh / 1.5,
                100,
                "center"
            )
            love.graphics.setColor(1, 1, 1)
        end
    end

    love.graphics.setFont(gameInfo.UIFont)
    love.graphics.setColor(1, 1, 1)
    local w, h = love.graphics.getDimensions()

    -- Bottom left text such as the score.
    love.graphics.print("High Score: " .. math.floor(gameInfo.HighScore), 20, h - 90)
    love.graphics.print("Score: " .. math.floor(gameInfo.Score), 20, h - 60)
    love.graphics.print("Time in section: " .. math.floor(gameInfo.Difficulty.Timer) .. "s", 20, h - 30)
    local sectionImg = gameInfo.Difficulty.ImageObjects[gameInfo.CurrentDifficultyName]
    if sectionImg then 
        love.graphics.setColor(1, 1, 1, 1) 
        local scale = 1.2 
        love.graphics.draw(sectionImg, 850 - (sectionImg:getWidth() * scale) / 2, 10, 0, scale, scale) 
    end 
end
