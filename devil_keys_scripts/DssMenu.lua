-- Change this variable to match your mod. The standard is "Dead Sea Scrolls (Mod Name)"
local DSSModName = "Dead Sea Scrolls (Devil Keys)"

-- DSSCoreVersion determines which menu controls the mod selection menu that allows you to enter other mod menus.
-- Don't change it unless you really need to and make sure if you do that you can handle mod selection and global mod options properly.
local DSSCoreVersion = 6

-- Every MenuProvider function below must have its own implementation in your mod, in order to handle menu save data.
local MenuProvider = {}

function MenuProvider.SaveSaveData()
    DevilKeysMod:SaveStorage()
end

function MenuProvider.GetPaletteSetting()
    return DevilKeysMod.Config.MenuPalette
end

function MenuProvider.SavePaletteSetting(var)
    DevilKeysMod.Config.MenuPalette = var
end

function MenuProvider.GetHudOffsetSetting()
    if not REPENTANCE then
        return DevilKeysMod.Config.HudOffset
    else
        return Options.HUDOffset * 10
    end
end

function MenuProvider.SaveHudOffsetSetting(var)
    if not REPENTANCE then
        DevilKeysMod.Config.HudOffset = var
    end
end

function MenuProvider.GetGamepadToggleSetting()
    return DevilKeysMod.Config.GamepadToggle
end

function MenuProvider.SaveGamepadToggleSetting(var)
    DevilKeysMod.Config.GamepadToggle = var
end

function MenuProvider.GetMenuKeybindSetting()
    return DevilKeysMod.Config.MenuKeybind
end

function MenuProvider.SaveMenuKeybindSetting(var)
    DevilKeysMod.Config.MenuKeybind = var
end

function MenuProvider.GetMenuHintSetting()
    return DevilKeysMod.Config.MenuHint
end

function MenuProvider.SaveMenuHintSetting(var)
    DevilKeysMod.Config.MenuHint = var
end

function MenuProvider.GetMenuBuzzerSetting()
    return DevilKeysMod.Config.MenuBuzzer
end

function MenuProvider.SaveMenuBuzzerSetting(var)
    DevilKeysMod.Config.MenuBuzzer = var
end

function MenuProvider.GetMenusNotified()
    return DevilKeysMod.Config.MenusNotified
end

function MenuProvider.SaveMenusNotified(var)
    DevilKeysMod.Config.MenusNotified = var
end

function MenuProvider.GetMenusPoppedUp()
    return DevilKeysMod.Config.MenusPoppedUp
end

function MenuProvider.SaveMenusPoppedUp(var)
    DevilKeysMod.Config.MenusPoppedUp = var
end

local DSSInitializerFunction = require("devil_keys_scripts.dssmenucore")

-- This function returns a table that some useful functions and defaults are stored on
local dssmod = DSSInitializerFunction(DSSModName, DSSCoreVersion, MenuProvider)


-- Adding a Menu


