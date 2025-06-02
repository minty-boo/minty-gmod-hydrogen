local mod = hydrogen.Module()

-- Cache
local surface_DrawTexturedRectUV    = surface.DrawTexturedRectUV
local surface_SetDrawColor          = surface.SetDrawColor
local surface_SetTexture            = surface.SetTexture

-- Variables
local hud_shadow_border = surface.GetTextureID( "vgui/ttt/dynamic/hud_components/shadow_border" )

-- Patch: DrawHUDElementLines (gamemodes/terrortown/gamemode/shared/huds/pure_skin/cl_drawing_functions.lua)
-- Speed-up: ~2% (Ryzen 7 7800X3D, Radeon RX 6700 XT)
function mod.patch.DrawHUDElementLines( x, y, w, h, a )
    local xw = x + w
    local yh = y + h
    
    surface_SetDrawColor( 255, 255, 255, a )
    surface_SetTexture( hud_shadow_border )

    surface_DrawTexturedRectUV(
        x - 4,
        yh - 3,
        7,
        7,
        0.05555555555,
        0.83333333333,
        0.16666666666,
        0.94444444444
    )

    surface_DrawTexturedRectUV(
        xw - 3,
        yh - 3,
        7,
        7,
        0.83333333333,
        0.83333333333,
        0.94444444444,
        0.94444444444
    )

    surface_DrawTexturedRectUV(
        x - 4,
        y - 4,
        7,
        7,
        0.05555555555,
        0.05555555555,
        0.16666666666,
        0.16666666666
    )

    surface_DrawTexturedRectUV(
        xw - 3,
        y - 4,
        7,
        7,
        0.83333333333,
        0.05555555555,
        0.94444444444,
        0.16507936507
    )

    surface_DrawTexturedRectUV(
        x + 3,
        yh - 3,
        w - 6,
        7,
        0.5,
        0.83333333333,
        0.51587301587,
        0.94444444444
    )

    surface_DrawTexturedRectUV(
        x - 4,
        y + 3,
        7,
        h - 6,
        0.05555555555,
        0.5,
        0.16666666666,
        0.51587301587
    )

    surface_DrawTexturedRectUV(
        xw - 3,
        y + 3,
        7,
        h - 6,
        0.83333333333,
        0.5,
        0.94444444444,
        0.51587301587
    )

    surface_DrawTexturedRectUV(
        x + 3,
        y - 4,
        w - 6,
        7,
        0.5,
        0.05555555555,
        0.51587301587,
        0.16666666666
    )
end

-- Export
return mod