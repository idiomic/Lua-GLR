std = 'lua51'

files['Item.lua'].ignore = {
	'11',
}

files['grammars/**/*.lua'].ignore = {
	'113';
	'111/%u[%u_]*'; -- Globals starting with _ are special
}