-- Creating a menu like any other DSS menu is a simple process.
-- You need a "Directory", which defines all of the pages ("items") that can be accessed on your menu, and a "DirectoryKey", which defines the state of the menu.
local exampledirectory = {
    -- The keys in this table are used to determine button destinations.
    main = {
        -- "title" is the big line of text that shows up at the top of the page!
        title = 'devil key pieces',

        -- "buttons" is a list of objects that will be displayed on this page. The meat of the menu!
        buttons = {
            -- The simplest button has just a "str" tag, which just displays a line of text.
            
            -- The "action" tag can do one of three pre-defined actions:
            --- "resume" closes the menu, like the resume game button on the pause menu. Generally a good idea to have a button for this on your main page!
            --- "back" backs out to the previous menu item, as if you had sent the menu back input
            --- "openmenu" opens a different dss menu, using the "menu" tag of the button as the name
            {str = 'resume game', action = 'resume'},

            -- The "dest" option, if specified, means that pressing the button will send you to that page of your menu.
            -- If using the "openmenu" action, "dest" will pick which item of that menu you are sent to.
            {str = 'settings', dest = 'settings'},

            -- A few default buttons are provided in the table returned from DSSInitializerFunction.
            -- They're buttons that handle generic menu features, like changelogs, palette, and the menu opening keybind
            -- They'll only be visible in your menu if your menu is the only mod menu active; otherwise, they'll show up in the outermost Dead Sea Scrolls menu that lets you pick which mod menu to open.
            -- This one leads to the changelogs menu, which contains changelogs defined by all mods.
            dssmod.changelogsButton,
        },

        -- A tooltip can be set either on an item or a button, and will display in the corner of the menu while a button is selected or the item is visible with no tooltip selected from a button.
        -- The object returned from DSSInitializerFunction contains a default tooltip that describes how to open the menu, at "menuOpenToolTip"
        -- It's generally a good idea to use that one as a default!
        tooltip = dssmod.menuOpenToolTip
    },
    settings = {
        title = 'settings',
        buttons = {
            -- These buttons are all generic menu handling buttons, provided in the table returned from DSSInitializerFunction
            -- They'll only show up if your menu is the only mod menu active
            -- You should generally include them somewhere in your menu, so that players can change the palette or menu keybind even if your mod is the only menu mod active.
            -- You can position them however you like, though!
            dssmod.gamepadToggleButton,
            dssmod.menuKeybindButton,
            dssmod.paletteButton,
            dssmod.menuHintButton,
            dssmod.menuBuzzerButton,

            {
                str = 'trinket to spawn',

                -- The "choices" tag on a button allows you to create a multiple-choice setting
                choices = {'detect number magnet', 'always black feather', 'always number magnet'},
                -- The "setting" tag determines the default setting, by list index. EG "1" here will result in the default setting being "choice a"
                setting = 1,

                -- "variable" is used as a key to story your setting; just set it to something unique for each setting!
                variable = 'TrinketToSpawn',
                
                -- When the menu is opened, "load" will be called on all settings-buttons
                -- The "load" function for a button should return what its current setting should be
                -- This generally means looking at your mod's save data, and returning whatever setting you have stored
                load = function()
                    return DevilKeysMod.Config.TrinketToSpawn or 1
                end,

                -- When the menu is closed, "store" will be called on all settings-buttons
                -- The "store" function for a button should save the button's setting (passed in as the first argument) to save data!
                store = function(var)
                    DevilKeysMod.Config.TrinketToSpawn = var
                end,

                -- A simple way to define tooltips is using the "strset" tag, where each string in the table is another line of the tooltip
                tooltip = {strset = {'what trinket', 'spawns after', '2nd key piece'}}
            },

            {
                str = '',
                fsize = 2,
                nosel = true
            },

            {
                str = "detecting the number magnet unlock",
                fsize = 1,
                nosel = true,

                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 1
                        end
                    end
                end
            },
            {
                str = "can be unreliable when there are",
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 1
                        end
                    end
                end
            },
            {
                str = "too many mods",
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 1
                        end
                    end
                end
            },

            {
                str = '',
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 2
                        end
                    end
                end
            },
            {
                str = "always spawn black feather",
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 2
                        end
                    end
                end
            },
            {
                str = '',
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 2
                        end
                    end
                end
            },

            {
                str = '',
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 3
                        end
                    end
                end
            },
            {
                str = "always spawn number magnet",
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 3
                        end
                    end
                end
            },
            {
                str = '',
                fsize = 1,
                nosel = true,
                displayif = function (_, item)
                    for _, btn in ipairs(item.buttons) do
                        if btn.variable == 'TrinketToSpawn' then
                            return btn.setting == 3
                        end
                    end
                end
            },
        }
    }
}

local exampledirectorykey = {
    Item = exampledirectory.main, -- This is the initial item of the menu, generally you want to set it to your main item
    Main = 'main', -- The main item of the menu is the item that gets opened first when opening your mod's menu.

    -- These are default state variables for the menu; they're important to have in here, but you don't need to change them at all.
    Idle = false,
    MaskAlpha = 1,
    Settings = {},
    SettingsChanged = false,
    Path = {},
}

DeadSeaScrollsMenu.AddMenu("Devil Key Pieces", {
    -- The Run, Close, and Open functions define the core loop of your menu
    -- Once your menu is opened, all the work is shifted off to your mod running these functions, so each mod can have its own independently functioning menu.
    -- The DSSInitializerFunction returns a table with defaults defined for each function, as "runMenu", "openMenu", and "closeMenu"
    -- Using these defaults will get you the same menu you see in Bertran and most other mods that use DSS
    -- But, if you did want a completely custom menu, this would be the way to do it!
    
    -- This function runs every render frame while your menu is open, it handles everything! Drawing, inputs, etc.
    Run = dssmod.runMenu,
    -- This function runs when the menu is opened, and generally initializes the menu.
    Open = dssmod.openMenu,
    -- This function runs when the menu is closed, and generally handles storing of save data / general shut down.
    Close = dssmod.closeMenu,

    -- If UseSubMenu is set to true, when other mods with UseSubMenu set to false / nil are enabled, your menu will be hidden behind an "Other Mods" button.
    -- A good idea to use to help keep menus clean if you don't expect players to use your menu very often!
    UseSubMenu = false,

    Directory = exampledirectory,
    DirectoryKey = exampledirectorykey
})

-- There are a lot more features that DSS supports not covered here, like sprite insertion and scroller menus, that you'll have to look at other mods for reference to use.
-- But, this should be everything you need to create a simple menu for configuration or other simple use cases!