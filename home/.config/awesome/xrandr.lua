--- Separating Multiple Monitor functions as a separeted module (taken from awesome wiki)

local awful     = require("awful")
local naughty   = require("naughty")

-- A path to a fancy icon
local icon_path = ""

-- Get active outputs
local function outputs()
   local outputs = {}
   local xrandr = io.popen("xrandr -q --current")

   if xrandr then
      for line in xrandr:lines() do
         local output = line:match("^([%w-]+) connected ")
         if output then
            outputs[#outputs + 1] = output
         end
      end
      xrandr:close()
   end

   return outputs
end

local function arrange(out)
   -- We need to enumerate all permutations of horizontal outputs.

   local choices  = {}
   local previous = { {} }
   for i = 1, #out do
      -- Find all permutation of length `i`: we take the permutation
      -- of length `i-1` and for each of them, we create new
      -- permutations by adding each output at the end of it if it is
      -- not already present.
      local new = {}
      for _, p in pairs(previous) do
         for _, o in pairs(out) do
            if not awful.util.table.hasitem(p, o) then
               new[#new + 1] = awful.util.table.join(p, {o})
            end
         end
      end
      choices = awful.util.table.join(choices, new)
      previous = new
   end

   return choices
end

-- Build available choices
local function menu()
   local menu = {}
   local out = outputs()
   local choices = arrange(out)

   for _, choice in pairs(choices) do
      local cmd = "xrandr"
      -- Enabled outputs
      for i, o in pairs(choice) do
         cmd = cmd .. " --output " .. o .. " --auto"
         if i > 1 then
            cmd = cmd .. " --right-of " .. choice[i-1]
         end
      end
      -- Disabled outputs
      for _, o in pairs(out) do
         if not awful.util.table.hasitem(choice, o) then
            cmd = cmd .. " --output " .. o .. " --off"
         end
      end

      local label = ""
      if #choice == 1 then
         label = 'Only <span weight="bold">' .. choice[1] .. '</span>'
      else
         for i, o in pairs(choice) do
            if i > 1 then label = label .. " + " end
            label = label .. '<span weight="bold">' .. o .. '</span>'
         end
      end

      menu[#menu + 1] = { label, cmd }
   end

   return menu
end

-- Display xrandr notifications from choices
local state = { cid = nil }

local function naughty_destroy_callback(reason)
  if reason == naughty.notificationClosedReason.expired or
     reason == naughty.notificationClosedReason.dismissedByUser then
    local action = state.index and state.menu[state.index - 1][2]
    if action then
      awful.util.spawn(action, false)
      state.index = nil
    end
  end
end

local function xrandr()
   -- Build the list of choices
   if not state.index then
      state.menu = menu()
      state.index = 1
   end

   -- Select one and display the appropriate notification
   local label, action
   local next  = state.menu[state.index]
   state.index = state.index + 1

   if not next then
      label = "Keep the current configuration"
      state.index = nil
   else
      label, action = unpack(next)
   end
   state.cid = naughty.notify({ text = label,
                                icon = icon_path,
                                timeout = 4,
                                screen = mouse.screen,
                                replaces_id = state.cid,
                                destroy = naughty_destroy_callback}).id
end

return {
   outputs = outputs,
   arrange = arrange,
   menu = menu,
   xrandr = xrandr
}
