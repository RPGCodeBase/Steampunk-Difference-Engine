# ----------------------------------------------------------------------------
require 'db'
require 'output'
# ----------------------------------------------------------------------------
class Directory
	def initialize()
	end

	def add_address(dir)
		"add.cgi?dir=#{dir}"
	end

	def post_add_address
		'add.cgi'
	end

	def post_field_address
		'field.cgi'
	end

	def post_delete_address
		'delete.cgi'
	end

	def list_address(dir)
		"slist.cgi?dir=#{dir}"
	end

	def direct_address(dir,id)
		"field.cgi?dir=#{dir}&id=#{id}"
	end

	def query_list_address(dir,field,id)
		"qlist.cgi?dir=#{dir}&field=#{field}&value=#{id}"
	end

	def history_address(dir)
		"history.cgi?dir=#{dir}"
	end	

	def index_address
		'index.cgi'
	end	

private	
	def gen_random_id(available_list, prefix)
		begin
			new_number = prefix * (10 ** 5) + rand(10 ** 5)
		end while available_list.include? new_number
		new_number
	end
end
# ----------------------------------------------------------------------------
require 'government'
require 'crime'
require 'finance'
require 'oracle'
require 'foreign'
require 'fleet'
require 'patents'
require 'army'
# ----------------------------------------------------------------------------
class Directory
	def Directory.create(dir)
		case dir
			when 'gov' then return GovernmentDirectory.new
			when 'crime' then return CrimeDirectory.new
			when 'fin' then return FinanceDirectory.new
			when 'pat' then return PatentsDirectory.new
			when 'oracle' then return OracleDirectory.new
			when 'fore' then return ForeignDirectory.new
			when 'fleet' then return FleetDirectory.new
			when 'army' then return ArmyDirectory.new
		else
			return nil		
		end
	end
end

