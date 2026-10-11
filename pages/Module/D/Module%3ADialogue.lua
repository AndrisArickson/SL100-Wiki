-- <nowiki>
--
-- This module implements [[Template:Dialogue]].

local p = {}

local function makeCategoryLink(cat)
	return string.format('[[Category:%s]]', cat)
end

local function makeWikitextError(msg)
	local ret = ''
	ret = ret .. string.format(
		'<strong class="error">[[Template:Dialogue]] error: %s.</strong>',
		msg
	)
	if mw.title.getCurrentTitle().namespace == 0 then
		ret = ret .. makeCategoryLink('Pages with template parameter errors')
	end
	return ret
end

function p._main(lines, options, audio)
	-- Validate the lines data.
	if #lines < 2 then
		return makeWikitextError('dialogues must have at least two lines')
	elseif #lines > 10 then
		-- Dialogues were restricted to 10 lines or less in
		-- [[Forum:CT:Quote length]].
		return makeWikitextError('dialogues must not have more than 10 lines')
	end
	for i, t in ipairs(lines) do
		if not t.speaker then
			return makeWikitextError(string.format(
				'no speaker was specified for line %d of the dialogue',
				i
			))
		elseif not t.text then
			return makeWikitextError(string.format(
				'no text was specified for line %d of the dialogue',
				i
			))
		end
	end

	-- Get the dialogue text.
	local dialogue = {}
	local speakers = {}
	local numSpeakers = 0
	for i, t in ipairs(lines) do
		local text
		local from = ''
		if t.format == 'trans' then
			text = string.format("&laquo;''%s''&raquo;", t.text)
		elseif t.format == 'no' then
			text = t.text
		else
			text = string.format("\"''%s''\"", t.text)
		end
		if t.from then
			from = string.format('<sup>[[%s|%s]]</sup>', t.from, mw.text.nowiki('[translated]'))
		end
		if speakers[t.speaker] == nil then
			speakers[t.speaker] = true
			numSpeakers = numSpeakers + 1
			if string.find(t.speaker, ' and ') then
				numSpeakers = numSpeakers + 1
			end
		end
		table.insert(dialogue, string.format(
			":'''%s''': %s%s", t.speaker, text, from
		))
	end
	dialogue = table.concat(dialogue, '\n')

	-- Make the footnote.
	local footnote = {}
	if numSpeakers == 2 and mw.title.getCurrentTitle().namespace == 0 then
		table.insert(footnote, '[[Category:Usages of Template:Dialogue with only two speakers]]')
	end
	table.insert(footnote, ':&#8213;')
	if options.attr then
		table.insert(footnote, options.attr)
	else
		return makeWikitextError("no 'attr' argument was specified")
	end
	if audio ~= nil and audio ~= '' then
		table.insert(footnote, audio)
	end
	if options.allfrom then
		table.insert(footnote, string.format('<sup>[[%s|%s]]</sup>', options.allfrom, mw.text.nowiki('[translated]')))
	end
	local sourceOnHover = false
	if options.src then
		if string.find(options.src, '-ref-') ~= nil then
			table.insert(footnote, options.src) 
		else
			local formatString
			if options.url then
				formatString = '<sup class="noprint plainlinks">[%s %s]</sup>'
			else
				formatString = '<sup class="noprint">[[%s|%s]]</sup>'
				sourceOnHover = true
			end
			table.insert(footnote, string.format(
				formatString,
				options.src,
				mw.text.nowiki('[src]')
			))
			if mw.title.getCurrentTitle().namespace == 0 then
				table.insert(footnote, makeCategoryLink('Dialogues with obsolete sourcing'))
			end
		end
	elseif mw.title.getCurrentTitle().namespace == 0 then
		table.insert(footnote, makeCategoryLink('Articles with unsourced quotes'))
	end
	footnote = table.concat(footnote)

	-- Return the assembled output.
	if sourceOnHover then
		return string.format(
			'<div class="quote" title="Source: %s">\n%s\n%s</div>',
			options.src,
			dialogue,
			footnote
		)
	else
		return string.format(
			'<div class="quote">\n%s\n%s</div>',
			dialogue,
			footnote
		)
	end
end

function p.main(frame)
	-- Process arguments from the frame object.
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end

	-- Sort the aguments into a usable format.
	local lines, options = {}, {}
	local function addLineData(line, lineKey, value)
		lines[line] = lines[line] or {}
		lines[line][lineKey] = value
	end
	for k, v in pairs(args) do
		if type(k) == 'number' then
			local line = math.ceil(k / 2)
			local lineKey = k % 2 == 1 and 'speaker' or 'text'
			addLineData(line, lineKey, v)
		else
			-- Assume k is a string.
			local line = k:match('^line([1-9][0-9]*)$')
			local from = k:match('^from([1-9][0-9]*)$')
			if line then
				addLineData(tonumber(line), 'format', v)
			elseif from then
				addLineData(tonumber(from), 'from', v)
			else
				options[k] = v
			end
		end
	end

	-- Remove blanks from the lines data.
	local function removeBlanks(t)
		local ret, nums = {}, {}
		for num in pairs(t) do
			nums[#nums + 1] = num
		end
		for i, num in ipairs(nums) do
			ret[i] = t[num]
		end
		return ret
	end
	lines = removeBlanks(lines)

	return p._main(lines, options, frame.args.audio)
end

return p

-- </nowiki>