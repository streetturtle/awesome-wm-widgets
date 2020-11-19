-------------------------------------------------
-- Text Clock Widget for Awesome Window Manager
-- Shows current time in words, e.g. 11.54 -> eleven fifty four
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/text-clock-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function convertNumberToName(num)
    num = tonumber(num)
    local lowNames = {"zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
                 "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                  "eighteen", "nineteen"};
    local tensNames = {"twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"}
    local tens, ones, result

    if num < tablelength(lowNames) then
        result = lowNames[num + 1];
    else
        tens = math.floor(num / 10);
        ones = num % 10;
        if (tens <= 9) then
            result = tensNames[tens - 2 + 1];
            if (ones > 0) then
                result =  result .. " " .. lowNames[ones + 1];
            end
        else
            result = "unknown"
        end
    end
    return result;
end

local text_clock = {}

local function worker(args)

    local args = args or {}

    text_clock = wibox.widget {
        {
            id = 'hours',
            font = 'Play 12',
            widget = wibox.widget.textbox,
        },
        {
            id = "minutes",
            font = 'Play 12',
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.align.horizontal,
        set_text = function(self, hours, minutes)
            self:get_children_by_id('hours')[1]:set_text(hours)

            if string.match(minutes, " ") then
                local f,s = minutes:match("(%w+)%s(%w+)")
                self:get_children_by_id('minutes')[1]:set_markup('<span font_weight="bold" color="' .. beautiful.fg_urgent .. '">' .. f .. '</span>' .. s)
            else
                self:get_children_by_id('minutes')[1]:set_markup('<span font_weight="bold"> color="' .. beautiful.fg_urgent .. '">' .. minutes .. '</span>')
              end

        end
    }

    gears.timer {
        timeout   = 1,
        call_now  = true,
        autostart = true,
        callback  = function()
            local time = os.date("%I:%M")
            local h,m = time:match('(%d+):(%d+)')
            local hw = convertNumberToName(h)
            local mw = convertNumberToName(m)
            print(hw)
            print(mw)
            text_clock:set_text(hw, mw)
        end
    }

    return text_clock

end

return setmetatable(text_clock, { __call = function(_, ...)
    return worker(...)
end })