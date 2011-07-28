#!/usr/bin/ruby
# ----------------------------------------------------------------------------
require 'readline'
require 'engine'
require 'log'
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
$log.puts 'Console started'
# ----------------------------------------------------------------------------
$engine = Engine.new
# ----------------------------------------------------------------------------
trap('INT') {
	$engine.finish
	exit
}
# ----------------------------------------------------------------------------
Readline.completion_append_character = ' '
Readline.basic_quote_characters = '\"'
loop {
	list = $engine.command_list.sort
	comp = proc { |s| list.grep( /^#{Regexp.escape(s)}/) }
	Readline.completion_proc = comp

	line = Readline.readline($engine.prompt, true)
	if line.nil?
		puts
		next
	end

	begin
		$engine.command(line)
	rescue EngineException => e
		puts e
		$log.puts "Machine exception #{e}"
#	rescue Exception => e
#		$log.puts "Console exception #{e}"
	end
}
# ----------------------------------------------------------------------------

