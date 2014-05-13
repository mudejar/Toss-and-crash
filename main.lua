-- Programmer: Bader Aljishi
-- CS4849 - game programming

local storyboard = require( "storyboard" )
--local sceneBalls = require ( "sceneBalls" )
-- local sceneRun = require ("sceneRun")
local startMenu = require("startmenu")


-- Fetch all input devices currently connected to the system.
local inputDevices = system.getInputDevices()

-- Traverse all input devices.
for deviceIndex = 1, #inputDevices do
    -- Fetch the input device's axes.
    local inputAxes = inputDevices[deviceIndex]:getAxes()
    if #inputAxes > 0 then
        -- Print all available axes to the log.
        for axisIndex = 1, #inputAxes do
            print(inputAxes[axisIndex].descriptor)
        end
    else
        -- Device does not have any axes.
        print(inputDevices[deviceIndex].descriptor .. ": No axes found.")
    end
end

--
--storyboard.gotoScene ( "sceneBalls" )
storyboard.gotoScene ( "startmenu" )
