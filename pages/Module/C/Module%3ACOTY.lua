local p = {}

function p.votecount(frame)
	local contest = frame.args.contest ~= nil and frame.args.contest or 'Character'
	local year = mw.text.trim(frame.args.year)
	local page = mw.title.new('Star_Wars_' .. contest .. '_of_the_Year_' .. year, 'Wookieepedia')
	local content = page:getContent()
	
	-- remove all comments
    content = string.gsub(content, '<%!%-%-.-%-%->', '' )
    
    -- add string to mark end of sections
    content = content .. '\nEndOfSection'
	content = string.gsub(content, '\n===', '\nEndOfSection\n===')
	
	local nominees = {}
	local name, i, w
	local result = ''
	local limit = frame.args.limit ~= nil and tonumber(mw.text.trim(frame.args.limit)) or 50
	
	-- get nominee data
	for w in string.gfind(content, '===.-===.-EndOfSection') do
		-- get name
		_, _, name = string.find(w, '===(.-)===')
		-- remove bold
		name = string.gsub(name, "'''", '')
		-- remove {{C}}
		name = string.gsub(name, '{{C.-}}', '')
		-- remove unnecessary whitespace
		name = mw.text.trim(name)
		-- count votes
		i = select(2, string.gsub(w,'\n#[^#:%*][^\n]', ''))
		
		table.insert(nominees, {name, i})
	end
	
	-- sort by votes
	table.sort(nominees, function(a,b) return (a[2] > b[2]) or ((a[2] == b[2]) and (a[1] < b[1])) end)

	if limit < table.maxn(nominees) then
		result = result .. 'Top ' .. limit .. ' nominees'
	end
	
	i = 0
	for _, w in ipairs(nominees) do
		result = result .. '\n#' .. w[1] .. ': ' .. w[2] .. string.format(' vote%s', w[2]==1 and '' or 's')
		i = i + 1
		if i >= limit then
			break
		end
	end
	
	return result
end

return p