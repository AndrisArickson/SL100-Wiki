-- <pre>
-- Returns the first valid/existing page from a given list (Max: 5 Links)
-- 
-- If none of the given pages exist, "defaultText" and "defaultLink" are
-- returned ("defaultLink" is never checked for existence)
-- If "defaultLink" is nil or blank, "defaultText" is returned without link
-- brackets.
-- 
-- This is meant for when a page does not currently exist, but will eventually.
--   - Ex. Linking to a Legends/Canon page when a project page has yet to be
--     created. Like "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Anoat_sector"
--     linking to "Anoat_sector" until the page is made.
-- 
-- You should avoid using this module (or any "Exists" function for that matter) while
-- on the "mainspace". "Red links" are important for wiki growth and let users know
-- when information is unavailable/missing. But out of the mainspace you may need a
-- way to link to the most relevant information available. This is especially true
-- for dynamically generated pages.
--
-- The "expensive function count" will be incremented each time a page's existence
-- is checked. Should be used as little as possible.
--
-- Syntax:
--     Takes links (page name and display text) using the following format
--     ("X" is a number from 1 to 5, and keys are not case-sensitive):
--         Lua:  TextX = "Foo", LinkX = "Bar"
--         Wiki: TextX=Foo|LinkX=Bar
--
-- ToDo:
--     - Add a maintenance category when the first link (Link1) exists, flagging
--       the page to have the exists function removed.
--       * Potential Problem:
--         If called from a lua module NOT using statically defined names, should
--         the category still be added? Is there a way to tell how a module/function
--         was called in Lua other than just the frame?
--
-- Lua Example:
--     ValidLink.getExistingPageLink{link1 = "I do not exist", text1 = "Bad Page Name", link2 = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Anoat_sector", text2 = "Anoat sector", defaultLink = "Anoat_sector", defaultText = "Anoat sector"}
--     result: [[Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Anoat_sector|Anoat sector]]
-- 
--     ValidLink.getExistingPageLink{link1 = "I do not exist", text1 = "Bad Page Name", defaultLink = "Anoat_sector", defaultText = "Anoat sector"}
--     result: [[Anoat_sector|Anoat sector]]
--
--     ValidLink.getExistingPageLink{link1 = "I do not exist", text1 = "Bad Page Name", defaultText = "Anoat sector"}
--     result: Anoat sector
--
-- Wiki Example:
--     {{#invoke:ValidLink|main|link1=|I do not exist,text1=Bad Page Name,link2=Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Anoat_sector,text2=Anoat sector,defaultLink=Anoat_sector, defaultText =Anoat sector}}
--     output: [[Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Anoat_sector|Anoat sector]]
-- 
--     {{#invoke:ValidLink|main|link1=I do not exist,text1=Bad Page Name,defaultLink=Anoat_sector,defaultText=Anoat sector}}
--     output: [[Anoat_sector|Anoat sector]]
--
--     {{#invoke:ValidLink|main|link1=I do not exist,text1=Bad Page Name,defaultText=Anoat sector}}
--     output: Anoat sector


local p = {}

local testFrameArgs = {
    link1 = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Anoat_sector",
    text1 = "Anoat sector",
    defaultLink = "Anoat_sector",
    defaultText = "Anoat sector"
}

-- test frame
p.childFrame = {
    args = mw.clone(testFrameArgs),
    getParent = function()
        local pArgs = mw.clone(testFrameArgs)
        return { args = pArgs }
    end
}

function p.childFrame:getParent()
    local pArgs = mw.clone(testFrameArgs)
    return { args = pArgs }
end

function toLower(str)
    if str == nil then
        return nil
    end
    
    return mw.ustring.lower(tostring(str))
end

function isNotEmpty(str)
    return ((str ~= nil and mw.text.trim(tostring(str)) ~= '' and true) or false)
end

function getParentFrame(frame)
    return frame:getParent()
end

function getParentFrame2(frame)
    return frame.getParent()
end

function Try_getParentFrame(frame)
    local success,result = pcall(getParentFrame, frame)
    
    if success == false or result == nil or result.args == nil then
        local success2,result2 = pcall(getParentFrame2, frame)
        if success2 == true and result2 ~= nil then
            return result2
        end
    end
    
    return result
end

function _getArgs(frame)
    local args = {}
    local parentFrame = nil
    
    local processArgList = function(_args)
        for k,v in pairs(_args) do
            if isNotEmpty(v) then
                if type(v) == 'string' then
                    args[toLower(k)] = mw.text.trim(v)
                else
                    args[toLower(k)] = v
                end
            end
        end
    end
    
    if frame then
        if frame.args ~= nil then
            processArgList(frame.args)
        end
        parentFrame = Try_getParentFrame(frame)
        if parentFrame == nil and frame.args == nil then
            processArgList(frame)
        elseif parentFrame and parentFrame.args ~= nil then
            processArgList(parentFrame.args)
        end
    end
    
    return args
end

local pageExists = function(link)
    local titleobject = mw.title.new(link)
    
    return (titleobject and titleobject.exists)
end


function p.getExistingPage(args)
    if args.defaulttext == nil and args.defaultlink == nil then
        args = _getArgs(args)
    end
    local defaultText = args.defaulttext
    local defaultLink = args.defaultlink
    
    for i=1,5 do
        if isNotEmpty(args['link' .. tostring(i)]) then
            if pageExists(args['link' .. tostring(i)]) then
                return (isNotEmpty(args['text' .. tostring(i)]) and args['text' .. tostring(i)] or defaultText), args['link' .. tostring(i)]
            end
        else
            break
        end
    end
    
    return defaultText, defaultLink
end

function p.getExistingPageLink(args)
    local text, link = p.getExistingPage(args)
    
    if isNotEmpty(link) then
        return '[[' .. link .. (isNotEmpty(text) and ('|' .. text) or '') .. ']]'
    end
    
    return (text or '')
end

function p.main(frame)
    frame = frame or mw.getCurrentFrame()
    local args = _getArgs(frame)
    
    return p.getExistingPageLink(args)
end

function p._debug(fn)
    -- main
    -- getExistingPageLink
    -- getExistingPage
    local result = p[fn or 'main'](p.childFrame)
    mw.log(result)
    return result
end

return p
-- </pre>