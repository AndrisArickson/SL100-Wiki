local p = {}

local legends = {
	["Battle of the Sith Lords"] = 1, 
	["Jedi: Yoda"] = 1, 
	["Star Wars Detours"] = 1, 
	["Star Wars Galaxies"] = 1, 
	["Star Wars drafts"] = 1, 
	["Star Wars: 1313"] = 1, 
	["Star Wars: Adventures in Hyperspace"] = 1, 
	["Star Wars: Empire at War"] = 1, 
	["Star Wars: Knights of the Old Republic"] = 1, 
	["Star Wars: Knights of the Old Republic II: The Sith Lords"] = 1, 
	["Star Wars: Knights of the Old Republic 3"] = 1, 
	["Star Wars: The Old Republic"] = 1, 
	["Star Wars: Tiny Death Star"] = 1, 
	["The Epic Continues"] = 1, 
	["The Star Wars Holiday Special"] = 1, 
	["The Unknown Regions"] = 1, 
	["Vernost"] = 1, 
	["Who's Who: Imperial Grand Admirals"] = 1, 
	["Star Wars Adventure Journal"] = 1, 
	["Star Wars Adventure Journal 16‎"] = 1, 
	["Star Wars Adventure Journal 17‎"] = 1, 
	["Emanations of Darkness‎‎"] = 1, 
	["Light and Shadow‎‎"] = 1,
}

function p.main(frame)
	local args = frame:getParent().args
	local target = mw.text.trim(args.page or args[1])
	if legends[target] then
		return "Legends"
	end
	return ""
end

return p