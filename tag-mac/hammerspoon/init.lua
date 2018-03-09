-- Ensure the IPC command line client is available
hs.ipc.cliInstall()

-- Watchers and other useful objects
local configFileWatcher = nil
local appWatcher = nil
local wifiWatcher = nil
local screenWatcher = nil
local usbWatcher = nil

local mouseCircle = nil
local mouseCircleTimer = nil

local statusletTimer = nil
local firewallStatusText = nil
local firewallStatusDot = nil
local cccStatusText = nil
local cccStatusDot = nil
local arqStatusText = nil
local arqStatusDot = nil

-- Define some keyboard modifier variables
-- (Node: Capslock bound to cmd+alt+ctrl+shift via Seil and Karabiner)
local alt = {"⌥"}
local hyper = {"⌘", "⌥", "⌃"}

-- Define monitor names for layout purposes
local display_laptop = "Color LCD"
local display_monitor = "Thunderbolt Display"

-- Define monitor names on desktop
local display_topleft = "DELL U2713HM"
local display_bottomleft = "DELL P2715Q (1)"
local display_bottomright = "DELL P2715Q (2)"
local display_topright = "DELL U2212HM"

-- Define audio device names for headphone/speaker switching
local headphoneDevice = "Jabra PRO 9470"
local speakerDevice = "Speaker-Schiit USB Audio Device"
local conferenceDevice = "BCC950 ConferenceCam"

-- Defines for WiFi watcher
local homeSSID = "unixborg" -- My home WiFi SSID
local lastSSID = hs.wifi.currentNetwork()

-- Defines for screen watcher
local lastNumberOfScreens = #hs.screen.allScreens()

-- Defines for window grid
hs.grid.GRIDWIDTH = 4
hs.grid.GRIDHEIGHT = 4
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-- Defines for window maximize toggler
local frameCache = {}

