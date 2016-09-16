local SPEC = {
	TERM = {},
	BEGIN = {},
}
SPEC[SPEC.TERM] = 'TERM'
SPEC[SPEC.BEGIN] = 'BEGIN'
--[[if arg[1] == '--debug' then
	local peak = 0
	debug.sethook(function()
		local m = collectgarbage'count'
		if m > peak then
			print( m )
			peak = m
		end
	end, '', 1)
end--]]
local chain = {}


local function add( prev, new )
	local c = chain[ prev ]
	if not c then
		c = {0}
		chain[ prev ] = c
	end
	c[ new ] = (c[ new ] or 0) + 1
	c[1] = c[1] + 1
end


local nfile
do
	local k = 0
	local n = 0
	function nfile()
		n = n + 1
		io.write( string.rep( '\b', k ))
		io.write( n )
		k=#tostring( n )
	end
end


local out = io.open(arg[1], 'w') or io.stdout


io.write'#files processed:'
local prev
for file in assert( io.popen'find /usr/share/man/man* -type f' ):lines() do
	nfile()
	local iter = assert( io.popen( 'PAGER=cat man '..file )):read'*a':gmatch( utf8.charpattern )
	prev = SPEC.BEGIN
	for char in iter do
		if char:match'%S' then
			--io.write( char )
			if prev then
				add( prev, char )
			end
			prev = char
		else
			if prev then
				add( prev, SPEC.TERM )
			end
			prev = nil
		end
	end
end


local function write( s )
	out:write( s, '\n' )
end

write[[
local SPEC = {
	TERM = {},
	BEGIN = {},
}]]
write'return { data = {'
for char, t in pairs( chain ) do
	if SPEC[char] then
		write( string.format( '\t[SPEC.%s] = {', SPEC[char] ))
	else
		write( string.format( '\t[%q] = {', char ))
	end
	local sum = t[1]
	for k, v in pairs( t ) do
		if SPEC[k] then
			write( string.format( '\t\t[SPEC.%s] = %s,', SPEC[k], v ))
		else
			write( string.format( '\t\t[%q] = %s,', k, v ))
		end
	end
	write'\t},'
end
write'}, specials = SPEC }'
