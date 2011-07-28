#!/usr/bin/ruby

puts 'INDEXES = ['

dir = false
STDIN.each_line { |l|
	l.strip!
	if l ==	'запись:' then
		if dir == false
			puts "\t["
			dir = true
		else
			puts "\t], ["
		end
	elsif l =~ /([0-9A-F][0-9A-F])\s*\*\s*([0-9A-F][0-9A-F])\s*\*/
		puts "\t\t[0x#{$1}, 0x#{$2}],"
	end
}

puts "\t]"
puts ']'

