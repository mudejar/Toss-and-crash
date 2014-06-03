local storyboard = require( "storyboard" )
local physics = require("physics")
local utils = require("utils")
local scene = storyboard.newScene()
local vector = require("vector")
local fsm = require("fsm")
local perspective = require("perspective")

----------------------------------------------------------------------------------
-- 
--      NOTE:
--      
--      Code outside of listener functions (below) will only be executed once,
--      unless storyboard.removeScene() is called.
-- 
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )

    -- OBJECTS
    local camera = perspective.createView()
    local bg
    local penguin
    local woodenBlock
    local stoneBlock
    local ubuntuSign
    local microsoftPig
    local shotArrow
    local scoreText
    local pigs = {}

    -- object attributes
    local stoneDensity = 5.0
    local woodDensity = 2.0
    local vertSlabShape = {-12,-26, 12,-26, 12,26, -12,26}
    local vertPlankShape = {-6,-48, 6,-48, 6,48, -6,48}
    local horizontalPlankShape = { -100,-20, 100,-20, 100,20, -100,20 }
    local pigShape = {-12,-13, 12,-13, 12,13, -12,13}
    local health

    local microsoftPigSheets = {
        {sheet = graphics.newImageSheet("microsoft_pig_healthy.png",{width = 45, height = 42, numFrames = 1})},
        {sheet = graphics.newImageSheet("microsoft_pig_unhealthy.png", {width = 45, height = 42, numFrames = 1})}   
    }

    local microsoftPigSequence = {
        {name = "seq1", sheet = microsoftPigSheets[1].sheet, start = 1, count = 1, time = 1, loopCount = 0},
        {name = "seq2", sheet = microsoftPigSheets[2].sheet, start = 1, count = 1, time = 1, loopCount = 0}
    }

    local applePigSheets = {
        {sheet = graphics.newImageSheet("apple_pig_healthy.png", {width = 45, height = 47, numFrames = 1})},
        {sheet = graphics.newImageSheet("apple_pig_unhealthy.png", {width = 45, height = 46, numFrames = 1})}   
    }

    local applePigSheetsSequence = {
        {name = "seq1", sheet = applePigSheets[1].sheet, start = 1, count = 1, time = 1, loopCount = 0},
        {name = "seq2", sheet = applePigSheets[2].sheet, start = 1, count = 1, time = 1, loopCount = 0}
    }


    -- VARIABLES
    local pigCount
    local waitingForNewRound
    local gameLives = 4
    local restartTimer
    local canSwipe = true
    local gameScore = 0
    local swipeTween
    local birdTween
    local outOfBounds

    local group = self.view


    -- functions for forward referencing
    local destroyObject

    -- image sheet from sky bkgrnd
   local options = { width=64, height=64, 
                        numFrames=768, sheetContentWidth=2048, 
                        sheetContentHeight=1536}

    scene.skySheet = graphics.newImageSheet("swamp-background.jpg", options)
    scene.goodStartFrameForTextures = 19*32 -- four rows of 32 at bottom of image
    scene.numGoodTextureFrames = 4*32

    -- hud
    scene.hud = display.newGroup()
    group:insert(scene.hud)


    local centerX = display.contentCenterX
    local centerY = display.contentCenterY
    scene.width = display.contentWidth
    scene.height = display.contentHeight

    -- declare states here for forward referencing
    healthyState = {}
    unhealthyState = {}

    -- physics
    physics.start()
    physics.setDrawMode("normal")
    physics.setGravity(0, 11)

    -------------------
    -- healthyState
    -------------------

    function healthyState:enter ( owner )
        -- register event (table) listeners, initialize state

    end

    function healthyState:exit ( owner )
        -- unsubscribe event listeners, cleanup
    end

    function healthyState:execute ( owner )
        -- called every frame
        -- first, execute in current state
        lowHealth = function()
            owner.fsm:changeState(unhealthyState)
        end

        if owner.health < 40 then lowHealth() end
    end

    -----------------------------
    -- unhealthyState
    -----------------------------

    function unhealthyState:enter ( owner )
        --print ('sadState:enter()' .. owner.name )
        -- change to the unhealthy sprite image
        print("entering unhealthyState")
        owner:setSequence("seq2")
    end
    function unhealthyState:exit ( owner )
        --print ('sadState:exit()' .. owner.name )
        
        --return true
    end
    function unhealthyState:execute ( owner )
        --print ('sadState:execute()')
        if owner.health <= 0 then
            destroyObject(owner)
        end
    end
 

    local thickness = 10
    
    function addRect(x,y,w,h,destructable,density)
        local rect = display.newImage ( scene.skySheet, 
                scene.goodStartFrameForTextures + 
                                math.random(scene.numGoodTextureFrames)-1 )
        rect.width = w
        rect.height = h
        rect.x = x
        rect.y = y
        local denseness = density or 0.1
        scene.world:insert(rect)
        if destructable then
                physics.addBody(rect, "dynamic", {density=denseness, friction=0.5, bounce=0.5})
        else 
                physics.addBody(rect, "static", {density=denseness, friction=0.9, bounce=0.1})
        end
        rect.destructable = destructable
    end

        -- function for adding smaller vertical wooden block
    function addVertWoodenBlock(x, y)
        woodenBlock = display.newImage("vertical-wood.png", x, y, true)
        scene.world:insert(woodenBlock)
        
        physics.addBody(woodenBlock, "dynamic", {density = woodDensity, friction = 0.5, bounce = 0.5})
       
        woodenBlock.destructable = destructable
    end

    -- function for adding smaller vertical stone block
    function addVertStoneBlock(x, y)
        stoneBlock = display.newImage("vertical-stone.png", x, y, true)
        scene.world:insert(stoneBlock)
        if destructable then
            physics.addBody(stoneBlock, "dynamic", {density = stoneDensity, friction = 0.5, bounce = 0.5})
        else
            physics.addBody(stoneBlock, "static", {density = stoneDensity, friction = 0.9, bounce = 0.1})
        end
        stoneBlock.destructable = destructable
    end

    function loadExplosionData()
        local data = {}
        data.options = { width=64, height=64, numFrames=16, 
                        sheetContentWidth=256, sheetContentHeight=256}
        data.sheet = graphics.newImageSheet("explosion.png", data.options )
        data.sequenceData = {
                name="exploding",
                start=1,
                count=16,
                time=500,
                loopCount = 1,   -- Optional ; default is 0 (loop indefinitely)
                loopDirection = "forward"    -- Optional ; values include "forward" or "bounce"
            }
        return data
    end

    scene.explosionData = loadExplosionData()
    scene.explosions = {}
    
    -------------------------------------------------
    -- START NEW ROUND
    -------------------------------------------------

    local newRound = function()
        local activateRound = function()

            canSwipe = true
            waitingForNewRound = false

            if restartTimer then
                timer.cancel(restartTimer)
            end


            function BirdLoaded()
                gameIsActive = true
                penguin.inAir = false
                penguin.isHit = false
            end
        end
    end


    -------------------------------------------------
    -- GAME OVER
    -------------------------------------------------

    local gameOver = function(outcome)
        local outcome = outcome

        gameIsActive = false
        physics.pause()

        -- game over window
        self.buttons = display.newGroup()
        group:insert(self.buttons)

        if outcome == "yes" then
            --[[outcomeResult = display.newImageRect("youwin.jpg", display.contentWidth, display.contentHeight)
            outcomeResult.x = display.contentCenterX
            outcomeResult.y = display.contentCenterY
            physics.pause()

            function outcomeResult:touch(event)
                if event.phase == "began" then
                    print("trying to go to the next scene")
                    scene.gotoScene("startmenu")
                    return true
                end
            end

            outcomeResult:addEventListener("touch", outcomeResult)--]]


            --[[self.menuButton = utils.makeButtonToScene("main",
            "next-level.jpg", self.buttons, 
            display.contentCenterX,
            display.contentCenterY)
            self.menuButton.start()--]]
            storyboard.gotoScene("startmenu")
        else
            self.menuButton = utils.makeButtonToScene("startmenu",
            "youlose.png", self.buttons, 
            display.contentCenterX,
            display.contentCenterY)
            --self.menuButton.start()
        end

    end

        

