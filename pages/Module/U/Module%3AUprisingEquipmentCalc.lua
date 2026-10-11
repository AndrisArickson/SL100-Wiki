local p = {}
local getArgs = require('Dev:Arguments').getArgs

local function getC0(MaxPowerUpLevel)
    if MaxPowerUpLevel <= 5 then return 30.0 end
    if MaxPowerUpLevel <= 90 then return 20.0 end
    if MaxPowerUpLevel <= 120 then return 51.333 end
    return 110.833
end


local function getC1(MaxPowerUpLevel)
    if MaxPowerUpLevel <= 5 then return 0.0 end
    if MaxPowerUpLevel <= 10 then return 40.0 end
    if MaxPowerUpLevel <= 20 then return 80.0 end
    if MaxPowerUpLevel <= 40 then return 1300.0 end
    if MaxPowerUpLevel <= 65 then return 2000.0 end
    return 2700.0
end

local function getC2(MaxPowerUpLevel)
    if MaxPowerUpLevel <= 5 then return 100.0 end
    if MaxPowerUpLevel <= 10 then return 70.0 end
    if MaxPowerUpLevel <= 20 then return 55.0 end
    if MaxPowerUpLevel <= 40 then return 1300.0 end
    if MaxPowerUpLevel <= 65 then return 48.0 end
    if MaxPowerUpLevel <= 90 then return 132.8 end
    if MaxPowerUpLevel <= 120 then return 289.3 end
    return 300.0
end

local function getC3(MaxPowerUpLevel)
    if MaxPowerUpLevel <= 5 then return 0.0 end
    if MaxPowerUpLevel <= 10 then return 500.0 end
    if MaxPowerUpLevel <= 20 then return 1000.0 end
    if MaxPowerUpLevel <= 40 then return 1700.0 end
    if MaxPowerUpLevel <= 65 then return 2800.0 end
    if MaxPowerUpLevel <= 90 then return 4000.0 end
    if MaxPowerUpLevel <= 120 then return 7320.0 end
    return 16000.0
end

local function getBasePowerUpLevel(MaxPowerUpLevel)
    if MaxPowerUpLevel <= 5 then return 0.0 end
    if MaxPowerUpLevel > 120 then return 120.0 end
    if MaxPowerUpLevel > 90 then return 90.0 end
    if MaxPowerUpLevel > 65 then return 65.0 end
    if MaxPowerUpLevel > 40 then return 40.0 end
    if MaxPowerUpLevel > 20 then return 20.0 end
    if MaxPowerUpLevel > 10 then return 10.0 end
    if MaxPowerUpLevel > 5 then return 5.0 end
    return 0.0
end

local function formulaLHS(TargetPowerUpLevel, c0, c1)
    return ((c0 * TargetPowerUpLevel) + c1)
end 

local function formulaRHS(TargetPowerUpLevel, BasePowerUpLevel, c2, c3)
    return ((c2 * (TargetPowerUpLevel - BasePowerUpLevel)) + c3)
end

local function parseFloat(num)
    local tmp = tonumber(num)
    local _
    if tmp == nil then
        _, _, tmp = string.find(num, '%s*([%d%.]+)[^%d%.]*$')
        return tonumber(tmp)
    end
    return tmp
end

local function parseScalar(num)
    local val = parseFloat(num)
    local hasPct = string.match(num, '%d%%%s*$')
    
    if val == nil or hasPct == nil then
        return val
    else
        return (val / 100.0)
    end
end

local function equipmentFormula(target, levelCap, scalar)
    local TargetPowerUpLevel = parseFloat(target)
    local MaxPowerUpLevel = parseFloat(levelCap)
    local scaleNum = parseScalar(scalar)
    
    if not (TargetPowerUpLevel == nil or MaxPowerUpLevel == nil or scaleNum == nil) then
        local c0 = getC0(MaxPowerUpLevel)
        local c1 = getC1(MaxPowerUpLevel)
        local c2 = getC2(MaxPowerUpLevel)
        local c3 = getC3(MaxPowerUpLevel)
        local BasePowerUpLevel = getBasePowerUpLevel(MaxPowerUpLevel)
        
        local lhs = formulaLHS(TargetPowerUpLevel, c0, c1)
        local rhs = formulaRHS(TargetPowerUpLevel, BasePowerUpLevel, c2, c3)
        
        
        local out = (math.max(lhs, rhs) * (scaleNum / 2.0))
        
        --return string.format('%.2f', out)
        return out
    end
    return ""
end

local function equipmentInverseFormula(targetLevel, levelCap, rValue)
    local TargetPowerUpLevel = parseFloat(targetLevel)
    local MaxPowerUpLevel = parseFloat(levelCap)
    local resultValue = parseFloat(rValue)
    
    if not (TargetPowerUpLevel == nil or MaxPowerUpLevel == nil or resultValue == nil or resultValue == 0) then
        local c0 = getC0(MaxPowerUpLevel)
        local c1 = getC1(MaxPowerUpLevel)
        local c2 = getC2(MaxPowerUpLevel)
        local c3 = getC3(MaxPowerUpLevel)
        local BasePowerUpLevel = getBasePowerUpLevel(MaxPowerUpLevel)
        
        local lhs = formulaLHS(TargetPowerUpLevel, c0, c1)
        local rhs = formulaRHS(TargetPowerUpLevel, BasePowerUpLevel, c2, c3)
        
        
        local out = ((2.0 * resultValue) / math.max(lhs, rhs))
        
        --return string.format('%.2f', out)
        return out
    end
    return ""
end


function p.getLevelValue(frame)
    local args = getArgs(frame)
    local e
    local r
    local TargetPowerUpLevel = args["level"]
    local MaxPowerUpLevel = args["levelCap"]
    local scaleNum = args["scalar"]
  
    if not(TargetPowerUpLevel == nil or MaxPowerUpLevel == nil or scaleNum == nil or TargetPowerUpLevel == "?" or MaxPowerUpLevel == "?" or scaleNum == "?") then
        e, r = pcall(equipmentFormula, TargetPowerUpLevel, MaxPowerUpLevel, scaleNum)
        if e then
            return string.format('%.0f', r)
        else
            return r
        end
    end
    return ""
end

function p.getScalarValue(frame)
    local args = getArgs(frame)
    local e
    local r
    local TargetPowerUpLevel = args["level"]
    local MaxPowerUpLevel = args["levelCap"]
    local levelValue = args["levelValue"]
    
    if not(TargetPowerUpLevel == nil or MaxPowerUpLevel == nil or levelValue == nil or TargetPowerUpLevel == "?" or MaxPowerUpLevel == "?" or levelValue == "?") then
        e, r = pcall(equipmentInverseFormula, TargetPowerUpLevel, MaxPowerUpLevel, levelValue)
        if e then
            return string.format('%.2f%%', r * 100)
        else
            return r
        end
    end
    return ""
end
--io.write("OUT: ",equipmentFormula("65", "65", "0.26"),"\n")
--io.write("OUT: ",equipmentFormula("54", "65", "0.26"),"\n")

return p