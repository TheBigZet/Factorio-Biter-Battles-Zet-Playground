local Public = {}

function Public.element_style(options)
	local element = options.element
	element.style.width = options.x
	element.style.height = options.y
	element.style.padding = options.pad
end

--[[
Function returning:
"[color = r, g, b] input [/color]" for input = LuaString and color = {r =_, g = _, b = _} (As it is in color library)
"[color = player.color] player.name [/color]" for input = LuaPlayer (color will be dimmed as it is in feeding messages)
]]
function Public.colored_text(input, color)
	if input.object_name == "LuaPlayer" then
		return table.concat({"[color=", input.color.r * 0.6 + 0.35, ",", input.color.g * 0.6 + 0.35, ",", input.color.b * 0.6 + 0.35, "]", input.name, "[/color]"})
	else
		return table.concat({"[color=", color.r, ",", color.g, ",", color.b, "]", input, "[/color]"})
	end
end
return Public

