-- <nowiki>
--[[
--------------------------------------------------------------------------------
--                                                                            --
--                            NAMESPACE DETECT                                --
--                                                                            --
-- This module implements the {{namespace detect}} template in Lua, with a    --
-- few improvements: all namespaces and all namespace aliases are supported,  --
-- and namespace names are detected automatically for the local wiki. The     --
-- module can also use the corresponding subject namespace value if it is     --
-- used on a talk page. Parameter names can be configured for different wikis --
-- by altering the values in the "cfg" table in                               --
-- Module:Namespace detect/config.                                            --
--                                                                            --
--------------------------------------------------------------------------------
--]]

return require('Dev:Namespace detect')

-- </nowiki>
-- [[Category:Modules]]