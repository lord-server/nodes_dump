-- Removes non-serializable data
local function sanitize_table(t)
	-- Detect mixed tables
	local seen_non_str_keys = false
	local seen_str_keys = false

	for key, _ in pairs(t) do
		if type(key) == 'string' then
			seen_str_keys = true
		else
			seen_non_str_keys = true
		end
	end

	if seen_non_str_keys and seen_str_keys then
		for k in pairs(t) do
			t[k] = nil
		end
		return
	end

	-- Detect non-serializable values
	for key, value in pairs(t) do
		local value_type = type(value)
		if value_type == 'function' or value_type == 'userdata' then
			t[key] = nil
		elseif value_type == 'table' then
			sanitize_table(value)
		end
	end
end

core.after(0, function()
	local game = {}
	game.aliases = table.copy(core.registered_aliases)
	game.nodes = table.copy(core.registered_nodes)
	sanitize_table(game)

	for name, node in pairs(game.nodes) do
		--- @diagnostic disable-next-line: undefined-field не проверялось. Мод живёт давно, порблем не наблюдалось.
		if node.tiles ~= nil and node.tiles.name ~= nil then
			--- @diagnostic disable-next-line: undefined-field не проверялось. Мод живёт давно, порблем не наблюдалось.
			game.nodes[name]["tiles"] = {node["tiles"]["name"]}
		end

		if node.tiles ~= nil then
			for i, tile in ipairs(node.tiles) do
				if type(tile) == "table" then
					node.tiles[i] = tile.name
				end

				if type(tile) ~= "string" and type(tile) ~= "table" then
					node.tiles[i] = nil
				end
			end
		end
	end

	local path = core.get_worldpath() .. "/nodes_dump.json"
	local file = io.open(path, 'wb')
	local json = core.write_json(game, true)
	assertf(file ~= nil, "[nodes_dump] Failed to open file %s for writing", path)
	file--[[@as file]]:write(json--[[@as string]])
	file--[[@as file]]:close()
end)
