local storyboard = require( "storyboard" )
local physics = require("physics")
local utils = require("utils")
local scene = storyboard.newScene()
local vector = require("vector")
local fsm = require("fsm")

--local client = require("client")

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
        local group = self.view

        
               -- background 
        scene.background = display.newGroup()
        local bg = display.newImage("super-mario-level-wallpaper.png", 
                        system.ResourceDirectory,
                        0,0,
                        true)
        bg:scale(8,8)
        scene.background:insert(bg)
        group:insert(scene.background)

        -- world
        scene.world = display.newGroup()
        group:insert(scene.world)

        -- image sheet from sky bkgrnd
        local options = { width=64, height=64, numFrames=768, 
                                sheetContentWidth=2048, sheetContentHeight=1536}
        scene.skySheet = graphics.newImageSheet("super-mario-level-wallpaper.png",options)
        scene.goodStartFrameForTextures = 19*32 -- four rows of 32 at bottom of image
        scene.numGoodTextureFrames = 4*32

        -- hud
        scene.hud = display.newGroup()
        group:insert(scene.hud)
 
        physics.start()

        local centerX = display.contentCenterX
        local centerY = display.contentCenterY
        scene.width = display.contentWidth
        scene.height = display.contentHeight


        local thickness = 10
        
        -- implement the rectangle objects as FSM's
        --[[function addRect(x,y,w,h,destructable,density)
--                local rect = display.newRect(x,y,w,h)
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
        end --]]
        
        function loadBird()
                local options =
                        {
                            -- The params below are required
                            width = 270,
                            height = 267,
                            numFrames = 9,
                            -- The params below are optional; used for dynamic resolution support
                            --sheetContentWidth = 900,  -- width of original 1x size of entire sheet
                            --sheetContentHeight = 900  -- height of original 1x size of entire sheet
                        }

                local imageSheet = graphics.newImageSheet( "spike_bird_sprite.png", options )

                local sequenceData =
                        {
                            name="walking",
                            start=1,
                            count=9,
                            time=10,
                            loopCount = 0,   -- Optional ; default is 0 (loop indefinitely)
                            loopDirection = "forward"    -- Optional ; values include "forward" or "bounce"
                        }
                return display.newSprite ( imageSheet, sequenceData )

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
-- LEVEL
-------------------------------------------------

        local floorLength = 20000
        -- the floor
        addRect(0, centerY+100, floorLength, 10, false, 10.0)
        -- some stuff
        
        -- this makes a bunch of rectangle objects
        local steps=40
        for i=1,steps do
                for j=1,steps do

                        --local isDestructable
                        --if math.random(0,100)>0 then
                        --        isDestructable=true
                        --else
                        --        isDestructable=nil
                        --end
                        local isDestructable = true

                        local deltax = floorLength/2 / steps
                        local deltay = (5000) / steps
                        local minx = centerX + j * deltax
                        local miny = centerY - j * deltay
                        local maxx = minx + deltax
                        local maxy = centerY+20
                        local minsize = 8
                        local maxsize = 64
                        addRect ( math.random (minx, maxx),
                                math.random ( miny, maxy),
                                math.random(minsize, maxsize),
                                math.random(minsize,maxsize),
                                isDestructable,
                                0.075*i/steps) -- gets denser along x
                end
        end

-------------------------------------------------
-- GUI
-------------------------------------------------
        --[[local margin = 50

        -- score
        self.score = 0
        self.scoreText = display.newText(tostring(self.score), 
                                        self.width - margin, margin,
                                        native.systemFont, 36 )

        self.useButtons = false -- if false, then use multitouch 

        -- draw them regardless if used for input events
        self.rightButton = display.newImage ("rtArrow.png")
        self.rightButton:translate(scene.width-margin, scene.height-margin)
        scene.hud:insert(self.rightButton)

        self.jumpButton = display.newImage ("rtArrow.png")
        self.jumpButton:rotate(-90)
        self.jumpButton:translate(scene.width/2, scene.height-margin)
        scene.hud:insert(self.jumpButton)

        self.leftButton = display.newImage("rtArrow.png")
        self.leftButton:rotate(180)
        self.leftButton:translate(margin, scene.height-margin)
        scene.hud:insert(self.leftButton)

        if (self.useButtons) then
                --         
        else 
                -- the problem with buttons done the usual way is no multitouch

                system.activate("multitouch")

                -- create a single big button

                self.multitouchRect = display.newRect( centerX, centerY, self.width, self.height )
                self.currentTouches = {}
                self.multitouchListener = function ( event )
                        --print( "Phase: "..event.phase )
                        --print( "Location: "..event.x..","..event.y )
                        --print( "Unique touch ID: "..tostring(event.id) )
                        --print( "----------" )
                        local finger=self.currentTouches[event.id]
                        if finger then
                                if event.phase=="ended" then
                                        self[finger.flag] = false
                                        self.currentTouches[event.id]=nil 
                                end     
                        else
                                local w3 = self.width / 3 
                                if event.phase=="began" then
                                        local finger = {}
                                        if event.x < w3 then
                                                finger.flag="leftButtonDown"
                                        elseif event.x < 2*w3 then
                                                finger.flag = "jumpButtonDown"
                                        else
                                                finger.flag = "rightButtonDown"
                                        end
                                        self[finger.flag] = true
                                        self.currentTouches[event.id] = finger
                                end
                        end

                        return true
                end
                self.multitouchRect.alpha = 0
                self.multitouchRect.isHitTestable = true -- Only needed if alpha is 0
                self.hud:insert(self.multitouchRect)

                -- button to return to startmenu
               self.startButton = utils.makeButtonToScene("startmenu","startButton.png", 
                       self.hud, margin, margin)
               self.startButton:scale(0.25,0.25)
 
        end--]]

        