-------------------------------------------------
-- LEVEL
-------------------------------------------------

    local createLevel = function()

        -- bad guys
        pigCount = 2
        microsoftPig = display.newSprite(microsoftPigSheets[1].sheet, microsoftPigSequence)
        microsoftPig.fsm = fsm.new(microsoftPig)
        microsoftPig.fsm:changeState(healthyState)
        microsoftPig.x = 720; microsoftPig.y = 450
        microsoftPig.myName = "pig"
        microsoftPig.isHit = false
        microsoftPig.health = 100

        table.insert(pigs, microsoftPig)

        physics.addBody(microsoftPig, "dynamic", {density=1.0, bounce=0, friction=0.5, shape=pigShape})
        scene.world:insert(microsoftPig)

        microsoftPig:addEventListener("scene.onCollision", microsoftPig)

        applePig = display.newSprite(applePigSheets[1].sheet, applePigSheetsSequence)
        applePig.fsm = fsm.new(applePig)
        applePig.fsm:changeState(healthyState)
        applePig.x = 850; applePig.y = 450
        applePig.myName = "pig"
        applePig.isHit = false
        applePig.health = 100

        table.insert(pigs, applePig)

        physics.addBody(applePig, "dynamic", {density=1.0, bounce=0, friction=0.5, shape=pigShape})
        scene.world:insert(applePig)

        applePig:addEventListener("scene.onCollision", applePig)

        -- object attributes
        local stoneDensity = 5.0
        local woodDensity = 2.0
        local vertSlabShape = {-12,-26, 12,-26, 12,26, -12,26}
        local vertPlankShape = {-6,-48, 6,-48, 6,48, -6,48}

        -- first vertical slab
        local vertSlab1 = display.newImageRect("vertical-stone.png", 28, 58)
        vertSlab1.x = 720; vertSlab1.y = 570
        vertSlab1.myName = "stone"

        physics.addBody(vertSlab1, "dynamic", {density = stoneDensity, bounce = 0, friction = 0.5, shape = vertSlabShape})
        scene.world:insert(vertSlab1) 

        -- second vertical slab
        local vertSlab2 = display.newImageRect("vertical-stone.png", 28, 58)
        vertSlab2.x = 900; vertSlab2.y = 570
        vertSlab2.myName = "stone"

        physics.addBody(vertSlab2, "dynamic", {density = stoneDensity, bounce = 0, friction = 0.5, shape = vertSlabShape})
        scene.world:insert(vertSlab2) 

        -- first vertical plank
        --[[local vertPlank1 = display.newImageRect("vertical-wood.png", 14, 98)
        vertPlank1.x = 160; vertPlank1.y = 570
        vertPlank1.myName = "wood"
        vertPlank1.destructable = true
        physics.addBody(vertPlank1, "dynamic", {density = woodDensity, bounce = 0, friction = 0.5, shape = vertPlankShape})

        scene.world:insert(vertPlank1)--]]

        -- first horizontal plank
        local horizontalPlank = display.newImageRect("horizontal-wood@2x.png", 200, 35)
        horizontalPlank.x = 800; horizontalPlank.y = 520
        horizontalPlank.myName = "wood"
        horizontalPlank.destructable = true
        physics.addBody(horizontalPlank, "dynamic", {density = woodDensity, bounce = 0, friction = 0.5, shape = horizontalPlankShape})

        scene.world:insert(horizontalPlank)
    end

