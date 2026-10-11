-- This module implements [[Template:ThrawnDate]] and [[Template:ThrawnNovelStartDate]].
local p = {}

function p.startReasoning()
	local start_date_reasoning =
		"[[Thrawn (novel)|''Thrawn'']] begins in approximately [[16 BBY]] with reasoning as follows. " ..
		"''Thrawn'' establishes that chapter 19 of the novel is set approximately four years after the start of ''Thrawn''. " ..  
		"In Chapter 19, [[Ryder Azadi]] has been recently [[Prisoner|arrested]] and removed as [[governor]] of [[Lothal]], " .. 
		"which " .. mw.getCurrentFrame():expandTemplate{ title = 'Rebels', args = { 'Gathering Forces' } } .. " establishes was " .. 
		"caused by allowing [[Ezra Bridger]]'s [[parent]]s to make broadcasts critical of the [[Galactic Empire]]. " .. 
		"''[[Star Wars Rebels: The Visual Guide]]'' states that Bridger was seven [[Standard year|years]] old " ..
		"when [[Gender|his]] parents were arrested, and ''[[Star Wars: Galactic Atlas]]'' places his [[Reproduction|birth]] " .. 
		"in [[19 BBY]]. Therefore, Azadi's arrest must occur in approximately [[12 BBY]], " ..
		"and by extension so must chapter 19 of ''Thrawn''. " ..
		"Because the novel starts four years before the events of chapter 19, " ..
		"the novel must begin around 16 [['ABY-BBY' dating system|BBY]]."
	return start_date_reasoning
end

function p.StartDateOnly(frame)
	local root = mw.html.create('span')
	root:wikitext("The novel " .. p.startReasoning())
	return tostring(root)
end

return p