-------------------------------------------------------------------------------
--                    Module:Template test case/config
-- This module holds configuration data for [[Module:Template test case]].
-------------------------------------------------------------------------------

return {

-------------------------------------------------------------------------------
-- Options
-------------------------------------------------------------------------------

-- The magic word used in place of the template name when making nowiki
-- invocations.
templateNameMagicWord = '__TEMPLATENAME__',

-- The subpage that sandboxes are typically stored on. Used when loading
-- wrapper template config and when guessing the sandbox template name.
sandboxSubpage = 'sandbox',

-------------------------------------------------------------------------------
-- Messages
-------------------------------------------------------------------------------

msg = {

-- The default header for test cases rendered in columns.
['columns-header'] = 'Side by side comparison',

-- The error message to use if a templaten option is missing.
-- $1 - the number of the missing template option.
['missing-template-option-error'] = "one or more options ending in '$1' " ..
	"were detected, but no 'template$1' option was found",

-- The error message to use if a nowiki invocation is used but the template
-- name magic word is not found.
-- $1 - the value of the template name magic word
['nowiki-magic-word-error'] = "the template invocation must include '$1' in " ..
	"place of the template name",

},

-------------------------------------------------------------------------------
-- Default argument config.
-- Wrapper templates can specify a config parameter in their invocations to
-- load various default arguments. This table specifies those default
-- arguments. The table keys are the values specified by the wrapper templates,
-- and the values are subtables containing two fields:
--   func - the function name to be used with that template. This must be a
--       function in the modules "bridge" table. This is optional: the default
--       value is "table".
--   args - a table of default arguments to be used with that template. This is
--       is optional.
-------------------------------------------------------------------------------

defaultArgs = {
	['nowiki'] = {func = 'nowiki'}
}

-------------------------------------------------------------------------------
-- End config
-------------------------------------------------------------------------------

}