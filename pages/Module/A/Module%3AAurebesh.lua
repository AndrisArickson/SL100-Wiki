local p = {}

local data = mw.loadData('Module:Aurebesh/data')

local yesno = require('Module:Yesno')

local imagelink = '[[File:%s|%s|link=%s|alt=%s|class=darkmodeinvert]]'

local function makeCategoryLink(cat)
    -- "Category" is split out here so that the module isn't put into the
    -- category "%s" when the page is saved.
    return string.format('[[%s:%s]]', 'Category', cat)
end

local function makeWikitextError(msg)
    return string.format(
        '<strong class="error">Aurebesh error: %s.</strong>%s',
        msg,
        makeCategoryLink('Pages with invalid Aurebesh templates')
    )
end

local function escapePattern(str)
    return mw.ustring.gsub(str, "([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
end

local function singlechars(args)
    local style = args.style
    local link = args.link or ''
    local size = args.size or 'x13px'
    local ret = {}
    for _, arg in ipairs(args) do
        char = mw.ustring.lower(arg)
        if data.chars[char] then
            ret[#ret + 1] = imagelink:format(
                data.chars[char][style],
                size,
                link,
                ''
            )
        else
            return makeWikitextError(string.format(
                'unrecognized character "%s"',
                char
            ))
        end
    end
    local spacer = imagelink:format('1pixelspace.png', size, link, '')
    return table.concat(ret, spacer)
end

function p._main(args)
    local style = args.style
    if not style then
        style = 'regular'
    end
    if not data.sets.style[style] then
        return makeWikitextError('invalid argument to "style"')
    end
    local digraphs = args.digraphs
    if digraphs then
        digraphs = yesno(digraphs, 'error')
        if digraphs == 'error' then
            return makeWikitextError('invalid argument to "digraphs"')
        end
    else
        digraphs = true
    end
    local link = args.link or ''
    local size = args.size or 'x13px'
    local ret = {}
    for _, arg in ipairs(args) do
        local pos = 0
        while pos < mw.ustring.len(arg) do
            pos = pos + 1
            local char = mw.ustring.sub(arg, pos, pos)
            local lookup = mw.ustring.lower(char)
            if char == "'" or char == '"' then
                local prevpos = pos - 1
                if prevpos == 0 then
                    lookup = char .. 'l'
                else
                    local prevchar = mw.ustring.sub(arg, prevpos, prevpos)
                    if prevchar == ' ' or prevchar == '\n' or prevchar == '' then
                        lookup = char .. 'l'
                    else
                        lookup = char .. 'r'
                    end
                end
            end
            if digraphs and data.sets.digraphstarts[char] then
                local nextchar = mw.ustring.sub(arg, pos + 1, pos + 1)
                if data.sets.digraphs[char..nextchar] then
                    char = char .. nextchar
                    lookup = mw.ustring.lower(char)
                    pos = pos + 1
                end
            end
            if char == ' ' or char == '\n' then
                ret[#ret + 1] = char
            elseif data.chars[lookup] then
                ret[#ret + 1] = imagelink:format(
                    data.chars[lookup][style],
                    size,
                    link,
                    char
                )
            else
                return makeWikitextError(string.format(
                    'unrecognized character "%s"',
                    char
                ))
            end
        end
    end
    local spacer = imagelink:format('1pixelspace.png', size, link, '')
    output = table.concat(ret, spacer)
    output = mw.ustring.gsub(output, '\n' .. escapePattern(spacer), '\n')
    return output
end

local function processArgs(frame)
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
    return args
end

-- called from deprecated [[Template:Aur]]
function p.regular(frame)
    local args = processArgs(frame)
    args.style = 'regular'
    return singlechars(args)
end

-- called from deprecated [[Template:AurB]]
function p.bold(frame)
    local args = processArgs(frame)
    args.style = 'bold'
    return singlechars(args)
end

-- called from new [[Template:AurText]]
function p.main(frame)
    local args = processArgs(frame)
    return p._main(args)
end

return p