#!/usr/bin/ruby
# ----------------------------------------------------------------------------
require 'web'
require 'directory'
# ----------------------------------------------------------------------------
unless $cgi.has_key? 'dir'
	Output.error
	puts 'Не указана директория'
	exit 0
end
# ----------------------------------------------------------------------------
directory = Directory.create $cgi['dir']
if directory.nil?
	Output.error
	puts "Неверная директория #{$cgi['dir']}"
	exit 0	
end
# ----------------------------------------------------------------------------
Output.start
if not $cgi.has_key? 'post'
	directory.add
else
	idx = directory.post_add($cgi)
	if idx.nil?
		puts "\n\nНе удалось добавить запись"
		exit 0	
	end
	directory.field(idx)
end
Output.finish
# ----------------------------------------------------------------------------

