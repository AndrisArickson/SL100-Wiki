--<nowiki>
local p = {}

local cells = mw.loadData('Module:FamilyTree/data')

function p._main(cell_args)
    local ret = mw.html.create()
    local top = ret:tag('tr')
                        :css{ height = '1px',
                                ['text-align'] = 'center' }
    local bottom = ret:tag('tr')
                        :css{ height = '1px',
                                ['text-align'] = 'center' }
    for _, v in ipairs(cell_args) do
        if type(v) == 'string' then
            top:wikitext(cells[v].t)
            bottom:wikitext(cells[v].b)
        else
            top:tag('td')
                :attr{ colspan = v.colspan or cell_args.colspan or 6,
                        rowspan = v.rowspan or cell_args.rowspan or 2,
                        class = 'ft-colored-box' }
                :css{ padding = '0.2em',
                        border = (v.border or cell_args.border or '2') .. 'px solid' }
                :cssText(v.boxstyle or cell_args.boxstyle)
                :wikitext(v.text)
        end
    end
    return tostring(ret)
end

function p.main(frame)
    local args = frame:getParent().args
    local cell_args = {
        colspan = args.colspan,
        rowspan = args.rowspan,
        border = args.border,
        boxstyle = args.boxstyle
    }
    for _, val in ipairs(args) do
        local trimmedVal = val:match('^%s*(.-)%s*$')
        if trimmedVal == '' then
            trimmedVal = '$'
        end
        if cells[trimmedVal] then
            table.insert(cell_args, trimmedVal)
        else
            -- Unnamed params behave weirdly
            -- white space at the front counts for param_{{{1}}}, but not whitespace at the end, so remove it
            local rightTrimmedVal = val:gsub('%s+$','')
            
            --Shortcut for coloring female, male, and unknown boxes
            local style = args['boxstyle_'..rightTrimmedVal]
            local content = args[trimmedVal] or ('{{{'..trimmedVal..'}}}')
            if style ~= nil then
                style = string.lower(args['boxstyle_'..rightTrimmedVal])
                if style == 'f' then 
                    style = 'background-color: #FFDDE4;'
                    content = content .. "&nbsp;♀"
                elseif style == 'm' then
                    style = 'background-color: #BDE3FF;'
                    content = content .. "&nbsp;♂"
                elseif style == 'u' then
                    style = 'background-color: #CECECE;'
                elseif style == 'i' then
                    style = 'background-color: #CECECE; font-style: italic;'
                else
                    style = args['boxstyle_'..rightTrimmedVal]
                end
            end
                
            table.insert(cell_args, {
                text = content,
                colspan = args['colspan_'..rightTrimmedVal],
                rowspan = args['rowspan_'..rightTrimmedVal],
                border = args['border_'..rightTrimmedVal],
                boxstyle = style
            })
        end
    end
    
    return p._main(cell_args)
end

return p