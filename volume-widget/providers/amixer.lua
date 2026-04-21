local pactl = require("awesome-wm-widgets.volume-widget.providers.pactl")

local amixer = {}
setmetatable(amixer, { __index = pactl })

function amixer:get_volume_cmd()
    return string.format("amixer -D %s -c %d sget %s", self.device, self.card, self.mixctrl)
end

function amixer:inc_volume_cmd(s)
    return string.format("amixer -D %s -c %d sset %s %d%%+", self.device, self.card, self.mixctrl, s or self.step)
end

function amixer:dec_volume_cmd(s)
    return string.format("amixer -D %s -c %d sset %s %d%%-", self.device, self.card, self.mixctrl, s or self.step)
end

function amixer:tog_volume_cmd()
    return string.format("amixer -D %s -c %d sset %s toggle", self.device, self.card, self.mixctrl)
end

function amixer:parse_volume_cmd(stdout)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume_level = string.match(stdout, "(%d?%d?%d)%%")
    return tonumber(volume_level), mute == "off"
end

function amixer.new(args)
    local self = pactl.new(args) -- initializes step
    self.card = args.card or 0
    self.device = args.device or 'pulse'
    self.mixctrl = args.mixctrl or 'Master'

    return setmetatable(self, { __index = amixer })
end

return amixer
