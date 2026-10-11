--<nowiki>
local SLD = '1px solid'
local DSH = '1px dashed'
local DOT = '1px dotted'

local data = {
	['!'] = {
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['%'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	["'"] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['('] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	[')'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['*'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['+'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	[','] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['-'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = SLD, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['.'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['7'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	[':'] = {
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['A'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['C'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['D'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['F'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['G'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['G2'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['H'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['J'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['K'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['L'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['M'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DOT, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['P'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DOT, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['Q'] = {
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['R'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['S'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['T3'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['T2'] = {
		b = { { style ={ ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style =  { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = {  ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['T'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['U'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['V'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DSH, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['W'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['X'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['Y'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['Z'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['^'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['$'] = {
		t = { { attr = { colspan = '2', rowspan = '2'}, style = { ['padding-left'] = '2em', ['padding-top'] = '2em' } } }
			},
	['`'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['a2'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = '1px dashed #000001', ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['a'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['b2'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = '1px dotted #000001', ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['b3'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['b'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['c'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['d'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['di'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['dj'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['e'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['f'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['fh'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] =DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['fy'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['h'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['he'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['i'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['ic'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['j'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = SLD, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['jc'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['k2'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['k3'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['k'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['kq'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['kr'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['kq2'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['kr2'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},

	['l2'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = '1px dashed #000001', ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['l3'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['l4'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['l'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['m2'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DOT, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['m'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DOT, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['mp'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['mp2'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['n2'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = '1px dotted #000001', ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['n'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['np'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['np2'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['o2'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['o'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { rowspan = '2' }, style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '2em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['om'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['om2'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['on'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['on2'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['p2'] = {
		b = { { style = { ['border-right'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DSH, ['border-bottom'] = '1px dotted #000001', ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['p'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['q2'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = '1px dashed #000001', ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['q'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['ql'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['ql2'] = {
		b = { { style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = DOT, ['border-bottom'] =DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['r2'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DSH, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['r'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = SLD, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['rl'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['rl2'] = {
		b = { { style = { ['border-right'] = DOT, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['t'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-right'] = SLD, ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } } }
			},
	['v'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = SLD, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['x'] = {},
	['y'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ style = { ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DSH, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			},
	['ye'] = {
		b = { { style = { ['border-right'] = SLD, ['padding-left'] = '1em', ['padding-top'] = '1em' } } },
		t = { { style = { ['border-bottom'] = DSH, ['padding-left'] = '1em', ['padding-top'] = '1em' } },
			{ attr = { rowspan = '2' }, style = { ['padding-left'] = '1em', ['padding-top'] = '2em' } } }
			},
	['~'] = {
		b = { { attr = { colspan = '2' }, style = { ['padding-left'] = '2em', ['padding-top'] = '1em' } } },
		t = { { attr = { colspan = '2' }, style = { ['border-bottom'] = DSH, ['padding-left'] = '2em', ['padding-top'] = '1em' } } }
			}
}


local retval = {}

for k,v in pairs(data) do
	retval[k] = {}
	for k2,v2 in pairs(v) do
		local renderedCells = mw.html.create()
		for k3,v3 in ipairs(v2) do
			renderedCells:tag('td'):css(v3.style or {}):attr(v3.attr or {})
		end
		retval[k][k2] = tostring(renderedCells)
	end
end

return retval