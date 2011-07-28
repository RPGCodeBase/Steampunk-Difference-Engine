# ----------------------------------------------------------------------------
require 'mysql'
require 'config'
require 'log'
# ----------------------------------------------------------------------------
class Database
	def initialize()
		@host = DB_HOST 
		@user = DB_USER
		@passwd = DB_PASSWORD
		@db = DB_NAME
	end

	def select(q, hash = false, with_table_ = false)
		begin	
			dbh = Mysql.real_connect(@host, @user, @passwd, @db)
			res = dbh.query(q)
			ret = res.num_rows
			if hash then
				res.each_hash(with_table = with_table_) do |row|
					yield row
				end
			else
				res.each do |row|
					yield row
				end
			end
			res.free
		rescue Mysql::Error => e
			$log.puts "MySQL error code: #{e.errno}"
			$log.puts "Error message: #{e.error}"
			$log.puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
			ret = nil
		ensure
			dbh.close if dbh
			return ret
		end	
	end

	def modify(q)
		begin	
			dbh = Mysql.real_connect(@host, @user, @passwd, @db)
			dbh.query(q)
			return true
		rescue Mysql::Error => e
			$log.puts "MySQL error code: #{e.errno}"
			$log.puts "Error message: #{e.error}"
			$log.puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
			return false
		ensure
			dbh.close if dbh
		end	
	end
end
# ----------------------------------------------------------------------------

