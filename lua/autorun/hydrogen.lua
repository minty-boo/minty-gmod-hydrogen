AddCSLuaFile()

-- Global table
hydrogen = hydrogen or {
    __active = false,
    __post = false,

    init = {},

    shared = {},
    server = {},
    client = {},
}

-- Registered meta-tables
hydrogen.__meta = {
    ANGLE       = FindMetaTable( "Angle" ),
    COLOR       = FindMetaTable( "Color" ),
    ENTITY      = FindMetaTable( "Entity" ),
    IMATERIAL   = FindMetaTable( "IMaterial" ),
    PANEL       = FindMetaTable( "Panel" ),
    PHYSOBJ     = FindMetaTable( "PhysObj" ),
    PLAYER      = FindMetaTable( "Player" ),
    VECTOR      = FindMetaTable( "Vector" ),
    WEAPON      = FindMetaTable( "Weapon" ),
}

-- Unload if already loaded
if hydrogen.__active then hydrogen.init.Unload() end

-- Cache
local debug_getinfo = debug.getinfo
local file_Find     = file.Find
local string_find   = string.find
local string_sub    = string.sub
local table_Copy    = table.Copy

-- Constants
local TAG           = "Hydrogen"

local LUA_ROOT      = "hydrogen"
local LUA_REALMS    = { "shared", "server", "client" }
local LUA_INCLUDES  = { "debug", "hook", "patch", "benchmark" }

local REALM_SHARED  = 1
local REALM_SERVER  = 2
local REALM_CLIENT  = 3

-- Variables
local meta = {
    mod = {},
}

-- Utility
local function path_combine( ... )
    local args = { ... }
    local path = nil

    for _, arg in ipairs( args ) do
        path = path and ( path .. '/' .. arg ) or arg
    end

    return path
end

local function remove_extension( name )
    for i = #name, 1, -1 do
        if ( name[ i ] == '.' ) then
            return string_sub( name, 1, i - 1 )
        end
    end

    return name
end

local function remove_root( path )
    local _, stop = string_find( path, LUA_ROOT .. '/' )
    if not stop then return path end

    return string_sub( path, stop + 1 )
end

local function remove_root_ext( path )
    local _, stop = string_find( path, "lua/" .. LUA_ROOT .. '/' )
    if not stop then return path end

    return string_sub( path, stop + 1 )
end

local function remove_realm( path )
    local sub = remove_root( path )
    if ( sub == path ) then return sub end

    return string_sub( sub, 8 )
end

local function debug_get_name()
    return remove_extension( remove_root_ext( debug_getinfo( 3 ).source  ) )
end

local function get_gamemode( path )
    local sub = remove_realm( path )
    local start, stop = string_find( sub, "gamemodes/" )

    if ( start == 1 ) then
        for i = ( stop + 1 ), #sub do
            if ( sub[ i ] == '/' ) then
                return string_sub( sub, stop + 1, i - 1 )
            end
        end
    end

    return false
end

local function should_include( realm )
    if ( realm == REALM_SHARED ) then return true end
    if ( realm == REALM_SERVER ) and SERVER then return true end
    if ( realm == REALM_CLIENT ) and CLIENT then return true end

    return false
end

local function should_upload( realm )
    if ( realm == REALM_SHARED ) then return true end
    if ( realm == REALM_CLIENT ) then return true end

    return false
end

-- Functions
function hydrogen.NameOf( path )
    return remove_extension( remove_root( path ) )
end

-- Meta: mod
function meta.mod.__index( self, k )
    -- Exists in meta-table?
    if meta.mod[ k ] then return meta.mod[ k ] end
end

-- Modules
function hydrogen.Include()
    local mod = { __name = '<' .. debug_get_name() .. '>' }
    if hydrogen.debug then mod.debug = hydrogen.debug.New( mod ) end
    if hydrogen.hook then mod.hook = hydrogen.hook.New( mod ) end

    return mod
end

function hydrogen.Module()
    local mod = {
        __name = debug_get_name(),
    }

    mod.debug = hydrogen.debug.New( mod )
    mod.patch = hydrogen.patch.New( mod )
    mod.hook = hydrogen.hook.New( mod )

    mod = setmetatable( mod, meta.mod )

    return mod
end

-- Initialisation
function hydrogen.init.File( path, realm )
    local gamemode = get_gamemode( path )

    if gamemode and ( gamemode ~= hydrogen.__gamemode ) then
        hydrogen.debug.Debug( "Skipping '", remove_root( path ), "'" )
        return
    end

    if should_upload( realm ) then AddCSLuaFile( path ) end
    if not should_include( realm ) then return nil end

    return include( path )
end

