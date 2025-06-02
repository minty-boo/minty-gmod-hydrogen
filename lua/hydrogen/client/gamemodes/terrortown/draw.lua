local mod = hydrogen.Module()

-- Patches:     lua/ttt2/extensions/draw.lua
-- Speed-up:    ~15% (Ryzen 7 7800X3D, Radeon RX 6700 XT), HUDManager.DrawHUD
-- Speed-up:    ~40% (Ryzen 7 7800X3D, Radeon RX 6700 XT), keyhelp.Draw, including keyhelp.Draw patch

-- Cache
local IMATERIAL_SetFloat        = hydrogen.__meta.IMATERIAL.SetFloat
local IMATERIAL_Recompute       = hydrogen.__meta.IMATERIAL.Recompute
local render_PopFilterMag       = render.PopFilterMag
local render_PopFilterMin       = render.PopFilterMin
local render_PushFilterMag      = render.PushFilterMag
local render_PushFilterMin      = render.PushFilterMin
local render_SetScissorRect     = render.SetScissorRect
local surface_DrawCircle        = surface.DrawCircle
local surface_DrawLine          = surface.DrawLine
local surface_DrawOutlinedRect  = surface.DrawOutlinedRect
local surface_DrawTexturedRect  = surface.DrawTexturedRect
local surface_DrawRect          = surface.DrawRect
local surface_SetDrawColor      = surface.SetDrawColor
local surface_SetMaterial       = surface.SetMaterial

local render_UpdateScreenEffectTexture = render.UpdateScreenEffectTexture

local math_Round    = math.Round
local table_copy    = table.Copy
local unpack        = unpack

-- Constants
local COLOR_WHITE           = Color( 255, 255, 255 )
local SHADOW_ALPHA_DARK     = 0.86274509803
local SHADOW_ALPHA_LIGHT    = 0.29411764705
local TEXFILTER_LINEAR      = TEXFILTER.LINEAR

-- Variables
local material_blurscreen   = Material( "pp/blurscreen" )

-- Utility
local function GetShadowAlpha( color )
    return ( ( color.r + color.g + color.b ) > 200 ) and
        math_Round( color.a * SHADOW_ALPHA_DARK ) or
        math_Round( color.a * SHADOW_ALPHA_LIGHT )
end

-- Patch: draw.OutlinedShadowedBox
function mod.patch.draw.OutlinedShadowedBox( x, y, w, h, t, color )
    color = color or COLOR_WHITE

    local alpha = GetShadowAlpha( color or COLOR_WHITE )

    -- Draw shadows
    surface_SetDrawColor( 0, 0, 0, alpha )

    for i = 0, ( t or 1 ) - 1 do
        local xi = x + i
        local yi = y + i
        local wi2 = w - i * 2
        local hi2 = h - i * 2

        surface_DrawOutlinedRect( xi + 2, yi + 2, wi2, hi2 )
        surface_DrawOutlinedRect( xi + 1, yi + 1, wi2, hi2 )
        surface_DrawOutlinedRect( xi + 1, yi + 1, wi2, hi2 )
    end

    surface_SetDrawColor( color.r, color.g, color.b, color.a )

    for i = 0, ( t or 1 ) - 1 do
        surface_DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
    end
end

-- Patch: draw.ShadowedBox
function mod.patch.draw.ShadowedBox( x, y, w, h, color, scale )
    color = color or COLOR_WHITE

    local shift1 = math_Round( scale or 1 )
    local shift2 = shift1 * 2

    local alpha = GetShadowAlpha( color )

    surface_SetDrawColor( 0, 0, 0, alpha )
    surface_DrawRect( x + shift2, y + shift2, w, h )
    surface_DrawRect( x + shift1, y + shift1, w, h )
    surface_DrawRect( x + shift1, y + shift1, w, h )

    surface_SetDrawColor( color.r, color.g, color.b, color.a )
    surface_DrawRect( x, y, w, h )
end

-- Patch: draw.OutlinedShadowedCircle
function mod.patch.draw.OutlinedShadowedCircle( x, y, r, color, scale )
    color = color or COLOR_WHITE

    local shift1 = math_Round( scale or 1 )
    local shift2 = shift1 * 2

    local alpha = GetShadowAlpha( color )
    local Cr, Cg, Cb, Ca = unpack( color )

    surface_DrawCircle( x + shift2, y + shift2, r, Cr, Cg, Cb, alpha )
    surface_DrawCircle( x + shift1, y + shift1, r, Cr, Cg, Cb, alpha )
    surface_DrawCircle( x + shift1, y + shift1, r, Cr, Cg, Cb, alpha )
    surface_DrawCircle( x, y, r, Cr, Cg, Cb, Ca )
