OUTPUT_SIDE = "left"
INPUT_SIDE = "right"


local current_timer = 0
local pullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

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

local function handleEvents()
    while true do
        local event = os.pullEvent()
        local event_type = event[0] or event

        if event_type == "redstone" then
            print("Redstone signal changed.")
            local thermalilySignal = redstone.getAnalogInput("right")
            print("Thermalily signal: ", thermalilySignal)
            if thermalilySignal == 0 then
                print("Thermalily Active.")
                closeValve()
            else
                if current_timer ~= 0 then
                    os.cancelTimer(current_timer)
                end
                local delay = (20 * thermalilySignal) + 5
                print("Waiting", delay.."s", "cooldown...")
                current_timer = os.startTimer(delay)
                os.queueEvent("cooldown", delay, os.clock())
            end
        elseif event_type == "timer" then
            local event_id = event[1]
            print("Cooldown over, opening valve...")
            openValve()
            current_timer = 0
        elseif event_type == "terminate" then
            closeValve()
            os.pullEvent = pullEvent
            os.queueEvent("terminate")
        end
    end
end

local function cooldownCountdown()
    while true do
        local event, delay, start_time = os.pullEvent("cooldown")
        print(event, "event received: ")
        print("delay:", delay)
        print("start_time:", start_time)
        local time_remaining = 1
        term.setTextColor(colors.white)
        while time_remaining > 0 do
            local current_time = os.clock()
            local time_elapsed = current_time - start_time
            time_remaining = math.floor(delay - time_elapsed)
            local time_remaining_str = time_remaining .. "s"
            term.setTextColor(colors.blue)
            term.write("Thermalily Cooldown: "..time_remaining_str.." (Press any key to update)")
            term.setTextColor(colors.white)
            local cur_x, cur_y = term.getCursorPos()
            term.setCursorPos(1, cur_y)
            coroutine.yield()
        end
    end
end

openValve()

parallel.waitForAny(handleEvents, cooldownCountdown)
print("End of Execution")