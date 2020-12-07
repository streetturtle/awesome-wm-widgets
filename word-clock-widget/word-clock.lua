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

local function split(string_to_split, separator)
    if separator == nil then separator = "%s" end
    local t = {}

    for str in string.gmatch(string_to_split, "([^".. separator .."]+)") do
        table.insert(t, str)
    end

    return t
end

local function convertNumberToName(num)
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

local function worker(user_args)

    local args = user_args or {}

    local main_color = args.main_color or beautiful.fg_normal
    local accent_color = args.accent_color or beautiful.fg_urgent
    local font = args.font or beautiful.font
    local is_human_readable = args.is_human_readable
    local military_time = args.military_time
    local with_spaces = args.with_spaces

    if military_time == nil then military_time = false end
    if with_spaces == nil then with_spaces = false end
    if is_human_readable == nil then is_human_readable = false end

    text_clock = wibox.widget {
        {
            id = 'clock',
            font = font,
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.align.horizontal,
        set_text = function(self, time)
            local t = split(time)
            local res = ''
            for i, v in ipairs(t) do
                res = res .. '<span color="'
                .. ((i % 2 == 0) and accent_color or main_color)
                .. '">' .. v .. '</span>'
                .. (with_spaces and ' ' or '')
            end
            self:get_children_by_id('clock')[1]:set_markup(res)
        end
    }

    gears.timer {
        timeout   = 1,
        call_now  = true,
        autostart = true,
        callback  = function()
            local time = os.date((military_time and '%H' or '%I') ..  ':%M')
            local h,m = time:match('(%d+):(%d+)')
            local min = tonumber(m)
            local hour = tonumber(h)

            if is_human_readable then

                if min == 0 then
                    text_clock:set_text(convertNumberToName(hour) .. " o'clock")
                else
                    local mm
                    if min == 15 or min == 45 then
                        mm = 'quater'
                    elseif min == 30 then
                        mm = 'half'
                    else
                        mm = convertNumberToName((min < 31) and min or 60 - min)
                    end

                    local to_past

                    if min < 31 then
                        to_past = 'past'
                    else
                        to_past = 'to'
                        hour = hour + 1
                    end

                    text_clock:set_text(mm .. ' ' .. to_past .. ' ' .. convertNumberToName(hour))
                end
            else
                text_clock:set_text(convertNumberToName(hour) .. ' ' .. convertNumberToName(min))
            end
        end
    }

    return text_clock

end

return setmetatable(text_clock, { __call = function(_, ...)
    return worker(...)
end })