local storyboard = require("storyboard")
local utils = require("utils")

local scene = storyboard.newScene()

-- local forward references

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- called when scene's view does not exist:
function scene:createScene(event)
  local group = self.view
  -----------------------------------------------------------------------------

        --      CREATE display objects and add them to 'group' here.
        --      Example use-case: Restore 'group' from previously saved state.

        -----------------------------------------------------------------------------
  self.background = display.newGroup()
  local bg = display.newImage("default.png")
  
    bg:scale(2,2)
    bg.x = display.contentCenterX
    bg.y = display.contentCenterY
    self.background:insert(bg)
    group:insert(self.background)
    
    self.buttons = display.newGroup()
    group:insert(self.buttons)
    
    self.startButton = utils.makeButtonToScene("sceneFight1",
      "Ubuntu_Start_Button.png", self.buttons, 
      display.contentCenterX,
      display.contentCenterY)
end
    
function scene:enterFrame(event)
  self.background:translate(math.random(0,1)-0.5, math.random(0,1)-0.5)
end

--called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
  local group = self.view
end

-- called immediately after scene has moved onscreen:
function scene:enterScene(event)
  local group = self.view
  -----------------------------------------------------------------------------

        --      INSERT code here (e.g. start timers, load audio, start listeners, etc.)

        -----------------------------------------------------------------------------
  
  Runtime:addEventListener("enterFrame", scene)
  self.startButton.start()
end

-- called when scene is about to move offscreen:
function scene:exitScene(event)
  local group = self.view
  -----------------------------------------------------------------------------

        --      INSERT code here (e.g. stop timers, remove listeners, unload sounds, etc.)

        -----------------------------------------------------------------------------
  
  self.startButton.stop()
end

-- called AFTER scene has finished moving offscreen:
function scene:didExitScene(event)
  local group = self.view
  -----------------------------------------------------------------------------

        --      This event requires build 2012.782 or later.

        -----------------------------------------------------------------------------
end

-- called prior to the removal of scene's "view" (display group)
function scene:destroyScene(event)
  local group = self.view
  
  -----------------------------------------------------------------------------

        --      INSERT code here (e.g. remove listeners, widgets, save state, etc.)

                      -----------------------------------------------------------------------------

end

function scene:overlayBegan(event)
  local group = self.view
  local overlay_name = event.sceneName
end


-- called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded(event)
  local group = self.view
  local overlay_name = event.sceneName
end

-- "createScene" event is displatched if scene's view does not exist
scene:addEventListener("createScene", scene)

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