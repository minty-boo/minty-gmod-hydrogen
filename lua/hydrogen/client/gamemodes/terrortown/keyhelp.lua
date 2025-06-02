local mod = hydrogen.Module()

-- Cache
local Key                           = Key
local LANG_TryTranslation           = LANG.TryTranslation
local ScrH                          = ScrH
local ScrW                          = ScrW
local appearance_GetGlobalScale     = appearance.GetGlobalScale
local bind_Find                     = bind.Find
local draw                          = draw
local input_GetKeyName              = input.GetKeyName
local isfunction                    = isfunction
local math_Round                    = math.Round
local math_floor                    = math.floor
local math_max                      = math.max
local string_upper                  = string.upper
local util_EditingModeActive        = util.EditingModeActive

local keyhelp_keyHelpers_INTERNAL   = keyhelp.keyHelpers[ KEYHELP_INTERNAL ]
local keyhelp_keyHelpers_CORE       = keyhelp.keyHelpers[ KEYHELP_CORE ]
local keyhelp_keyHelpers_EQUIPMENT  = keyhelp.keyHelpers[ KEYHELP_EQUIPMENT ]
local keyhelp_keyHelpers_EXTRA      = keyhelp.keyHelpers[ KEYHELP_EXTRA ]
local keyhelp_keyHelpers_SCOREBOARD = keyhelp.keyHelpers[ KEYHELP_SCOREBOARD ]

-- Variables
local cvEnableCore          = GetConVar( "ttt2_keyhelp_show_core" )
local cvEnableExtra         = GetConVar( "ttt2_keyhelp_show_extra" )
local cvEnableEquipment     = GetConVar( "ttt2_keyhelp_show_equipment" )
local cvEnableBoxBlur       = GetConVar( "ttt2_hud_enable_box_blur" )
local cvEnableDescription   = GetConVar( "ttt2_hud_enable_description" )

local cvEnableBoxBlur_bool      = false
local cvEnableDescription_bool  = false

local offsetCenter  = 230
local height        = 48
local width         = 18
local padding       = 5
local thicknessLine = 2

local heightScaled  = 0
local widthScaled   = 0
local paddingScaled = 0
local thicknessLineScaled   = 0
local thicknessLineScaledH  = 0

local colorBox  = Color(0, 0, 0, 100)

local fnull = function() end

-- Utility: keyhelp.Draw
local function DrawKeyContent(x, y, keyString, iconMaterial, bindingName, scoreboardShown, scale)
    local wKeyString = draw.GetTextSize(keyString, "weapon_hud_help_key", scale)
    local wBox = math_max(widthScaled, wKeyString) + 2 * paddingScaled
    local xIcon = x + 0.5 * (wBox - widthScaled)
    local yIcon = y + paddingScaled + thicknessLineScaled
    local xKeyString = x + math_floor(0.5 * wBox)
    local yKeyString = yIcon + widthScaled + paddingScaled

    if cvEnableBoxBlur_bool then
        draw.BlurredBox(x, y, wBox, heightScaled + paddingScaled)
        draw.Box(x, y, wBox, heightScaled + paddingScaled, colorBox) -- background color
        draw.Box(x, y, wBox, thicknessLineScaledH, colorBox) -- top line shadow
        draw.Box(x, y, wBox, thicknessLineScaled, colorBox) -- top line shadow
        draw.Box(x, y - thicknessLineScaled, wBox, thicknessLineScaled, COLOR_WHITE) -- white top line
    end

    draw.FilteredShadowedTexture(
        xIcon,
        yIcon,
        widthScaled,
        widthScaled,
        iconMaterial,
        255,
        COLOR_WHITE,
        scale
    )

    draw.AdvancedText(
        keyString,
        "weapon_hud_help_key",
        xKeyString,
        yKeyString,
        COLOR_WHITE,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_TOP,
        true,
        scale
    )

    if scoreboardShown and cvEnableDescription_bool then
        draw.AdvancedText(
            LANG_TryTranslation(bindingName),
            "weapon_hud_help",
            xKeyString,
            y - 3 * paddingScaled,
            COLOR_WHITE,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER,
            true,
            scale,
            -45
        )
    end

    return wBox
