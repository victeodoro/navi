--- @sync entry
-- Same behaviour as the official yazi-rs smart-enter plugin:
-- Enter goes into a folder, and opens anything else.
local function entry()
	local h = cx.active.current.hovered
	ya.emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
end

return { entry = entry }
