local mod = hydrogen.Include()

-- Cache
local MsgC          = MsgC
local SysTime       = SysTime
local debug_getinfo = debug.getinfo
local math_ceil     = math.ceil
local table_insert  = table.insert

-- Constants
local TAG           = "<debug>"

local COLOR_PREFIX  = Color( 192, 223, 255 )
local COLOR_TAG     = Color( 128, 128, 128 )

local COLOR_FATAL   = Color( 255, 0, 0 )
local COLOR_ERROR   = Color( 255, 128, 128 )
local COLOR_WARN    = Color( 255, 255, 128 )
local COLOR_INFO    = Color( 192, 192, 192 )
local COLOR_DEBUG   = Color( 128, 128, 128 )
local COLOR_TRACE   = Color( 255, 128, 255 )

local VERBOSITY_COLOR = {
    COLOR_FATAL,
    COLOR_ERROR,
    COLOR_WARN,
    COLOR_INFO,
    COLOR_DEBUG,
    COLOR_TRACE,
}

local VERBOSITY_TAG = { 'F', 'E', 'W', 'I', 'D', 'T' }

mod.VERBOSITY_NONE  = 0
mod.VERBOSITY_FATAL = 1
mod.VERBOSITY_ERROR = 2
mod.VERBOSITY_WARN  = 3
mod.VERBOSITY_INFO  = 4
mod.VERBOSITY_DEBUG = 5
mod.VERBOSITY_TRACE = 6

-- Variables
mod.__queue = {}
mod.__log = {}

mod.verbosity = mod.VERBOSITY_TRACE

-- Utility
local function format_trace( tag, info )
    return tag .. "::" .. info.name .. "@L" .. info.currentline
end

local function format_trace_ex( tag, info )
    return tag .. "::" .. hydrogen.NameOf( info.source ) .. "@L" .. info.currentline
end

local function to_microseconds( seconds )
    return math_ceil( seconds * 10e6 )
end

-- Functions
function mod.Print( tag, message, verbosity )
    if ( verbosity > mod.verbosity ) then return end

    MsgC(
        COLOR_PREFIX, "H₂",
        COLOR_TAG, VERBOSITY_TAG[ verbosity ], ' ',
        COLOR_PREFIX, tag, ' '
    )
    
    for _, part in ipairs( message ) do
        MsgC( VERBOSITY_COLOR[ verbosity ], tostring( part ) )    
    end

    MsgC( '\n' )
end

local function sub_Fatal( tag, ... ) mod.Print( tag, { ... }, mod.VERBOSITY_FATAL ) end
local function sub_Error( tag, ... ) mod.Print( tag, { ... }, mod.VERBOSITY_ERROR ) end
local function sub_Warn( tag, ... ) mod.Print( tag, { ... }, mod.VERBOSITY_WARN ) end
local function sub_Info( tag, ... ) mod.Print( tag, { ... }, mod.VERBOSITY_INFO ) end
local function sub_Debug( tag, ... ) mod.Print( tag, { ... }, mod.VERBOSITY_DEBUG ) end

local function sub_Trace( tag, ... )
    if ( mod.verbosity < mod.VERBOSITY_TRACE ) then return end
    mod.Print( format_trace( tag, debug_getinfo( 3 ) ), { ... }, mod.VERBOSITY_TRACE )
end

local function sub_TraceEx( tag, depth, ... )
    if ( mod.verbosity < mod.VERBOSITY_TRACE ) then return end
    mod.Print( format_trace_ex( tag, debug_getinfo( 3 + depth ) ), { ... }, mod.VERBOSITY_TRACE )
end

function mod.Fatal( ... ) mod.Print( TAG, { ... }, mod.VERBOSITY_FATAL ) end
function mod.Error( ... ) mod.Print( TAG, { ... }, mod.VERBOSITY_ERROR ) end
function mod.Warn( ... ) mod.Print( TAG, { ... }, mod.VERBOSITY_WARN ) end
function mod.Info( ... ) mod.Print( TAG, { ... }, mod.VERBOSITY_INFO ) end
function mod.Debug( ... ) mod.Print( TAG, { ... }, mod.VERBOSITY_DEBUG ) end

function mod.Time( tag )
    local begin = SysTime()

    return function( logger )
        local duration = to_microseconds( SysTime() - begin )
        logger( '(', tag, ')', " took ", duration, "us" )

        return duration
    end
end

function mod.New( sub )
    local tag = sub.__name

    local log = {
        Fatal = function( ... ) sub_Fatal( tag, ... ) end,
        Error = function( ... ) sub_Error( tag, ... ) end,
        Warn = function( ... ) sub_Warn( tag, ... ) end,
        Info = function( ... ) sub_Info( tag, ... ) end,
        Debug = function( ... ) sub_Debug( tag, ... ) end,
        Trace = function( ... ) sub_Trace( tag, ... ) end,
        TraceEx = function( ... ) sub_TraceEx( tag, ... ) end,
    }

    return log
end

-- Export
return mod