end

-- Patch: draw.ShadowedLine
function mod.patch.draw.ShadowedLine( startX, startY, endX, endY, color )
    color = color or COLOR_WHITE

    local alpha = GetShadowAlpha( color )

    surface_SetDrawColor( 0, 0, 0, alpha )
    surface_DrawLine( startX + 2, startY + 2, endX + 2, endY + 2 )
    surface_DrawLine( startX + 1, startY + 1, endX + 1, endY + 1 )
    surface_DrawLine( startX + 1, startY + 1, endX + 1, endY + 1 )

    surface_SetDrawColor( color.r, color.g, color.b, color.a )
    surface_DrawLine(startX, startY, endX, endY, color)
end

-- Patch: draw.ShadowedTexture
function mod.patch.draw.ShadowedTexture( x, y, w, h, material, alpha, color, scale )
    color = color or COLOR_WHITE

    local Sa = GetShadowColor( color )

    local shift_tex_1 = math_Round( scale or 1 )
    local shift_tex_2 = 2 * shift_tex_1

    surface_SetMaterial( material )

    surface_SetDrawColor( 0, 0, 0, Sa )
    surface_DrawTexturedRect( x + shift_tex_2, y + shift_tex_2, w, h )
    surface_DrawTexturedRect( x + shift_tex_1, y + shift_tex_1, w, h )

    surface_SetDrawColor( color.r, color.g, color.b, alpha or 255 )
    surface_DrawTexturedRect( x, y, w, h, material )
end

-- Patch: draw.FilteredTexture
function mod.patch.draw.FilteredTexture( x, y, w, h, material, alpha, color )
    color = color or COLOR_WHITE
    
    render_PushFilterMag( TEXFILTER_LINEAR )
    render_PushFilterMin( TEXFILTER_LINEAR )
        surface_SetDrawColor( color.r, color.g, color.b, alpha or 255 )
        surface_SetMaterial( material )
        surface_DrawTexturedRect( x, y, w, h )
    render_PopFilterMag()
    render_PopFilterMin()
end

local drawFilteredTexture = draw.FilteredTexture

-- Patch: draw.FilteredShadowedTexture
function mod.patch.draw.FilteredShadowedTexture( x, y, w, h, material, alpha, color, scale )
    color = color or COLOR_WHITE

    local Sa = GetShadowAlpha( color )

    local shift_tex_1 = math_Round( scale or 1 )
    local shift_tex_2 = 2 * shift_tex_1

    render_PushFilterMag( TEXFILTER_LINEAR )
    render_PushFilterMin( TEXFILTER_LINEAR )
        surface_SetMaterial( material )

        surface_SetDrawColor( 0, 0, 0, Sa )
        surface_DrawTexturedRect( x + shift_tex_2, y + shift_tex_2, w, h )
        surface_DrawTexturedRect( x + shift_tex_1, y + shift_tex_1, w, h )

        surface_SetDrawColor( color.r, color.g, color.b, alpha or 255 )
        surface_DrawTexturedRect( x, y, w, h )
    render_PopFilterMag()
    render_PopFilterMin()
end

-- Patch: draw.BlurredBox
function mod.patch.draw.BlurredBox( x, y, w, h, fraction )
    fraction = fraction or 1

    surface_SetMaterial( material_blurscreen )
    surface_SetDrawColor( 255, 255, 255, 255 )

    local scrW = ScrW()
    local scrH = ScrH()
    
    local x1 = x + w
    local y1 = h + 2

    for i = 1.65, 5, 1.65 do
        IMATERIAL_SetFloat( material_blurscreen, "$blur", fraction * i )
        IMATERIAL_Recompute( material_blurscreen )

        render_UpdateScreenEffectTexture()

        render_SetScissorRect( x, y, x1, y1, true )
        surface_DrawTexturedRect( 0, 0, scrW, scrH )
        render_SetScissorRect( 0, 0, 0, 0, false )
    end
end


-- Export
return mod