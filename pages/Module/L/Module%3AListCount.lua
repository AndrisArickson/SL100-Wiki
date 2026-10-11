local p = {}

function p.main(frame)
    local list = frame.args.list
    local bullet = string.format('\n%%%s+', frame.args[1])
    local _, count = list:gsub(bullet, '')
    local singular = count == 1
    return string.format(
        'There %s %s %s in this list.\n%s',
        singular and 'is' or 'are',
        mw.getContentLanguage():formatNum(count),
        singular and 'item' or 'items',
        list
    )
end

return p