-------------------------------------------------
-- PLAYER
-------------------------------------------------

    function loadBird(x, y)
        local options =
            {
                -- The params below are required
                width = 41,
                height = 42,
                numFrames = 64,
                -- The params below are optional; used for dynamic resolution support
            }

        local imageSheet = graphics.newImageSheet( "Fother-penguin.png", options )

        local sequenceData =
            {
                name="turning",
                start=1,
                count=64,
                time=8000,
                loopCount = 0,   -- Optional ; default is 0 (loop indefinitely)
                loopDirection = "forward"    -- Optional ; values include "forward" or "bounce"
            }

        penguin = display.newSprite(imageSheet, sequenceData)
        penguin.name = "linus"
        penguin.fsm = fsm.new(penguin)
        penguin.x = x
        penguin.y = y
        penguin.fsm:changeState(healthyState)
        penguin.isBullet = true -- for collision detection
        penguin.radius = 12

        penguin.isReady = false --> Not "flingable" until touched.
        penguin.inAir = false
        penguin.isHit = false
        penguin.trailNum = 0
        penguin.isInBounds = true

        
        penguinAttributes = {
            density = 40.0,
            bounce = 0.4,
            friction = 0.15,
            radius = penguin.radius
        }
        physics.addBody(penguin, "static", penguinAttributes)

        scene.player = penguin
        scene.player:play()
        scene.world:insert(scene.player)

        return scene.player

    end

    -------------------------------------------------
    -- AUDIO 
    -------------------------------------------------

    local touchSound = audio.loadSound("borp.wav")
    local explosionSound = audio.loadSound("explosion.wav")
    audio.setVolume(0.05)