end

local function DrawKey(client, xBase, yBase, keyHelper, scoreboardShown, scale)
    if not ( keyHelper.callback or fnull )(client) then
        return
    end

    -- handles both internal GMod bindings and TTT2 bindings
    local key = Key(keyHelper.binding) or input_GetKeyName(bind_Find(keyHelper.binding))

    if not key then
        return
    end

    return xBase
        + paddingScaled
        + DrawKeyContent(
            xBase,
            yBase,
            string_upper(key),
            keyHelper.iconMaterial,
            keyHelper.bindingName,
            scoreboardShown,
            scale
        )
end

-- Patch: keyhelp.Draw (lua/ttt2/libraries/keyhelp.lua)
-- Speed-up: ~40% (Ryzen 7 7800X3D, Radeon RX 6700 XT), including draw.* patches
function mod.patch.keyhelp.Draw()
    local client = LocalPlayer()
    local scoreboardShown = GAMEMODE.ShowScoreboard

    local scale = appearance_GetGlobalScale()

    local xBase = 0.5 * ScrW() + offsetCenter * scale
    local yBase = ScrH() - height * scale

    heightScaled = height * scale
    widthScaled = width * scale
    paddingScaled = padding * scale
    thicknessLineScaled = math_Round(thicknessLine * scale)
    thicknessLineScaledH = math_Round( 0.5 * thicknessLineScaled )

    local cvEnableCore = cvEnableCore:GetBool()
    local cvEnableExtra = cvEnableExtra:GetBool()
    local cvEnableEquipment = cvEnableEquipment:GetBool()

    cvEnableBoxBlur_bool = cvEnableBoxBlur:GetBool()
    cvEnableDescription_bool = cvEnableDescription:GetBool()

    if cvEnableCore or scoreboardShown then
        for i = 1, #keyhelp_keyHelpers_INTERNAL do
            xBase = DrawKey(
                client,
                xBase,
                yBase,
                keyhelp_keyHelpers_INTERNAL[i],
                scoreboardShown,
                scale
            ) or xBase
        end
    end

    if not util_EditingModeActive(client) then
        if keyhelp_keyHelpers_CORE and (cvEnableCore or scoreboardShown) then
            for i = 1, #keyhelp_keyHelpers_CORE do
                xBase = DrawKey(
                    client,
                    xBase,
                    yBase,
                    keyhelp_keyHelpers_CORE[i],
                    scoreboardShown,
                    scale
                ) or xBase
            end
        end

        if
            keyhelp_keyHelpers_EQUIPMENT
            and (cvEnableEquipment or scoreboardShown)
        then
            for i = 1, #keyhelp_keyHelpers_EQUIPMENT do
                xBase = DrawKey(
                    client,
                    xBase,
                    yBase,
                    keyhelp_keyHelpers_EQUIPMENT[i],
                    scoreboardShown,
                    scale
                ) or xBase
            end
        end

        if keyhelp_keyHelpers_EXTRA and (cvEnableExtra or scoreboardShown) then
            for i = 1, #keyhelp_keyHelpers_EXTRA do
                xBase = DrawKey(
                    client,
                    xBase,
                    yBase,
                    keyhelp_keyHelpers_EXTRA[i],
                    scoreboardShown,
                    scale
                ) or xBase
            end
        end
    end

    -- if anyone of them is disabled, but not all, the show more option is shown
    if not scoreboardShown and ( not cvEnableCore or not cvEnableEquipment or not cvEnableExtra ) then
        xBase = DrawKey(
            client,
            xBase,
            yBase,
            keyhelp_keyHelpers_SCOREBOARD[1],
            scoreboardShown,
            scale
        ) or xBase
    end
end

-- Export
return mod