local mod = hydrogen.Module()

-- Cache
local ENTITY    = hydrogen.__meta.ENTITY
local PLAYER    = hydrogen.__meta.PLAYER
local WEAPON    = hydrogen.__meta.WEAPON

local ENTITY_GetTable = ENTITY.GetTable
local ENTITY_GetOwner = ENTITY.GetOwner

-- Variables
local null = {}

-- Patch: *.__index
-- Speed-up: ~11% (Ryzen 7 7800X3D, Radeon RX 6700 XT)
function mod.patch.ENTITY.__index( self, k )
    if ( k == "Owner" ) then return ENTITY_GetOwner( self ) end
    return ( ENTITY[ k ] or ( ENTITY_GetTable( self ) or null )[ k ] )
end

function mod.patch.PLAYER.__index( self, k )
    if ( k == "Owner" ) then return ENTITY_GetOwner( self ) end
    return ( PLAYER[ k ] or ENTITY[ k ] or ( ENTITY_GetTable( self ) or null )[ k ] )
end

function mod.patch.WEAPON.__index( self, k )
    if ( k == "Owner" ) then return ENTITY_GetOwner( self ) end
    return ( WEAPON[ k ] or ENTITY[ k ] or ( ENTITY_GetTable( self ) or null )[ k ] )
end

-- Export
return mod