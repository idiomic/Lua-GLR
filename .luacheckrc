std = 'lua51'

files['Item.lua'].ignore = {
	'11',
}

files['grammars/**/*.lua'].ignore = {
	'113';
	'111/%a[%a_]*'; -- Globals starting with _ are special
	'212/records|token';
}