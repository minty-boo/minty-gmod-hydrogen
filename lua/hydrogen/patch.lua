local mod = hydrogen.Include()

-- Variables
local meta = {
    null = {},
    patch = {},
    shim = {},
}

-- Utility
local function get_key_name( name, k )
    if name then return name .. '.' .. k end
    return k
end

-- Meta: null
local null = setmetatable( { __null = true }, meta.null )

function meta.null.__index( self, _ ) return null end
function meta.null.__newindex( self, _, _ ) end

-- Meta: patch
function meta.patch.__index( self, k )
    -- Trying to get patched function?
    if ( k == "__func" ) then k = 3 end

    -- Exists as sub-patch?
    if self.__patch[ k ] then return self.__patch[ k ] end
    
    -- Exists in meta-table?
    if meta.patch[ k ] then return meta.patch[ k ] end

    local name = ( self.__name and ( self.__name .. '.' .. k ) or k )
    local target = ( self.__table and self.__table[ k ] or ( _G[ k ] or hydrogen.__meta[ k ] ) )
    local Tt = type( target )

    -- Ensure target table exists
    if ( Tt ~= "table" ) then
        mod.debug.Warn( "Invalid target table '" .. name .. "', got '" .. Tt .. "'" )
        mod.debug.TraceEx( 1, '^' )

        return null
    end
    
    -- Create child patch
    local child = meta.patch.New( name, self, target )
    rawset( self.__patch, k, child )

    return child
end

function meta.patch.__newindex( self, k, v )
    local name      = ( self.__name and ( self.__name .. '.' .. k ) or k )
    local table     = ( self.__table or _G )
    local target    = table[ k ]

    -- Ensure target exists
    if not target then
        mod.debug.Warn( "Invalid target: " .. k )
        mod.debug.TraceEx( 1, '^' )

        return
    end

    -- Ensure type match
    local Tt = type( target )
    local Tv = type( v )

    if ( Tt ~= Tv ) then
        mod.debug.Warn( "Type mismatch for target '" .. name .. "', expected '", Tt, "' got '", Tv, "'" )
        mod.debug.TraceEx( 1, '^' )

        return
    end

    -- Register patch
    if ( Tv == "function" ) then
        v = setfenv( v, setmetatable( { [ "_" ] = target }, { __index = _G } ) )
    end

    self.__patch[ k ] = { table, target, v, name }
end

function meta.patch.Patch( self )
    if self.__active then self:Unpatch() end

    for k, v in pairs( self.__patch ) do
        if v.__patch then
            v:Patch()
        else
            mod.debug.Info( "Patched '", get_key_name( self.__name, k ), "', ", tostring( v[ 1 ][ k ] ), " -> ", tostring( v[ 3 ] ) )
            v[ 1 ][ k ] = v[ 3 ]
        end
    end

    self.__active = true
end

function meta.patch.Unpatch( self )
    if not self.__active then return end

    for k, v in pairs( self.__patch ) do
        if v.__patch then
            v:Unpatch()
        else
            mod.debug.Info( "Unpatched '", get_key_name( self.__name, k ), "', ", tostring( v[ 1 ][ k ] ), " -> ", tostring( v[ 2 ] ) )
            v[ 1 ][ k ] = v[ 2 ]
        end
    end

    self.__active = false
end

function meta.patch.New( name, super, table )
    local new = {
        __name = name,
        __super = super,
        __table = table,

        __active = false,
        __patch = {},
    }

    return setmetatable( new, meta.patch )
end

-- Functions
function mod.New() return meta.patch.New( false, false, false ) end

-- Export
return mod