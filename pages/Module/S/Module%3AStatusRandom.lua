local p = {}

local function escapePattern(str)
    return mw.ustring.gsub(str, "([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
end

local start = '<!--Start-->'
local stop = '<!--End-->'
local listpatt = escapePattern(start) .. '(.-)' .. escapePattern(stop)

local linkpatt = "\"?'?'?%[%[[^%]\n]+%]%]'?'?\"?"

local function main(pagename)
    local wikitext = mw.title.new(pagename):getContent()
    local raw_list = mw.ustring.match(wikitext, listpatt)
    local list = {}
    for link in mw.ustring.gmatch(raw_list, linkpatt) do
        list[#list + 1] = link
    end
    math.randomseed(os.time())
    local num = math.random(1, #list)
    return list[num]
end

function p.FA(frame)
    return main('Wookieepedia:Featured articles')
end

function p.GA(frame)
    return main('Wookieepedia:Good articles')
end

function p.CA(frame)
    return main('Wookieepedia:Comprehensive articles')
end

return p