-- Define window layouts
--   Format reminder:
--     {"App name", "Window name", "Display Name", "unitrect", "framerect", "fullframerect"},
local iTunesMiniPlayerLayout = {"iTunes", "MiniPlayer", display_laptop, nil, nil, hs.geometry.rect(0, -48, 400, 48)}
local internal_display = {
    {"IRC",               nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Reeder",            nil,          display_laptop, hs.layout.left30,    nil, nil},
    {"Safari",            nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"OmniFocus",         nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Mail",              nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Microsoft Outlook", nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"HipChat",           nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"1Password",         nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Calendar",          nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Messages",          nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Evernote",          nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"iTunes",            "iTunes",     display_laptop, hs.layout.maximized, nil, nil},
    iTunesMiniPlayerLayout,
}

local dual_display = {
    {"IRC",               nil,          display_laptop,  hs.layout.maximized, nil, nil},
    {"Reeder",            nil,          display_monitor, hs.layout.right50,   nil, nil},
    {"Safari",            nil,          display_monitor, hs.layout.left50,    nil, nil},
    {"OmniFocus",         nil,          display_monitor, hs.layout.right50,   nil, nil},
    {"Mail",              nil,          display_laptop,  hs.layout.maximized, nil, nil},
    {"Microsoft Outlook", nil,          display_monitor, hs.layout.maximized, nil, nil},
    {"HipChat",           nil,          display_monitor, hs.layout.right50,   nil, nil},
    {"1Password",         nil,          display_monitor, hs.layout.right50,   nil, nil},
    {"Calendar",          nil,          display_monitor, hs.layout.maximized, nil, nil},
    {"Messages",          nil,          display_laptop,  hs.layout.maximized, nil, nil},
    {"Evernote",          nil,          display_monitor, hs.layout.right50,   nil, nil},
    {"iTunes",            "iTunes",     display_laptop,  hs.layout.maximized, nil, nil},
    iTunesMiniPlayerLayout,
}

local macpro_default = {
    {"Slack", nil, display_topright, hs.layout.maximized, nil, nil},
    {"Mail", nil, display_topleft, hs.layout.maximized, nil, nil},
    {"Airmail 2", nil, display_topleft, hs.layout.maximized, nil, nil},
    {"Fantastical", "Fantastical", display_topleft, hs.layout.maximized, nil, nil}
}

-- Helper functions

-- Replace Caffeine.app with 18 lines of Lua :D
local caffeine = hs.menubar.new()

function setCaffeineDisplay(state)
    local result
    if state then
        result = caffeine:setIcon("caffeine-on.pdf")
    else
        result = caffeine:setIcon("caffeine-off.pdf")
    end
end

function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
    caffeine:setClickCallback(caffeineClicked)
    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end

-- Toggle between speaker and headphone sound devices (useful if you have multiple USB soundcards that are always connected)
function toggle_audio_output()
    local current = hs.audiodevice.defaultOutputDevice()
    local speakers = hs.audiodevice.findOutputByName(speakerDevice)
    local headphones = hs.audiodevice.findOutputByName(headphoneDevice)

    if not speakers or not headphones then
        hs.notify.new({title="Hammerspoon", informativeText="ERROR: Some audio devices missing", ""}):send():release()
        return
    end

    if current:name() == speakers:name() then
        headphones:setDefaultOutputDevice()
    else
        speakers:setDefaultOutputDevice()
    end
    hs.notify.new({
          title='Hammerspoon',
            informativeText='Default output device:'..hs.audiodevice.defaultOutputDevice():name()
        }):send():release()
end

-- Toggle Skype between muted/unmuted, whether it is focused or not
function toggleSkypeMute()
    local skype = hs.appfinder.appFromName("Skype")
    if not skype then
        return
    end

    local lastapp = nil
    if not skype:isFrontmost() then
        lastapp = hs.application.frontmostApplication()
        skype:activate()
    end

    if not skype:selectMenuItem({"Conversations", "Mute Microphone"}) then
        skype:selectMenuItem({"Conversations", "Unmute Microphone"})
    end

    if lastapp then
        lastapp:activate()
    end
end

-- Toggle an application between being the frontmost app, and being hidden
function toggle_application(_app)
    local app = hs.appfinder.appFromName(_app)
    if not app then
        -- FIXME: This should really launch _app
        return
    end
    local mainwin = app:mainWindow()
    if mainwin then
        if mainwin == hs.window.focusedWindow() then
            mainwin:application():hide()
        else
            mainwin:application():activate(true)
            mainwin:application():unhide()
            mainwin:focus()
        end
    end
end

-- Toggle a window between its normal size, and being maximized
function toggle_window_maximized()
    local win = hs.window.focusedWindow()
    if frameCache[win:id()] then
        win:setFrame(frameCache[win:id()])
        frameCache[win:id()] = nil
    else
        frameCache[win:id()] = win:frame()
        win:maximize()
    end
end



-- Callback function for application events
function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        if (appName == "Finder") then
            -- Bring all Finder windows forward when one gets activated
            appObject:selectMenuItem({"Window", "Bring All to Front"})
        elseif (appName == "iTunes") then
            -- Ensure the MiniPlayer window is visible and correctly placed, since it likes to hide an awful lot
            state = appObject:findMenuItem({"Window", "MiniPlayer"})
            if state and not state["ticked"] then
                appObject:selectMenuItem({"Window", "MiniPlayer"})
            end
            _animationDuration = hs.window.animationDuration
            hs.window.animationDuration = 0
            hs.layout.apply({ iTunesMiniPlayerLayout })
            hs.window.animationDuration = _animationDuration
        end
    end
end

-- Callback function for WiFi SSID change events
function ssidChangedCallback()
    newSSID = hs.wifi.currentNetwork()

    if newSSID == homeSSID and lastSSID ~= homeSSID then
        -- We have gone from something that isn't my home WiFi, to something that is
        home_arrived()
    elseif newSSID ~= homeSSID and lastSSID == homeSSID then
        -- We have gone from something that is my home WiFi, to something that isn't
        home_departed()
    end

    lastSSID = newSSID
end

-- Callback function for USB device events
function usbDeviceCallback(data)
    print("usbDeviceCallback: "..hs.inspect(data))
    if (data["productName"] == "ScanSnap S1300i") then
        event = data["eventType"]
        if (event == "added") then
            hs.application.launchOrFocus("ScanSnap Manager")
        elseif (event == "removed") then
            app = hs.appfinder.appFromName("ScanSnap Manager")
            app:kill()
        end
    end
end

-- Callback function for changes in screen layout
function screensChangedCallback()
    newNumberOfScreens = #hs.screen.allScreens()

    if lastNumberOfScreens ~= newNumberOfScreens then
        if newNumberOfScreens == 1 then
            hs.layout.apply(internal_display)
        elseif newNumberOfScreens == 2 then
            hs.layout.apply(dual_display)
        end
    end

    -- FIXME: We should really be calling a function here that destroys and re-creates the statuslets, in case they need to be in new places

    lastNumberOfScreens = newNumberOfScreens

end

-- Perform tasks to configure the system for my home WiFi network
function home_arrived()
    hs.audiodevice.defaultOutputDevice():setVolume(25)

    -- Note: sudo commands will need to have been pre-configured in /etc/sudoers, for passwordless access, e.g.:
    -- cmsj ALL=(root) NOPASSWD: /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall *
    os.execute("sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off")

    -- Mount my mac mini's DAS
    hs.applescript.applescript([[
        tell application "Finder"
            try
                mount volume "smb://cmsj@servukipa._smb._tcp.local/Data"
            end try
        end tell
    ]])
    updateStatuslets()
    hs.notify.new({
          title='Hammerspoon',
            informativeText='Unmuted volume, mounted volumes, disabled firewall'
        }):send():release()
end

-- Perform tasks to configure the system for any WiFi network other than my home
function home_departed()
    hs.audiodevice.defaultOutputDevice():setVolume(0)
    os.execute("sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on")
    hs.applescript.applescript([[
        tell application "Finder"
            eject "Data"
        end tell
    ]])
    updateStatuslets()

    hs.notify.new({
          title='Hammerspoon',
            informativeText='Muted volume, unmounted volumes, enabled firewall'
        }):send():release()
end

-- I always end up losing my mouse pointer, particularly if it's on a monitor full of terminals.
-- This draws a bright red circle around the pointer for a few seconds
function mouseHighlight()
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    mousepoint = hs.mouse.getAbsolutePosition()
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
    mouseCircle:setStrokeWidth(5)
    mouseCircle:show()

    mouseCircleTimer = hs.timer.doAfter(3, function() mouseCircle:delete() end)
end

-- Rather than switch to Safari, copy the current URL, switch back to the previous app and paste,
-- This is a function that fetches the current URL from Safari and types it
function typeCurrentSafariURL()
    script = [[
    tell application "Safari"
        set currentURL to URL of document 1
    end tell

    return currentURL
    ]]
    ok, result = hs.applescript(script)
    if (ok) then
        hs.eventtap.keyStrokes(result)
    end
end

-- Reload config
function reloadConfig(paths)
    doReload = false
    for _,file in pairs(paths) do
        if file:sub(-4) == ".lua" then
            print("A lua file changed, doing reload")
            doReload = true
        end
    end
    if not doReload then
        print("No lua file changed, skipping reload")
        return
    end

    hs.reload()
end

-- Hotkeys to move windows between screens, retaining their position/size relative to the screen
-- hs.urlevent.bind('hyperfnleft', function() hs.window.focusedWindow():moveOneScreenWest() end)
-- hs.urlevent.bind('hyperfnright', function() hs.window.focusedWindow():moveOneScreenEast() end)
--
-- Hotkeys to resize windows absolutely
hs.hotkey.bind(hyper, 'a', function() hs.window.focusedWindow():moveToUnit(hs.layout.left30) end)
hs.hotkey.bind(hyper, 's', function() hs.window.focusedWindow():moveToUnit(hs.layout.right70) end)
hs.hotkey.bind(hyper, '[', function() hs.window.focusedWindow():moveToUnit(hs.layout.left50) end)
hs.hotkey.bind(hyper, ']', function() hs.window.focusedWindow():moveToUnit(hs.layout.right50) end)
hs.hotkey.bind(hyper, 'f', toggle_window_maximized)
hs.hotkey.bind(hyper, 'r', function() hs.window.focusedWindow():toggleFullScreen() end)
--
-- -- Hotkeys to trigger defined layouts
-- hs.hotkey.bind(hyper, '1', function() hs.layout.apply(internal_display) end)
-- hs.hotkey.bind(hyper, '2', function() hs.layout.apply(dual_display) end)
--
hs.hotkey.bind(hyper, '3', function() hs.layout.apply(macpro_default) end)
-- -- Hotkeys to interact with the window grid
hs.hotkey.bind(hyper, 'Left', hs.grid.pushWindowLeft)
hs.hotkey.bind(hyper, 'Right', hs.grid.pushWindowRight)
hs.hotkey.bind(hyper, 'Up', hs.grid.pushWindowUp)
hs.hotkey.bind(hyper, 'Down', hs.grid.pushWindowDown)
--
-- hs.urlevent.bind('hypershiftleft', hs.grid.resizeWindowThinner)
-- hs.urlevent.bind('hypershiftright', hs.grid.resizeWindowWider)
-- hs.urlevent.bind('hypershiftup', hs.grid.resizeWindowShorter)
-- hs.urlevent.bind('hypershiftdown', hs.grid.resizeWindowTaller)
--
-- -- Application hotkeys
-- hs.hotkey.bind(hyper, 'e', function() toggle_application("iTerm") end)
-- hs.hotkey.bind(hyper, 'q', function() toggle_application("Safari") end)
-- hs.hotkey.bind(hyper, 'z', function() toggle_application("Reeder") end)
-- hs.hotkey.bind(hyper, 'w', function() toggle_application("IRC") end)

-- -- Hotkeys to control the lighting in my office
-- local officeBrightnessDown = function()
--     brightness = brightness - 1
--     brightness = officeLED:zoneBrightness(1, brightness)
--     officeLED:zoneBrightness(2, brightness - 3)
-- end
-- local officeBrightnessUp = function()
--     brightness = brightness + 1
--     brightness = officeLED:zoneBrightness(1, brightness)
--     officeLED:zoneBrightness(2, brightness - 3)
-- end
-- hs.hotkey.bind({}, 'f5', officeBrightnessDown, nil, officeBrightnessDown)
-- hs.hotkey.bind({}, 'f6', officeBrightnessUp, nil, officeBrightnessUp)
-- hs.hotkey.bind(hyper, 'f5', function() brightness = officeLED:zoneBrightness(0, hs.milight.minBrightness) end)
-- hs.hotkey.bind(hyper, 'f6', function() brightness = officeLED:zoneBrightness(0, hs.milight.maxBrightness) end)
--
-- -- Misc hotkeys
-- hs.hotkey.bind(hyper, 'y', hs.toggleConsole)
-- hs.hotkey.bind(hyper, 'n', function() os.execute("open ~") end)
hs.hotkey.bind(hyper, 'c', caffeineClicked)
-- hs.hotkey.bind(hyper, 'h', hs.hints.windowHints())
-- hs.hotkey.bind(hyper, 'Escape', toggle_audi-o_output)
-- hs.hotkey.bind(hyper, 'm', toggleSkypeMute)
-- hs.hotkey.bind(hyper, 'd', mouseHighlight)
-- hs.hotkey.bind(hyper, 'u', typeCurrentSafariURL)
--
-- -- Type the current clipboard, to get around web forms that don't let you paste
-- -- (Note: I have Fn-v mapped to F17 in Karabiner)
-- hs.urlevent.bind('fnv', function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)
--
-- -- Create and start our callbacks
-- hs.application.watcher.new(applicationWatcher):start()
--
-- screenWatcher = hs.screen.watcher.new(screensChangedCallback)
-- screenWatcher:start()
--
-- wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
-- wifiWatcher:start()
--
-- usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
-- usbWatcher:start()
--
-- configFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
-- configFileWatcher:start()
--
-- -- Make sure we have the right location settings
-- if hs.wifi.currentNetwork() == "chrul" then
--     home_arrived()
-- else
--     home_departed()
-- end

-- Finally, show a notification that we finished loading the config successfully
hs.notify.new({
      title='Hammerspoon',
        informativeText='Config loaded'
    }):send():release()

-- This is some developer debugging stuff. It will cause Hammerspoon to crash if any Lua is being executed on the wrong thread. You probably don't want this in your config :)
-- local function crashifnotmain(reason)
-- --  print("crashifnotmain called with reason", reason) -- may want to remove this, very verbose otherwise
--   if not hs.crash.isMainThread() then
--     print("not in main thread, crashing")
--     hs.crash.crash()
--   end
-- end
-- debug.sethook(crashifnotmain, 'c')
