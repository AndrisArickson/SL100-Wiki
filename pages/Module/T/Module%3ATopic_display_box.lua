local p = {}

-- function to output the appropriate icon for each article
local function icon(code, px, blank)
    local image
    if code == "FA" then
        image = "[[File:FA-Icon-old.svg|%dpx]]"
    elseif code == "GA" then
        image = "[[File:GA-Icon-old.svg|%dpx]]"
    elseif code == "CA" then
        image = "[[File:CA-Icon-old.svg|%dpx]]"
    elseif code == "FFA" then
        image = "[[File:FA-Former-retro.svg|%dpx]]"
    elseif code == "FGA" then
        image = "[[File:GA-Former-retro.svg|%dpx]]"
    elseif code == "FCA" then
        image = "[[File:CA-Former-retro.svg|%dpx]]"
    else
        image = blank or "[[File:Blank.svg|%dpx]]"
    end
    return image:format(px)
end

-- primary function called by template
function p._main(args)
    
    -- initialize main variables from parameters
    local topictype = (args.type or ""):upper()            -- topic type
    local title = args.title or " "                        -- topic title
    local titlestatus = (args.titlestatus or ""):upper()   -- status of title article
    local fullcategory = args.fullcategory                 -- category for full list of possible articles
    
    -- process unnamed parameters, which alternate between status and article
    local statuslist = {}                                  -- table that will contain list of statuses
    local articlelist = {}                                 -- table that will contain list of articles
    for n, value in ipairs(args) do
        if n % 2 == 1 then
            statuslist[#statuslist + 1] = value:upper()
        else
            articlelist[#articlelist + 1] = value
        end
    end
    
    local linecount = #articlelist
    if fullcategory then
        linecount = linecount + 1
    end
    
    local columns
    if linecount <= 2 then
        columns = 1
    elseif linecount <= 8 then
        columns = 2
    else
        columns = 3
    end

    -- declare variable that will contain background color
    local bgcolor
    -- determines background color based on topictype
    if topictype == "FT" then
        bgcolor = "FAFAD2"
    elseif topictype == "GT" then
        bgcolor = "ADDFAD"
    elseif topictype == "CT" then
        bgcolor = "FAB09E"
    else
        bgcolor = "FFFFFF" -- default to white if topictype is unrecognized
    end
    
    -- build finished product
    local ret = {}
    ret[#ret + 1] = string.format('<div style="margin: 1em 0; padding: 7px; background-color: #%s; border: 1px solid #999; ', bgcolor)
    ret[#ret + 1] = 'box-shadow: 0.1em 0.1em 0.5em rgba(0,0,0,0.75); -moz-box-shadow: 0.1em 0.1em 0.5em rgba(0,0,0,0.75); -webkit-box-shadow: 0.1em 0.1em 0.5em rgba(0,0,0,0.75); '
    ret[#ret + 1] = 'border-radius: 1em; -moz-border-radius: 1em; -webkit-border-radius: 1em; width: auto;">\n'
    ret[#ret + 1] = string.format("<big><center>%s '''%s'''</center></big>\n", icon(titlestatus, 20, ""), title)
    ret[#ret + 1] = string.format('<div style="column-count: %d; -moz-column-count: %d; -webkit-column-count: %d;">\n', columns, columns, columns)
    -- this CSS creates a proper HTML list without bullets or indentation
    ret[#ret + 1] = '<ul style="list-style: none; padding-left: 0; margin-top: 0;">\n'
    
    -- combine statuslist entries with the corresponding articlelist entries, calling icon() function to convert code into image
    for n, article in ipairs(articlelist) do
        ret[#ret + 1] = string.format("<li>%s %s</li>\n", icon(statuslist[n], 15), article)
    end
    -- if a category is provided, add an extra line with the category link
    if fullcategory then
        ret[#ret + 1] = string.format("<li>(''[[:Category:%s|Full list of possible articles]]'')</li>\n", fullcategory)
    end
    
    ret[#ret + 1] = "</ul></div></div>"
    
    return table.concat(ret)
end

function p.main(frame)
    local args = {}
    for k, v in pairs(frame:getParent().args) do
        v = v:match('^%s*(.-)%s*$') -- trim whitespace
        if v ~= '' or type(k) == 'number' then
            args[k] = v
        end
    end
    return p._main(args)
end

return p