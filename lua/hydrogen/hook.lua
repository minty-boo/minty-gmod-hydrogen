local mod = hydrogen.Include()

-- Variables
local meta = {}

-- Meta: hook
function meta.__index( self, k )
    -- Exists in meta-table?
    if meta[ k ] then return meta[ k ] end

    -- Exists in hooks table?
    if self.__hook[ k ] then return self.__hook[ k ] end
end

function meta.__newindex( self, k, v )
    local id = ( k .. '.' .. self.__id .. '@' .. self.__name )
    self.__id = self.__id + 1

    self.__hook[ id ] = { k, v }
end

function meta.Register( self )
    if self.__active then self:Unregister() end

    for k, v in pairs( self.__hook ) do
        hook.Add( v[ 1 ], k, v[ 2 ] )
        mod.debug.Debug( "Created hook '", k, "'" )
    end

    self.__active = true
end

function meta.Unregister( self )
    if not self.__active then return end

    for k, v in pairs( self.__hook ) do
        hook.Remove( v[ 1 ], k )
        mod.debug.Debug( "Removed hook '", k,  "'" )
    end

    self.__active = true
end

-- Functions
function mod.New( sub )
    local new = {
        __name = sub.__name,
        __id = 1,
        __active = false,
        __hook = {},
    }

    return setmetatable( new, meta )
end

-- Export
return mod