es8 = {
	gamestate = "default",
	deleted   = {},
	systems   = {}
}

function es8.hasall(entity, keys)
	for i, key in ipairs(keys) do
		if entity[key] == nil then
			return false
		end
	end
	return true
end

function es8.system(required)
	return {
		entities = {},
		required = required or nil
	}
end

function es8:addsystem(name, system, gamestate)
	system.name = name
	system.gamestate = gamestate or "default"
	add(self.systems, system)
end

function es8:getsystem(name)
	for system in all(self.systems) do
		if (system.gamestate == self.gamestate or system.gamestate == "all") and system.name == name then
			return system
		end
	end
	return nil
end

function es8:addentity(entity)
	for system in all(self.systems) do
		if (system.gamestate == self.gamestate or system.gamestate == "all") and system.required and es8.hasall(entity, system.required) then
			add(system.entities, entity)
		end
	end
end

function es8:delentity(entity)
	add(self.deleted, entity)
end

function es8:init()
	for system in all(self.systems) do
		if (system.gamestate == self.gamestate or system.gamestate == "all") and system.init then
			system:init()
		end
	end
end

function es8:update()
	for system in all(self.systems) do
		if (system.gamestate == self.gamestate or system.gamestate == "all") and system.update then
			system:update()
		end
	end
	for deleted in all(self.deleted) do
		for system in all(self.systems) do
			del(system.entities, deleted)
		end
	end
	for d = 1, #self.deleted do
		deli(self.deleted, 1)
	end
end

function es8:draw()
	for system in all(self.systems) do
		if (system.gamestate == self.gamestate or system.gamestate == "all") and system.draw then
			system:draw()
		end
	end
end

function es8:ask(name, msg, info)
	for system in all(self.systems) do
		if (system.gamestate == self.gamestate or system.gamestate == "all") and system.name == name then
			return system:ask(msg, info)
		end
	end
	return nil
end

function es8:clear()
	for system in all(self.systems) do
		if system.gamestate == self.gamestate or system.gamestate == "all" then
			if system.clear then
				system:clear()
			end
			for e = 1, #system.entities do
				deli(system.entities, 1)
			end
		end
	end
end

function es8:reset()
	self:clear()
	self:init()
end

function es8:setgamestate(gamestate)
	self:clear()
	self.gamestate = gamestate
	self:init()
end

function es8:printinfo(x, y, color)
	print("memory: "..stat(0).." cpu: "..stat(1), x, y, color or 11)
	i = 1
	for system in all(self.systems) do
		if system.gamestate == self.gamestate or system.gamestate == "all" then
			if system.entities and #system.entities > 0 then
				print((system.name or tostring(system))..": "..(#system.entities).." ent", x, y + i * 8, color or 11)
			else
				print((system.name or tostring(system))..": no ent", x, y + i * 8, color or 11)
			end
			i += 1
		end
	end
end