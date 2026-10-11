local p = {}

local template = [=[
<div style="background: #2E628A; border: 1px solid #2E628A; padding: 3px; border-radius: 5px; box-shadow: 0.1em 0.1em 0.5em rgba(0,0,0,0.75); text-align: center; height: 100px; width: 100px;">
<div style="position: relative;">
<div style="position: absolute; top: 88px; right: 0px; width: auto; overflow: hidden; line-height: 12px; z-index: 4; text-align: right; padding: 1px 1px 1px 5px; background: #2E628A; border-radius-topleft: 8px; width: auto; text-align: right;">[[%s|<span style="color: white; font-size: 0.8em;">'''%s'''</span>]]</div>
<div style="position: absolute; top: 0px; left: 0px; height: 100px; width: 100px; overflow: hidden; z-index: 2;">[[Image:%s|100px|%s|link=%s]]</div>
</div>
</div>]=]

local output = [=[
{| width="270" border="0" cellspacing="2" align="center" style="background: transparent;"
|%s 
|%s
|%s
|%s
|-
|%s
|%s
|%s
|%s
|}]=]

function p.main(frame)
    local listtext = frame.args.list
    local list = {}
    for line in listtext:gmatch('[^\n]+') do
        list[#list + 1] = line:match('^%*?%s*(.-)%s*$')
    end
    math.randomseed(os.time())
    for n = 0, 7 do
        local max = #list - n
        local selection = math.random(1, max)
        if selection ~= max then
            list[selection], list[max] = list[max], list[selection]
        end
    end
    local result = {unpack(list, #list - 7)}
    for index, item in ipairs(result) do
        local args = {}
        for arg in item:gmatch('[^%|]+') do
            args[#args + 1] = arg
        end
        local file = args[1]
        local article = args[2]
        local display = args[3] or args[2]
        result[index] = template:format(article, display, file, display, article)
    end
    return output:format(unpack(result))
end

return p