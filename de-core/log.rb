# ----------------------------------------------------------------------------
require 'config'
# ----------------------------------------------------------------------------
class Log
	def initialize(filename)
		@filename = filename
	end

	def puts(s)
		f = File.new(@filename, File::WRONLY | File::APPEND) 
		f.puts "#{Time.now.to_s} #{s}"
		f.close
	end
end
# ----------------------------------------------------------------------------
$log = Log.new(LOG_FILE) if $log.nil?
# ----------------------------------------------------------------------------

