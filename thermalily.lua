OUTPUT_SIDE = "left"
INPUT_SIDE = "right"

local current_timer = 0

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
        local event = os.pullEventRaw()
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
                os.queueEvent("cooldown", delay, os.time())
            end
        elseif event_type == "timer" then
            local event_id = event[1]
            print("Cooldown over, opening valve...")
            openValve()
            current_timer = 0
        elseif event_type == "terminate" then
            closeValve()
            coroutine.yield()
        end
    end
end

local function cooldownCountdown()
    while true do
        local event, delay, start_time = os.pullEvent("cooldown")
        print(event, " event received: ")
        print("delay: ", delay)
        print("start_time: ", start_time)
        local time_elapsed = 0
        term.setTextColor(colors.white)
        term.write("Thermalily Cooldown: ")
        while time_elapsed <= delay do
            time_elapsed = delay - (os.time() - start_time)
            local time_elapsed_str = time_elapsed .. "s"
            local time_elapsed_str_len = string.len(time_elapsed_str)
            term.setTextColor(colors.blue)
            term.write(time_elapsed_str_len)
            term.setTextColor(colors.white)
            local cur_x, cur_y = term.getCursorPos()
            term.setCursorPos(cur_x - time_elapsed_str_len, cur_y)
        end
    end
end

openValve()

parallel.waitForAny(handleEvents)
print("End of Execution")
