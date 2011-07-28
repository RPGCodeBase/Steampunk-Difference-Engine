# ----------------------------------------------------------------------------
$teletype_buffer = [] if $teletype_buffer.nil?
# ----------------------------------------------------------------------------
def teletype(s)
	print s
	STDOUT.flush
	$teletype_buffer.push s
end
# ----------------------------------------------------------------------------
def flush_teletype
	p = IO.popen('lpr', 'w')
	p.puts $teletype_buffer.join('')
	p.close
	$teletype_buffer = []
end
# ----------------------------------------------------------------------------

