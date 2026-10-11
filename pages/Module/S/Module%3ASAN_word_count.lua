-- This module implements the word count used in status article nominations,
-- i.e., counts the words of the: 
-- * introduction
-- * article body
-- * "Behind the scenes" material
-- and excludes any:
-- * captions
-- * quotes
-- * headers
-- * tables
-- * etc.

local p = {}
local transcluder = require('Dev:Transcluder')

function p._main(args)
	local page = args.page
	local text = p.get_text(page)
	--local word_count = p.word_count(text)
	
	local pruned_text = p.prune_wikitext(text)
	local word_count = p.word_count(pruned_text)

	-- Create the surrounding span.
	local root = mw.html.create('span')

	local template_start = 'The article "[[' .. page .. ']]" has '
	
	local template_end = ' words. This word count counts the introduction, the article body, and "Behind the scenes" material, but not captions, quotes, headers, etc. For clarification, please refer to [[:File:NominationFlowchart.png|this flowchart]].'
	
	local full_text = template_start .. word_count .. template_end

	-- Add the span containing the formed wording.
	root:wikitext(full_text)
	return tostring(root)
end

function p.get_text(page)
	local transclude_options = {
    	only = 'paragraphs',
    	-- noComments = true,
    	noBehaviorSwitches = true,
    	references = 0,
    	templates = '-.+infobox',
    	categories = '0',
    	-- noLinks = true
    }
	local text = transcluder.get( page, transclude_options)
	return text
end

-- remove e.g. infobox templates and section headers
-- treat pipelinks as the text they show
function p.prune_wikitext(text)
	-- Step 1: treat pipelinks like just the displayed text
	-- '[[' (anything but ']' or '|') '|' (anything but ']') ']]'
	local pipelink_regex = '%[%[[^%|%]]+%|([%]]+)%]%]'
	local no_pipelinks = '%1'
	local step_1 = text:gsub(pipelink_regex, no_pipelinks)
	
	-- Step 2: No ref notes
	local refnote_regex='</?ref(%s+name="[^"]*")?%s*/?>'
	local pruned_text = step_1:gsub(refnote_regex, "")
	
	return pruned_text
end

function p.word_count(text)
	local _, words = text:gsub("%S+","")
	return words
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

-- debugging functions

function p.text(frame)
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
	return p.get_text(args.page)
end

function p.pruned_text(frame)
	local text = p.text(frame)
	return p.prune_wikitext(text)
end

return p