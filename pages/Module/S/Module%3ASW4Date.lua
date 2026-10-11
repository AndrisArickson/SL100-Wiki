-- This module implements [[Template:SW4Date]] and [[Template:SW4Date/Legends]].

-- Find whether the specified page exists. We use pcall to catch errors if we
-- are over the expensive parser function count limit, or a number of other
-- juicy errors. This function increases the expensive parser function count
-- for every new page called.
--local function exists(page)
--	local success, title = pcall(mw.title.new, page)
--	return success and title and title.exists or false
--end

local p = {}

function p._main(args)
	local subpage = args.subpage or args[5]
	local year_num
	local year_given = args.year or args[1]
	local before_after = args.before_after or args[2]
	local before_after_letter = 'B'
	local before_after_word = 'before'
	local event = args.event or args[3]
	local source = args.source or args[4]
	local has_source = false
	local is_legends = args.is_legends
	local param_error = false
	local bby_source = "''[[Star Wars: Galactic Atlas]]''"
	local std_year_pg = 'Standard year'

	local year_pipelink = '[[0 BBY]]'
	local year_fmt

	-- Create the surrounding span.
	local root = mw.html.create('span')

	if source then
		has_source = true
	end

	if event == nil or before_after == nil then
		param_error = true
	end
	
	if year_given then
		year_num = string.gsub(year_given, ',', '')
		year_num = tonumber(year_num)
		if year_num >= 10000 then year_num = year_given end --years with more than five digits have commas
	end
	if year_num == nil then param_error = true end
	
	if (before_after == 'B') or (before_after == 'b') or (before_after == 'Before') or (before_after == 'before') then
		before_after_letter = 'B'
		before_after_word = 'before'
	elseif (before_after == 'A') or (before_after == 'a') or (before_after == 'After') or (before_after == 'after') then
		before_after_letter = 'A'
		before_after_word = 'after'
	else
		param_error = true
	end
	
	if param_error then
	-- Add the tracking category. The function passed to
	-- [[Module:SpecialCategorizer]] is called if the page being processed is
	-- not blacklisted.	
		if mw.title.getCurrentTitle():inNamespace(0) then
			require('Module:SpecialCategorizer')._main(function ()
				-- The category link is split up so that this page isn't categorised.
				root:wikitext('<strong class="error">[[Template:SW4Date]] error: missing or invalid parameters.</strong>' ..
					'[[' .. 'Category:Invalid SW4Date parameter arguments]]')
			end)
		end
		return tostring(root)
	end
	
	if is_legends then
		std_year_pg = 'Standard year/Legends'
		bby_source = "''[[The New Essential Chronology]]''"
	elseif not has_source then
		source = "''[[The Star Wars Book]]''"
		has_source = true
	end
	
	local beginning
	if has_source then
		beginning = source .. ' dates the ' .. event .. ' to '
	else
		beginning = event .. ' is set '
	end

	local relative_str
	if (year_num == 1) then
		relative_str = '1 [[' .. std_year_pg .. '|year]] ' .. before_after_word
	else
		relative_str = year_given .. ' [[' .. std_year_pg .. '|years]] ' .. before_after_word
	end
	
	local middle_str = " the events of [[Star Wars: Episode IV A New Hope|''Star Wars'': Episode IV ''A New Hope'']], which corresponds to "
	
	if before_after_letter == 'B' then 
		year_fmt = year_num .. ' BBY'
	else
		year_fmt = year_num .. ' ABY'
	end
	
	local year_subpage = year_fmt .. '/Canon'
	if is_legends then
		year_subpage = year_fmt .. '/Legends'
	end

	--if exists(year_subpage) then
	if subpage then
		year_pipelink = '[[' .. year_subpage .. '|' .. year_fmt .. ']]'
	else
		year_pipelink = '[[' .. year_fmt .. ']]'
	end
	
	local end_of_text = ' according to ' .. bby_source .. '.'
	
	full_text = beginning .. relative_str .. middle_str .. year_pipelink .. end_of_text

	-- Add the span containing the formed wording.
	root:wikitext(full_text)
	return tostring(root)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	for k, v in pairs(frame.args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

function p.legends(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	for k, v in pairs(frame.args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	args.is_legends = true
	return p._main(args)
end

return p