local p = {}

local function strip(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

local formatting = {
	["Andor: Season 2 - "] = "''Andor'': Season 2 - ",
	["Star Wars: Visions – "] = "''Star Wars: Visions'' – ",
	["Star Wars: Visions Vol. 2 – "] = "''Star Wars: Visions Vol. 2'' – ",
	["The Mandalorian: Chapter"] = "''The Mandalorian'': Chapter"
}

local function decideFormatting(base)
	for k, v in pairs(formatting) do
		if base:sub(0, #k) == k then
			return v..base:sub(#k)
		end
	end
	if base:gsub('–', '-'):find(' . Vol%. %d %(') then
		local f1, f2 = base:gsub('–', '-'):find(' . Vol%. %d %(')
		return "''"..base:sub(0, f1).."''"..base:sub(f1)
	end
	if base:find('[:,] Vol%. %d %(') then
		local f1, f2 = base:match('^(.*)([:,] Vol%. %d %(.*)$')
		return "''"..f1.."''"..f2
	end
	if base:find(' %(') then
		local f1, f2 = base:match('^(.*)%s*%((.-)%)$')
		return "''"..f1.."''"..f2
	end
	return "''"..base.."''"
end

function p.citation(target)
	if target == nil then
		return ""
	elseif not target:find(' %(') then
		return "''[["..target.."]]''"
	end
	
	local base, paren = target:match('^(.*)%s*%((.-)%)$')
	if base:find(' %(') then
		paren = "<small>&#91;"..paren.."&#93;</small>"
	elseif paren:find('Original Music from ') then
		paren = "<small>(Original Music from ''"..paren:sub(20).."'')</small>"
	else
		paren = "<small>("..paren..")</small>"
	end
	base = strip(base)
	
	local fmt = decideFormatting(base)
	return string.format("[[%s|%s %s]]", target, fmt, paren)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame.args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p.citation(args.target)
end

return p