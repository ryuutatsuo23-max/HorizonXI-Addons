-- Synthetic addon lifecycle: no character files or game client required.
local function noop() end
T = function(value) return value end
addon = {}
local events, callback, loaded, renders = {}, nil, nil, 0
ashita = { events = { register = function(event, _, fn) events[event] = fn end } }
package.loaded.common = {}
package.loaded.chat = {}
package.loaded.imgui = {}
package.loaded.settings = {
    load = function(defaults)
        defaults.visible = true -- Simulate a previous session saved open.
        loaded = defaults
        return defaults
    end,
    register = function(_, _, fn) callback = fn end,
    save = function() callback(loaded) end,
}
package.loaded.catalog = { empty_snapshot = function() return {} end,
    build_snapshot = function() return {} end }
package.loaded.skill_levels = { empty_snapshot = noop, build_snapshot = noop }
package.loaded.crafting = { build_snapshot = noop }
package.loaded.horizon_profile = {}
package.loaded.exporter = {}
package.loaded.outpost_diagnostic = { clear = noop }
package.loaded.key_item_state = { load_cache = noop }
package.loaded.quest_state = { load_area_cache = noop }
package.loaded.mission_state = { load_area_cache = noop }
package.loaded.checklist_ui = { render = function() renders = renders + 1 end }
string.args = function(value)
    local result = {}
    for word in value:gmatch('%S+') do result[#result + 1] = word end
    return result
end
string.any = function(value, ...)
    for _, candidate in ipairs({...}) do if value == candidate then return true end end
    return false
end
dofile('HXIChecklist/HXIChecklist.lua')
local function expect_visible(expected)
    local before = renders
    events.d3d_present()
    assert((renders > before) == expected)
    assert(loaded.visible == expected)
end
local function settings_update(saved_visible)
    loaded = { visible = saved_visible, manual_completed = { sentinel = true } }
    callback(loaded)
    assert(loaded.manual_completed.sentinel == true)
end
expect_visible(false)
settings_update(true) -- Delayed character settings must not reopen the window.
expect_visible(false)
events.command({ command = '/hc show' })
expect_visible(true)
settings_update(false) -- Preserve this session's explicit show choice.
expect_visible(true)
events.command({ command = '/hc hide' })
expect_visible(false)
settings_update(true)
expect_visible(false)
events.command({ command = '/hc' })
expect_visible(true)
events.command({ command = '/hc' })
expect_visible(false)
print('PASS startup visibility and settings updates')