-------------------------------------------------
-- EXPLOSION
-------------------------------------------------
    --scene.explosion = loadExplosion()
    --scene.explosion:pause()
    --scene.explosion:setFrame(16)
    --scene.world:insert(scene.explosion)
    local explode = function(obj)
        -- start up a an explosion at the obj's position
        
        local ex = display.newSprite( scene.explosionData.sheet, scene.explosionData.sequenceData )
        ex.x = obj.x
        ex.y = obj.y
        ex:rotate(math.random(360))
        ex:pause()
        ex:setFrame(1)
        scene.world:insert(ex)
        
        --[[ex.id = #scene.explosions
        scene.explosions[#scene.explosions] = ex
        
        ex:addEventListener("sprite", function (event) 
           if event.phase == "ended" then
             timer.performWithDelay( 30, function() scene.explosions[ex.id] = nil end )
           end
         end
        )--]]
        ex:play()
        audio.play(explosionSound)
        --[[if not obj.isBullet then
            scene.score = self.score + 1
            scene.scoreText.text = tostring(self.score)
        end--]]
    end

    -------------------------------------------------
    -- COLLISIONS
    -------------------------------------------------

    destroyObject = function ( obj )
        explode(obj)
        timer.performWithDelay(100, display.remove(obj))
        -- remove the object from the list if it belongs in one
        if obj.myName == "pig" then
            for i=1,#pigs do
                if pigs[i] == obj then
                    --table.remove(obj, i)
                    pigs[i] = nil
                end
            end

            -- check if the pig list is empty, if it is the level is complete
            if next(pigs) == nil then
                gameOver("yes")
            end
        end
    end

    local removeBullet = function (bullet)
        timer.performWithDelay(100, display.remove(bullet) )
    end

    -- this is a runtime handler, so we'll see all the collisions  XXX ug
    -- should use tables (the game objects) to handle each their own collisions (only)
    scene.onCollision = function ( event )
        if ( event.phase == "began" ) then
            if (event.object1.myName ~= "pig" and event.object2.myName == "pig") then
                -- a function affecting the state of the bullet should go here
                print("calling pig health depreciation")
                event.object2.health = event.object2.health - 30
                if event.object2.health < 40 then
                    event.object2.fsm:changeState(unhealthyState)
                end
                --[[if event.object2.health <= 0 then
                    destroyObject(event.object2)
                    audio.play(explosionSound)
                end--]]
                return true
            end
            if (event.object1.myName == "pig" and event.object2.myName ~= "pig") then
                -- a function affecting the state of the bullet should go here
                print("calling pig health depreciation")
                event.object1.health = event.object1.health - 30
                if event.object1.health < 20 then
                    event.object1.fsm:changeState(unhealthyState)
                end
                --[[if event.object1.health <= 0 then
                    destroyObject(event.object1)
                    audio.play(explosionSound)--]]
                return true
            end
            if (event.object2.isBullet and event.object1.myName == "wood") then
                if event.object1.destructable then
                    destroyObject(event.object1)
                    audio.play(explosionSound)
                end
                return true
            end
            if (event.object1.destructable and event.object2 == scene.player) then
                --print("bullet is removed")
                destroyObject(event.object1)
                audio.play(sound)
                return true
            end
            if (event.object2.destructable and event.object1 == scene.player) then
                --print("bullet is removed")
                destroyObject(event.object2)
                audio.play(explosionSound)
                return true
            end
        elseif ( event.phase == "ended" ) then
            --print( "ended: " )
        end
    end

    -------------------------------------------------
    -- BACKGROUND
    -------------------------------------------------

    local drawBackground = function()
        -- background 
        scene.background = display.newGroup()
        local bg = display.newImage("super-mario-level-wallpaper.png", system.ResourceDirectory, 0, 0, true)
        --bg:setReferencePoint(display.CenterLeftReferencePoint)
        bg.x = 0; bg.y = 180
        bg:scale(8,8)
        scene.background:insert(bg)
        group:insert(scene.background)

        -- world
        scene.world = display.newGroup()
        group:insert(scene.world)

    end


    local createGround = function()
        floor = display.newImageRect("ground.png", 480, 76)
        floor.x = 0; floor.y = centerY+300

        floor2 = display.newImageRect("ground.png", 480, 76)
        floor2.x = 480; floor2.y = centerY+300

        floor3 = display.newImageRect("ground.png", 480, 76)
        floor3.x = 960; floor3.y = centerY+300

        floor4 = display.newImageRect("ground.png", 480, 76)
        floor4.x = 1440; floor4.y = centerY+300

        floor5 = display.newImageRect("ground.png", 480, 76)
        floor5.x = 1920; floor5.y = centerY+300

        floor6 = display.newImageRect("ground.png", 480, 76)
        floor6.x = 2400; floor6.y = centerY+300

        floor7 = display.newImageRect("ground.png", 480, 76)
        floor7.x = 2880; floor7.y = centerY+300

        floor8 = display.newImageRect("ground.png", 480, 76)
        floor8.x = 3360; floor8.y = centerY+300

        floor9 = display.newImageRect("ground.png", 480, 76)
        floor9.x = 3840; floor9.y = centerY+300

        floor10 = display.newImageRect("ground.png", 480, 76)
        floor10.x = 4320; floor10.y = centerY+300

        floor11 = display.newImageRect("ground.png", 480, 76)
        floor11.x = -480; floor11.y = centerY+300

        floor12 = display.newImageRect("ground.png", 480, 76)
        floor12.x = -960; floor12.y = centerY+300

        floor.myName = "ground"
        floor2.myName = "ground"
        floor3.myName = "ground"
        floor4.myName = "ground"
        floor5.myName = "ground"
        floor6.myName = "ground"
        floor7.myName = "ground"
        floor8.myName = "ground"
        floor9.myName = "ground"
        floor10.myName = "ground"
        floor11.myName = "ground"
        floor12.myName = "ground"

        local groundShape = { -240,-18, 240,-18, 240,18, -240,18 }
        physics.addBody(floor, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor2, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor3, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor4, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor5, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor6, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor7, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor8, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor9, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor10, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor11, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})
        physics.addBody(floor12, "static", {density=1.0, bounce=0, friction=0.5, shape=groundShape})

        scene.world:insert(floor)
        scene.world:insert(floor2)
        scene.world:insert(floor3)
        scene.world:insert(floor4)
        scene.world:insert(floor5)
        scene.world:insert(floor6)
        scene.world:insert(floor7)
        scene.world:insert(floor8)
        scene.world:insert(floor9)
        scene.world:insert(floor10)
        scene.world:insert(floor11)
        scene.world:insert(floor12)

    end

    local loadUbuntuShot = function()
        ubuntuSign = display.newImageRect("ubuntu-sign.png", 96, 96)
        ubuntuSign.xScale = 1.0; ubuntuSign.yScale = 1.0
        ubuntuSign.isVisible = false

        group:insert(ubuntuSign)
    end

    local onScreenTouch = function (event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(event.target)
        end
        --[[if event.phase == "moved" then
            if (line) then
                line.parent:remove(line)
            end
            line = display.newLine(event.target.x, event.target.y, event.x, event.y)
            line:setColor(200,200,200,100)
            line.width = 8
        end--]]
        if event.phase == "ended" then
            -- calculate the distance and force that is placed on the penguin
            --local x = event.x
            --local y = event.y
            local xForce = (-1 * (event.x - event.xStart)) * 2.15
            local yForce = (-1 * (event.y - event.yStart)) * 2.15

            event.target.bodyType = "dynamic"
            event.target:applyLinearImpulse(xForce, yForce, event.target.x, event.target.y)
            event.target.isReady = false
            event.target.inAir = true

            --transition.to(ubuntuSign, {time=175, xScale=0.1, yScale=0.1, onComplete=flingPlayer})
        end
        return true
    end

    local setupLevel = function()
        print("setupLevel() being called")
        -- game objects
        drawBackground()
        createGround()
        loadUbuntuShot()
        penguin = loadBird(150, 200)
        penguin.x = 50
        penguin.y = 500
        --camera:add(penguin, 4, true)
        --camera:track()

        -- create the level
        createLevel()

        -- add event listeners
        penguin:addEventListener("touch", onScreenTouch)
        --Runtime:addEventListener("enterFrame", gameLoop)

    end
    
    if gameLives > 0 then
        setupLevel()
    end

    startAgain = function()
        print(gameLives)
        gameLives = gameLives - 1
        if gameLives <= 0 then
            penguin.isInBounds = false
            gameOver("no")

            -- make a new linus and destroy the old one
            --[[local oldLinus = penguin
            penguin = loadBird(150, 200)
            penguin.x = 50
            penguin.y = 500
            oldLinus:removeSelf()
            oldLinus = nil--]]
        else
            -- make a new linus and destroy the old one
            local oldLinus = penguin
            penguin = loadBird(150, 200)
            penguin.x = 50
            penguin.y = 500
            self.player = penguin
            oldLinus:removeSelf()
            oldLinus = nil

            setupLevel()
        end

        return true
    end

    -- Calls Execute Method in states!
    function update ( event )
        for i=1,#pigs do
            if pigs[i] ~= nil then
                pigs[i].fsm:update(event)
            end
        end
    end

  end

-------------------------------------------------
-- UPDATE
-------------------------------------------------

function scene:enterFrame ( event )
    if self.player.isInBounds == true then
        local p = self.player
        -- keep the world centered on the player with proper boundaries
        if p.x >= 0 and p.x <= 4000 then
          self.world.x = self.width/2 - p.x
        end

        if p.x < 0 or p.x > 4000 then
            outOfBounds = true
            p.isInBounds = false
            print("called")
            timer.performWithDelay(4000, startAgain)
        end
    end
        --self.world.y = self.height/2 - p.y
        -- move the background too, but slower
        self.background.x = self.world.x/10
        self.background.y = self.world.y/10
        -- constant force on player while button held
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
        local group = self.view
        -----------------------------------------------------------------------------

        --      This event requires build 2012.782 or later.

        -----------------------------------------------------------------------------

end

--
-- toggle() returns a function to toggle a boolean-value field
-- of the scene, based on the phase of the touch event
-- Pass toggle a string holding the field name, and it returns something
-- you can bind to a screen object's touch event handler
--
function scene.toggleButton (field)
        return function (event)
                if event.phase=="began" then
                        scene[field]=true
                elseif event.phase=="ended" then
                        scene[field]=false
                end
        end
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
        local group = self.view

        -----------------------------------------------------------------------------

        --      INSERT code here (e.g. start timers, load audio, start listeners, etc.)

        -----------------------------------------------------------------------------
        Runtime:addEventListener("enterFrame", scene)
        Runtime:addEventListener("collision", scene.onCollision)
        Runtime:addEventListener("enterFrame", update)

        --[[self.startButton.start()

        if self.useButtons then
                self.jumpButton:addEventListener("touch", self.toggleButton("jumpButtonDown"))
                self.leftButton:addEventListener("touch", self.toggleButton("leftButtonDown"))
                self.rightButton:addEventListener("touch", self.toggleButton("rightButtonDown"))
        else
                self.multitouchRect:addEventListener( "touch", self.multitouchListener )
        end

        self.player.x=centerX
        self.player.y=centerY

        self.player:play()--]]

end


-- Called when scene is about to move offscreen:
function scene:exitScene( event )
        local group = self.view

        -----------------------------------------------------------------------------

        --      INSERT code here (e.g. stop timers, remove listeners, unload sounds, etc.)

        -----------------------------------------------------------------------------
        Runtime:removeEventListener("enterFrame", scene)
        Runtime:removeEventListener("collision", scene.onCollision)
        --penguin:removeEventListener("touch", onScreenTouch)
        --microsoftPig:removeEventListener("onCollision", microsoftPig)
        --applePig:removeEventListener("onCollision", applePig)
        
        --self.menuButton.stop()
        --self.player:pause()
        physics.stop()
end


-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene( event )
        local group = self.view

        -----------------------------------------------------------------------------

        --      This event requires build 2012.782 or later.

        -----------------------------------------------------------------------------

end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene( event )
        local group = self.view

        -----------------------------------------------------------------------------

        --      INSERT code here (e.g. remove listeners, widgets, save state, etc.)

        -----------------------------------------------------------------------------

end


-- Called if/when overlay scene is displayed via storyboard.showOverlay()
function scene:overlayBegan( event )
        local group = self.view
        local overlay_name = event.sceneName  -- name of the overlay scene

        -----------------------------------------------------------------------------

        --      This event requires build 2012.797 or later.

        -----------------------------------------------------------------------------

end


-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded( event )
        local group = self.view
        local overlay_name = event.sceneName  -- name of the overlay scene

        -----------------------------------------------------------------------------

        --      This event requires build 2012.797 or later.

        -----------------------------------------------------------------------------

end



---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener( "willEnterScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "didExitScene" event is dispatched after scene has finished transitioning out
scene:addEventListener( "didExitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

-- "overlayBegan" event is dispatched when an overlay scene is shown
scene:addEventListener( "overlayBegan", scene )

-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener( "overlayEnded", scene )

---------------------------------------------------------------------------------



return scene