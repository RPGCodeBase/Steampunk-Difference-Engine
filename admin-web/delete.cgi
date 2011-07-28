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
if $cgi.has_key? 'id'
	idx = $cgi['id']
else
	Output.error
	puts "Не задан индекс"
	exit 0		
end
# ----------------------------------------------------------------------------
if $cgi['delete'] == 'true'
	Output.start
	idx = directory.post_delete($cgi)
	if idx.nil?
		puts "\n\nНе удалось удалить запись"
		exit 0	
	end
	directory.short_list
	Output.finish
else
	Output.error
	puts "\n\nНе отмечена галочка об удалении!"
	exit 0	
end
# ----------------------------------------------------------------------------

