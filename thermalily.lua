OUTPUT_SIDE = "left"
INPUT_SIDE = "right"


local current_timer = 0
local pullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

local timer_table = {}

local function closeValve()
    term.setTextColor(colors.red)
    print("Closing valve")
    term.setTextColor(colors.white)
    redstone.setOutput(OUTPUT_SIDE, false)
end

local function openValve()
    term.setTextColor(colors.lime)
    print("Opening valve")
    term.setTextColor(colors.white)
    redstone.setOutput(OUTPUT_SIDE, true)
end

local function handleRedstoneEvents()
    while true do
        local event = os.pullEvent("redstone")
        print("Redstone signal changed.")
        local thermalilySignal = redstone.getAnalogInput(INPUT_SIDE)
        print("Thermalily signal: ", thermalilySignal)
        if thermalilySignal == 0 then
            print("Thermalily Active.")
            closeValve()
        else
            if current_timer ~= 0 then
                os.cancelTimer(current_timer)
                timer_table[current_timer] = false
            end
            local delay = (20 * thermalilySignal) + 5
            print("Waiting", delay.."s", "cooldown...")
            current_timer = os.startTimer(delay)
            timer_table[current_timer] = true
            os.queueEvent("cooldown", delay, os.clock())
        end
    end
end

local function handleTimerEvents()
    while true do
        event, id = os.pullEvent("timer")
        if timer_table[id] then
            print("Cooldown over, opening valve...")
            openValve()
            current_timer = 0
            timer_table[id] = false
        end
    end
end

local function handleTerminate()
    os.pullEvent("terminate")
    closeValve()
    os.pullEvent = pullEvent
    os.queueEvent("terminate")
    return
end

local function cooldownCountdown()
    while true do
        local event, delay, start_time = os.pullEvent("cooldown")
        local time_remaining = 1
        term.setTextColor(colors.white)
        while time_remaining > 0 do
            local current_time = os.clock()
            local time_elapsed = current_time - start_time
            time_remaining = math.floor(delay - time_elapsed)
            local time_remaining_str = time_remaining .. "s"
            term.setTextColor(colors.blue)
            term.clearLine()
            term.write("Thermalily Cooldown: "..time_remaining_str)
            term.setTextColor(colors.white)
            local cur_x, cur_y = term.getCursorPos()
            term.setCursorPos(1, cur_y)
            os.startTimer(0.5)
            coroutine.yield()
        end
    end
end

openValve()

parallel.waitForAny(handleRedstoneEvents, handleTimerEvents, handleTerminate, cooldownCountdown)
print("End of Execution")
