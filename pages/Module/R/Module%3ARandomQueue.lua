local p = {}
 
local function escapePattern(str)
    return mw.ustring.gsub(str, "([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
end
 
local start = '<!--Start-->'
local stop = '<!--End-->'
--local listpatt = escapePattern(start) .. '(.-)' .. escapePattern(stop)
local linkpatt = "%[%[[^%]\n]+%]%]"
 
local function pick_article(mode)
	local list = {}
	local fa_list = " "
	local ga_list = " "
	local pagename, pagetext, filename = " "
	
	if (mode == "fa" or mode == "both") then
		fa_list = mw.title.new('Wookieepedia:Featured articles/Canon'):getContent() .. mw.title.new('Wookieepedia:Featured articles/Legends'):getContent() .. mw.title.new('Wookieepedia:Featured articles/OOU'):getContent()
		--fa_list = fa_list:match(listpatt)
	end
	if (mode == "ga" or mode == "both") then
		ga_list = mw.title.new('Wookieepedia:Good articles/Canon'):getContent() .. mw.title.new('Wookieepedia:Good articles/Legends'):getContent() .. mw.title.new('Wookieepedia:Good articles/OOU'):getContent()
		--ga_list = ga_list:match(listpatt)
	end
	
	local raw_list = mw.ustring.format("%s\n%s", fa_list, ga_list)
	for link in raw_list:gmatch(linkpatt) do
		pagename = link:gsub("%[%[(.*)%]%]", "%1")
		pagename = pagename:gsub("(.*)%|.*", "%1")
		if mw.title.new(pagename):getContent() ~= nil and not pagename:find("Unidentified") then
			list[#list + 1] = pagename
		end
	end
	
	local not_done = true
	local num = 0
	local selected = ""
	while not_done do
		math.randomseed(os.time())
		num = math.random(1, #list)
		pagetext = mw.title.new(list[num]):getContent()
		pagetext = pagetext:gsub("%=%=(.*)", "")
		filename = pagetext:match(".*%[%[File:(.*)%]%].*")
		if filename then
			selected = list[num]
			not_done = false
		end
	end
	
-- Extract the page name and load it
	return list[num]
end

-- Remove any links from the text, leaving
-- the displayed portion of the link only.
local function strip_links(text)
    -- First, convert links like this: [[foo|bar]] to this: bar
    text = text:gsub("%[%[[^%]\n]+%|([^%]\n]+)%]%]", "%1")
    -- Next, convert links like this: [[foo]] to this: foo
    return text:gsub("%[%[([^%]\n]+)%]%]", "%1")
end

local function queueify(pagename)
	local file_string = ""
	local main_link = ""
	local pagetext = mw.title.new(pagename):getContent()
	local x = pagetext:gsub("%=%=(.*)", "")
 
-- Generate image
	local filename = x:match(".*%[%[File:(.*)%]%].*")
	if filename then
		filename = filename:gsub("%|.*", "")
		filename = filename:gsub("%]%].*", "")
		file_string = string.format("[[File:%s|left|150px|link=%s]]\n", filename, pagename)
	end

-- Extract the bolded segment
	local bolded = ""
	local front_italics = false
	local end_italics = false
	local intro = x:gsub(".*()%}%}\n(.*)", "%2")
	
	local s1, e1 = intro:find("'''")
	if e1 and intro:sub(e1 + 1, e1 + 2) == "''" then
		e1 = e1 + 2
		front_italics = true
	end
	local s2, e2 = intro:find("'''", e1 + 1)
	if e2 and intro:sub(e2 + 1, e2 + 2) == "''" then
		s2 = s2 + 2
		end_italics = true
	end
	
	if front_italics and end_italics then
		bolded = strip_links(intro:sub(e1 + 1, s2 - 3))
		main_link = string.format("[[%s|%s]]", pagename, bolded)
		s2 = s2 - 2
	elseif front_italics then
		bolded = strip_links(intro:sub(e1 - 1, s2 - 1))
		main_link = string.format("[[%s|%s]]", pagename, bolded)
		e1 = e1 - 2
	elseif end_italics then
		bolded = strip_links(intro:sub(e1 + 1, s2 - 1))
		main_link = string.format("[[%s|%s]]", pagename, bolded)
	else
		bolded = strip_links(intro:sub(e1 + 1, s2 - 1))
		main_link = string.format("[[%s|%s]]", pagename, bolded)
	end

	intro = intro:sub(0, e1) .. main_link .. intro:sub(s2)
	
-- Substitute templates, add {{Rm}}, and remove any images
	intro = intro:gsub("%{%{'s%}%}", "<span style=\"padding-left: 0.1em;\">'</span>s")
	intro = intro:gsub("\n\n$", string.format(" '''([[%s|Read more&hellip;]])'''", pagename))
	if x:find("|image=") then
		intro = intro:gsub("%[%[File:(.*)%]%]", "")
	end

	return file_string .. intro
end

function p._main(args)
	local pagename, result, success
	if not args.mode then
		args.mode = "both"
	end
	if args.page then
		pagename = args.page
	else
		pagename = pick_article(string.lower(args.mode))
	end
	
	success, result = pcall(queueify, pagename)
	return success and result or 'An error was encountered while preparing '..pagename..' for display; please inform the admins of this error along with the pagename, and refresh the page.'
end

function p.main(frame)
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