function hydrogen.init.Folder( path, realm, context )
    if ( realm == REALM_SERVER ) and not SERVER then return end

    context = context or {}
    local search_path   = path_combine( LUA_ROOT, path )

    -- Search
    local files, _      = file_Find( path_combine( search_path, "*.lua" ), "LUA" )
    local _, folders    = file_Find( path_combine( search_path, "*" ), "LUA" )

    -- Register files
    for _, file_name in ipairs( files ) do
        local file_path = path_combine( search_path, file_name )
        local mod = hydrogen.init.File( file_path, realm )

        local name = remove_extension( remove_realm( file_path ) )

        if mod then context[ name ] = mod end
    end

    -- Register folders
    for _, folder_name in ipairs( folders ) do
        local folder_path = path_combine( path, folder_name )
        local name = remove_extension( remove_realm( folder_path ) )

        hydrogen.init.Folder( folder_path, realm, context )
    end

    return context
end

function hydrogen.init.Includes()
    -- Register includes
    for _, name in ipairs( LUA_INCLUDES ) do
        local file_path = path_combine( LUA_ROOT, name ) .. ".lua"

        hydrogen[ name ] = nil
        hydrogen[ name ] = hydrogen.init.File( file_path, REALM_SHARED )
    end
end

function hydrogen.init.Modules()
    local time = hydrogen.debug.Time( "modules" )

    -- Register modules
    for realm, name in ipairs( LUA_REALMS ) do
        local mod = hydrogen.init.Folder( name, realm )
        hydrogen[ name ] = mod
    end

    -- Print time taken
    time( hydrogen.debug.Debug )
end

function hydrogen.init.Register()
    hydrogen.init.Includes()
    hydrogen.init.Modules()
end

function hydrogen.init.Hook()
    hydrogen.benchmark.hook:Register()
    for _, v in pairs( hydrogen.shared ) do v.hook:Register() end
    if SERVER then for _, v in pairs( hydrogen.server ) do v.hook:Register() end end
    if CLIENT then for _, v in pairs( hydrogen.client ) do v.hook:Register() end end
end

function hydrogen.init.Unhook()
    hydrogen.benchmark.hook:Unregister()
    for _, v in pairs( hydrogen.shared ) do v.hook:Unregister() end
    if SERVER then for _, v in pairs( hydrogen.server ) do v.hook:Unregister() end end
    if CLIENT then for _, v in pairs( hydrogen.client ) do v.hook:Unregister() end end
end

function hydrogen.init.Patch()
    for _, v in pairs( hydrogen.shared ) do
        local time = hydrogen.debug.Time( "patch::" .. v.__name )
        v.patch:Patch()
        time( hydrogen.debug.Debug )
    end

    if SERVER then
        for _, v in pairs( hydrogen.server ) do
            local time = hydrogen.debug.Time( "patch::" .. v.__name )
            v.patch:Patch()
            time( hydrogen.debug.Debug )
        end
    end

    if CLIENT then
        for k, v in pairs( hydrogen.client ) do
            local time = hydrogen.debug.Time( "patch::" .. v.__name )
            v.patch:Patch()
            time( hydrogen.debug.Debug )
        end
    end
end

function hydrogen.init.Unpatch()
    for _, v in pairs( hydrogen.shared ) do
        local time = hydrogen.debug.Time( "unpatch::" .. v.__name )
        v.patch:Unpatch()
        time( hydrogen.debug.Debug )
    end

    if SERVER then
        for _, v in pairs( hydrogen.server ) do
            local time = hydrogen.debug.Time( "unpatch::" .. v.__name )
            v.patch:Unpatch()
            time( hydrogen.debug.Debug )
        end
    end

    if CLIENT then
        for _, v in pairs( hydrogen.client ) do
            local time = hydrogen.debug.Time( "unpatch::" .. v.__name )
            v.patch:Unpatch()
            time( hydrogen.debug.Debug )
        end
    end
end

-- Loading
function hydrogen.init.Load()
    if hydrogen.__active then hydrogen.init.Unload() end

    hydrogen.__gamemode = gmod.GetGamemode().FolderName

    hydrogen.init.Register()
    hydrogen.init.Patch()
    hydrogen.init.Hook()

    hydrogen.__active = true
    hydrogen.__post = true
end

function hydrogen.init.Unload()
    if not hydrogen.__active then return end

    hydrogen.init.Unpatch()
    hydrogen.init.Unhook()

    hydrogen.shared = {}
    hydrogen.server = {}
    hydrogen.client = {}

    hydrogen.__active = false
end

-- Debug
hook.Remove( "InitPostEntity", TAG .. "StorePost" )
hook.Add( "InitPostEntity", TAG .. "StorePost", function()
    hydrogen.__post = true
    hydrogen.init.Load()
end )

if hydrogen.__post then hydrogen.init.Load() end