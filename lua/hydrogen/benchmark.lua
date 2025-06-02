local mod = hydrogen.Include()

-- Cache
local RealFrameTime = RealFrameTime
local math_Round    = math.Round
local timer_Simple  = timer.Simple
local unpack        = unpack

-- Constants
local DEFAULT_COUNT     = 4096
local DEFAULT_DURATION  = 10
local BENCHMARK_WAIT    = 0.5

-- Variables
local busy              = false

local framerate_average = 0
local framerate_timer   = 0

local sound_bell        = Sound( "buttons/bell1.wav" )
local sound_start       = Sound( "buttons/button1.wav" )

-- Utility
local function play_bell()
    local ply = LocalPlayer()
    if IsValid( ply ) then ply:EmitSound( sound_bell, 45 ) end
end

local function play_start()
    local ply = LocalPlayer()
    if IsValid( ply ) then ply:EmitSound( sound_start, 45 ) end
end

-- Functions
function mod.Patch( patch, count, ... )
    if busy then return end
    busy = true

    count = count or DEFAULT_COUNT

    local arg = { ... }

    local a = patch[ 2 ]
    local b = patch[ 3 ]
    local c = {}

    play_start()
    mod.debug.Info( "Benchmarking '", patch[ 4 ], "', ", count, " passes" )

    timer_Simple( BENCHMARK_WAIT, function() 
        local Ta = hydrogen.debug.Time( "original" )
        for i = 1, count do
            c[ i ] = a( unpack( arg ) )
        end
        Ta = Ta( mod.debug.Info )
        mod.debug.Info( "Average time: ", math_Round( Ta / count ), "us"  )

        timer_Simple( BENCHMARK_WAIT + Ta * 10e-9, function()
            local Tb = hydrogen.debug.Time( "patched" )
            for i = 1, count do
                c[ i ] = b( unpack( arg ) )
            end
            Tb = Tb( mod.debug.Info )
            mod.debug.Info( "Average time: ", math_Round( Tb / count ), "us"  )

            mod.debug.Info( "Speed-up: ", math_Round( Ta / Tb, 2 ), 'x' )
            busy = false

            play_bell()
        end )
    end )
end

function mod.Function( fn, count, ... )
    if busy then return end
    busy = true

    count = count or DEFAULT_COUNT

    local arg = { ... }
    local _ = {}

    play_start()
    mod.debug.Info( "Benchmarking '", fn, "', ", count, " passes" )

    timer_Simple( BENCHMARK_WAIT, function() 
        local t = hydrogen.debug.Time( "call" )
        for i = 1, count do
            _[ i ] = fn( unpack( arg ) )
        end
        t = t( mod.debug.Info )
        mod.debug.Info( "Average time: ", math_Round( t / count ), "us"  )

        busy = false
        play_bell()
    end )
end

function mod.Framerate( duration )
    if busy then return end
    busy = true

    duration = duration or DEFAULT_DURATION
    
    play_start()
    mod.debug.Info( "Starting framerate measurement for ", duration, " seconds" )

    framerate_average = 0
    framerate_timer = CurTime() + duration
end

-- Hooks
function mod.hook.Think()
    -- Framerate measurement
    if ( framerate_timer > 0 ) then
        local fps = 1 / RealFrameTime()
        framerate_average = ( ( framerate_average > 0 ) and ( ( framerate_average + fps ) / 2 ) or fps )

        if ( framerate_timer < CurTime() ) then
            framerate_timer = 0
            fps = math_Round( framerate_average, 1 )

            mod.debug.Info( "Average framerate: ", fps, " FPS" )
            busy = false

            play_bell()
        end
    end
end

-- Export
return mod