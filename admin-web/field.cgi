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
Output.start
if $cgi.has_key? 'post'
	idx = directory.post_field($cgi)
	if idx.nil?
		puts "\n\nНе удалось изменить запись"
		exit 0	
	end
end
directory.field(idx)
Output.finish
# ----------------------------------------------------------------------------

