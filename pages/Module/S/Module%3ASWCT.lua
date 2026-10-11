local p = {}

local textLookup = require('Module:FormattedTextLookup').render
local pagetitle = mw.title.getCurrentTitle()

local function shouldSkipCategory()
	return pagetitle.namespace == 10 or pagetitle.namespace == 100 or pagetitle.namespace == 2 or pagetitle.namespace % 2 == 1
end

local function wikiLink(l, t)
	return string.format('[[W:c:starwarscardtrader:%s|%s]]', l, t and t or l)
end

local possible = {}
local setsToCheck = {"Masterwork Selects", "Armored & Ready",  "Chrome 2023",  "Chrome Black - 2022",  "Chrome Black 2023",  "Chrome Galaxy - 2022",  "Chrome Galaxy 2023",  "Chrome Legacy - 2021",  "Chrome Perspectives",  "Evolution Lightsaber",  "Evolution Vehicles",  "Evolution",  "Galactic Files 2016",  "Galactic Files 2018",  "Holocron Series - Wave 2",  "Holocron Series - Wave 3",  "Holocron Series",  "Journey to Star Wars: The Last Jedi",  "Journey to The Force Awakens",  "Journey to the Rise of Skywalker - Base",  "Masterwork 2018",  "Signature Series - 2022",  "Solo: A Star Wars Story - Physical Base",  "Star Wars - Masterwork - 2021",  "Star Wars Chrome 2024",  "Star Wars High Tek 2023",  "Star Wars Holocron - Charting the Galaxy",  "Star Wars Holocron Series - The Adventures of Han Solo",  "Star Wars Masterwork - 2020",  "Star Wars: Battle Plans",  "Star Wars: Holocron Series",  "Star Wars: Masterwork - Heroes of the Rebellion",  "Star Wars: Masterwork - The Dark Side",  "Star Wars: Masterwork 2016",  "Star Wars: Masterwork",  "Star Wars: Return of the Jedi - Black & White - Behind the Scenes",  "Star Wars: The Last Jedi - Physical Base - Characters",  "Star Wars: The Last Jedi - Physical Base - Locations",  "Star Wars: The Last Jedi - Physical Base - Scenes",  "Star Wars: The Last Jedi - Physical Base - Vehicles",  "Star Wars: The Last Jedi - Physical Base",  "Star Wars: The Last Jedi - Selects (Series 2)",  "Star Wars: The Last Jedi - Selects",  "Star Wars: The Last Jedi - Ships and Vehicles",  "Star Wars: The Last Jedi",  "Star Wars: The Rise of Skywalker - Crush the Resistance",  "Star Wars: The Rise of Skywalker Series 1 Base",  "Topps Chrome: The Mandalorian - Armored & Ready",  "Topps Finest - 2022 - The Mandalorian",  "Topps Finest - 2022",  "Topps Finest 2019 - Droids",  "Topps Finest 2019 - Rogue One",  "Topps Finest 2019",  "Topps' The Mandalorian - Series 1 - Characters",  "Topps' The Mandalorian - Series 1 - Tools of the Bounty Hunter",  "Topps' Women of Star Wars - Powerful Pairs",  "Topps' Women of Star Wars - The Journey of Leia",  "Topps: Star Wars",  "Topps: The Book of Boba Fett - Season 1",  "Wave 1 - The Mandalorian Legends",  "Wave 2 - The Mandalorian Legends", "Topps Chrome - 2025", 
	"2025 Topps Star Wars Hyperspace", "2025 Star Wars Chrome Sapphire", "Star Wars High Tek 2023",
	"2024 Topps Star Wars Masterwork", "Topps Star Wars Masterwork 2024", "2024 Topps Star Wars Hyperspace", "2024 Topps Star Wars High Tek", "Smuggler's Outpost 2025",
	"2025 Star Wars Chrome Masterwork",	"2026 Topps Chrome Star Wars", "2026 Topps Star Wars Chrome Galaxy", "2025 Topps Star Wars Chrome Galaxy"}

local function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function determineSetText(args)
	local setText = textLookup({type = "Cards", template = "SWCT", prefix = "W:c:starwarscardtrader:", target = args.set, text = args.stext or ''})
	if args.set ~= nil and args.set ~= "" and pagetitle.namespace == 0 and hasValue(possible, args.set) then
		setText = string.format("%s[[Category:SWCT usages with potential physical Topps set|%s]]", setText, pagetitle.text)
	elseif args.set ~= nil and args.set ~= "" and pagetitle.namespace == 0 and hasValue(setsToCheck, args.set) then
		setText = string.format("'''%s'''[[Category:SWCT usages with physical Topps set|%s]]", setText, args.set .. '-' .. pagetitle.text)
	end
	return setText
end
	
function render(args) 
	if args.news and args.link then
		return string.format('(News article: [[W:c:starwarscardtrader:Special:Redirect/file/%s|%s]]', args.link, args.news)
	elseif args.news then
		return args.news
	elseif args.set ~= nil and args.set ~= "" then
		if args.set == "Splash Screen Fun Facts" then
			return wikiLink("Splash Screen Fun Facts", nil)
		elseif args.cardname then
			local txt = {'<span class="pnh">Set: '}
			txt[#txt + 1] = determineSetText(args)
			if args.subset then 
				txt[#txt + 1] = ' - ' .. args.subset
			end
			txt[#txt + 1] = ',</span> Card: '
			
			if args.nolink then
				txt[#txt + 1] = args.cardname
			elseif args.link then
				txt[#txt + 1] = wikiLink(args.link, args.cardname)
			else
				txt[#txt + 1] = wikiLink(args.cardname .. ' - ' .. args.set, args.cardname)
			end
			txt[#txt + 1] = ''
			return table.concat(txt)
		elseif args.nolink then
			return "Set: ''" .. args.set .. "''"
		else
			return "Set: " .. determineSetText(args) .. ''
		end
	elseif pagetitle.namespace == 0 or pagetitle.namespace == 6 then
		return '[[Category:Template usages with missing parameters]]<span style="color: red"><b>No set defined!</b></span>'
	else
		return '<span style="color: red"><b>No set defined!</b></span>'
	end
end

function p._main(args)
	local cardText = "<small class=\"cgct\">"..render(args).."</small>"
	if true then
		cardText = "<span class=\"pnh\">[[Star Wars: Card Trader|''Star Wars'': Card Trader]]</span> "..cardText
	else
		cardText = "<span class=\"pnh\">[[File:ToppsDigitalLogo.png|text-bottom|x15px|link=Topps]] [[Star Wars: Card Trader|''Star Wars'': Card Trader]]</span> "..cardText
	end
	if not (args.cardname or args.news or args.parent) and not shouldSkipCategory() and args.set ~= "Splash Screen Fun Facts" then
		cardText = cardText .. '[[Category:Citation template usages without cardname|' .. pagetitle.text .. ']]'
	end
	return cardText
end

function p.main(frame, ...)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

return p