-------------------------------------------------
-- PLAYER
-------------------------------------------------

        scene.player = loadBird()
        scene.world:insert(scene.player)
        physics.addBody(scene.player, "dynamic", {density=1.0, friction=0.7, bounce=0.1})

-------------------------------------------------
-- AUDIO 
-------------------------------------------------

      --  local sound = audio.loadSound("borp.wav")
      --  audio.setVolume(0.05)


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
                
                ex.id = #scene.explosions
                scene.explosions[#scene.explosions] = ex
                
                ex:addEventListener("sprite", function (event) 
                   if event.phase == "ended" then
                     timer.performWithDelay( 30, function() scene.explosions[ex.id] = nil end )
                   end
                 end
                )
                ex:play()

                if not obj.isBullet then
                    scene.score = self.score + 1
                    scene.scoreText.text = tostring(self.score)
                end
        end

 -------------------------------------------------
-- COLLISIONS
-------------------------------------------------

    local destroyObject = function ( obj )
        explode(obj)
        timer.performWithDelay(100, display.remove(obj))
        --audio.play(sound)
    end

    local removeBullet = function (bullet)
        timer.performWithDelay(100, display.remove(bullet) )
    end

-- this is a runtime handler, so we'll see all the collisions  XXX ug
-- should use tables (the game objects) to handle each their own collisions (only)
        scene.onCollision = function ( event )
            if ( event.phase == "began" ) then
                --print( "began: " )
                if (event.object1.isBullet and event.object2 ~= scene.player) then
                    removeBullet(event.object1)
                    if event.object2.destructable then
                        destroyObject(event.object2)
                        audio.play(sound)
                    end
                    return true
                end
                if (event.object2.isBullet and event.object1 ~= scene.player) then
                    removeBullet(event.object2)
                    if event.object1.destructable then
                        destroyObject(event.object1)
                        audio.play(sound)
                    end
                    return true
                end
                if (event.object1.destructable and event.object2 == scene.player) then
                    destroyObject(event.object1)
                    audio.play(sound)
                    return true
                end
                if (event.object2.destructable and event.object1 == scene.player) then
                    destroyObject(event.object2)
                    audio.play(sound)
                    return true
                end
            elseif ( event.phase == "ended" ) then
                --print( "ended: " )
            end
    end

end
---------------------------------

-------------------------------------------------
-- BULLETS
-------------------------------------------------
--[[function scene:shootBullet()
    local bullet = display.newCircle( self.player.x, self.player.y, 10 )
    self.world:insert(bullet)

    bullet.isBullet = true
    physics.addBody( bullet, "dynamic", { radius=10 } )
    bullet.gravityScale = 0
    bullet:setLinearVelocity( 800,0 )
end--]]

-------------------------------------------------
-- UPDATE
-------------------------------------------------

function scene:enterFrame ( event )
        local p = self.player
        -- keep the world centered on the player
        self.world.x = self.width/2 - p.x
        self.world.y = self.height/2 - p.y
        -- move the background too, but slower
        self.background.x = self.world.x/10
        self.background.y = self.world.y/10
        -- constant force on player while button held
        if self.rightButtonDown then
                p:applyForce(100, 0, p.x, p.y)
        end
        if self.leftButtonDown then
                p:applyForce(-100, 0, p.x, p.y)
        end
        if self.jumpButtonDown then
                p:applyForce(0, -300, p.x, p.y)
        end

        self.timeLastBulletFired = self.timeLastBulletFired or system.getTimer()
        local now = system.getTimer()
        --[[if now - self.timeLastBulletFired > 100 then
            self:shootBullet()
            self.timeLastBulletFired = now
        end--]]

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

        self.startButton.stop()

                if self.useButtons then
                self.jumpButton:removeEventListener("touch",self)
                self.leftButton:removeEventListener("touch",self)
                self.rightButton:removeEventListener("touch",self)
        else
                self.multitouchRect:removeEventListener( "touch", self.multitouchListener )
        end
 
        self.player:pause()
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