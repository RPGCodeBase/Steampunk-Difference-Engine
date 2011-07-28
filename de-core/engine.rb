# ----------------------------------------------------------------------------
require 'db'
require 'teletype'
# ----------------------------------------------------------------------------
class EngineException < Exception
	def initialize(msg)
		@message = msg
	end

	def to_s
		@message
	end
end
# ----------------------------------------------------------------------------
class ProgramException < EngineException
	def initialize(msg,num)
		super(msg)
		@number = num
	end
end
# ----------------------------------------------------------------------------
class Time 
	def to_s
		(year - 120).to_s + strftime('-%m-%d %I:%M%p')
	end
end
# ----------------------------------------------------------------------------
class MachineState
	attr_reader :v, :e
	attr_writer :v, :e

	def initialize
		@v = {}
		['A', 'B', 'C'].each { |s|
			@v[s] = []
			5.times { |i|
				@v[s][i] = MachineState.default(i)
			}
			6.times { |i|
				j = i + 10
				@v[s][j] = MachineState.default(j)
			}
		}
		@e = [
			0,
			0,
			'',
			'',
			0,
			0
		]
	end

	def MachineState.default(index)
		case index
		when 0x0 then 0
		when 0x1 then 0
		when 0x2 then 0.0
		when 0x3 then ''
		when 0x4 then Time.new
		when 0xA..0xF then []
		else
			$log.puts "Bad default index #{index}"
			nil
		end
	end

	def serialize
		Marshal.dump(self)
	end

	def MachineState.deserialize(str)
		Marshal.load(str)
	end
end
# ----------------------------------------------------------------------------
class Engine
	VERSION = '2.117'
	CONTROL_CMD = {
		'RESET' => {:params => false, :run => Proc.new { |e| e.run_reset_cmd }, :cost => 1, :unnamed => false},
		'STATE' => {:params => false, :run => Proc.new { |e| e.run_state_cmd }, :cost => 1, :unnamed => true},
		'LIST' => {:params => false, :run => Proc.new { |e| e.run_list_cmd }, :cost => 10, :unnamed => false},
		'CONTROL' => {:params => false, :run => Proc.new { |e| e.run_control_cmd}, :cost => 1, :unnamed => false},
		'OPERATOR' => {:params => true, :run => Proc.new { |e,p| e.run_operator_cmd(p)}, :cost => 5, :unnamed => true},
		'BYE' => {:params => false, :run => Proc.new { |e| e.run_bye_cmd }, :cost => 1, :unnamed => false},
		'TEST' => {:params => true, :run => Proc.new { |e,p| e.run_test_cmd(p) }, :cost => 1, :unnamed => false}
	}
	ENGINE_CMD = {
		'FINISH' => Proc.new { |e| e.run_finish_ctrl },
		'CHOOSE' => Proc.new { |e,p| e.run_choose_ctrl(p)},
		'REQUEST' => Proc.new { |e,p| e.run_request_ctrl(p)},
		'MODIFY' => Proc.new { |e,p| e.run_modify_ctrl(p)},
		'ADD' => Proc.new { |e,p| e.run_add_ctrl(p)},
		'CALC' => Proc.new { |e,p| e.run_calc_ctrl(p)},
		'STAT' => Proc.new { |e,p| e.run_stat_ctrl(p)},
		'ORACLE' => Proc.new { |e,p| e.run_oracle_ctrl(p)},
		'INTEGRAL' => Proc.new { |e,p| e.run_integral_ctrl(p)},
		'RECORD' => Proc.new { |e,p| e.run_record_ctrl(p)},
		'LOOP' => Proc.new { |e,p| e.run_loop_ctrl(p)},
		'TYPE' => Proc.new { |e,p| e.run_type_ctrl(p)}
	}

	require 'indexes'

	def initialize
		@db = Database.new
		set_mode(:command)
		reset
	end

	def prompt
		case @mode
		when :command then '> '
		when :control 
			if @global_loop.nil? then
				'ENGINE> '
			else
				'LOOP> '
			end
		else
			$log.puts "Bad mode #{@mode}"
			'? '
		end
	end

	def command_list
		case @mode
		when :command then CONTROL_CMD.keys
		when :control then ENGINE_CMD.keys
		else
			$log.puts "Bad mode #{@mode}"
			[]
		end
	end

	def command(cmd)
		case @mode
		when :command then sys_command(cmd.strip)
		when :control then engine_command(cmd.strip)
		else
			$log.puts "Bad mode #{@mode}"
		end
	end
# ----------------------------------------------------------------------------
	def run_reset_cmd
		set_mode(:command)
		teletype "SYSTEM RESTARTING"
		10.times {
			sleep(1)
			teletype '.'
		}
		teletype "\n\n"
		flush_teletype
		reset
	end

	def run_state_cmd
		teletype "\nDIFFERENCE ENGINE VERSION #{VERSION}\n\n"
		teletype "SYSTEM STATE.............. #{state_to_string}\n"
		teletype "UPTIME COUNTER............ #{@uptime_counter}\n"
		teletype "RESTART TIME.............. #{@restart_time.strftime('%I:%M%p')}\n"
		teletype "OPERATOR.................. #{@operator.nil? ? 'NOT SET': @operator}\n\n"
	end

	def run_list_cmd
	end

	def run_control_cmd
		error 'CANNOT SWITCH TO CONTROL MODE' if @mode != :command
		set_mode(:control)
		teletype "CONTROL MODE ENABLED\n"
		flush_teletype
	end

	def run_operator_cmd(params)
		id = params.to_i
		error 'BAD OPERATOR ID PARAMETER' unless id > 0

		sex = ''
		res = @db.select("select D0F05 from D0 where D0F01 = #{id}") { |row|
			sex = row[0]
		}
		if res.nil? or res == 0 then
			error 'UNKNOWN OPERATOR ID'
		end
		if sex == 'MALE' then
			teletype "GLAD TO SEE YOU, GENTLEMAN\n"
		else
			teletype "GLAD TO SEE YOU, LADY\n"
		end
		@operator = id
	end
# ----------------------------------------------------------------------------
	def run_bye_cmd
		return 
		res = @db.select("select D0F05 from D0 where D0F01 = #{@operator}") { |row|
			sex = row[0]
		}
		if res.nil? or res == 0 then
			error 'UNKNOWN OPERATOR ID'
		end
		if sex == 'MALE' then
			teletype "GOOD BYE, GENTLEMAN\n"
		else
			teletype "GOOD BYE, LADY\n"
		end
				
	end
# ----------------------------------------------------------------------------
	def run_test_cmd(params)
		error 'BAD TEST COMMAND STRING' unless params =~ /^([A-Z]+)\s*(.*)$/ 

		cmd_name = $1
		cmd_params = $2.strip
			
		res = calculate_cost(cmd_name, cmd_params)
		if res.nil? then
			teletype "BAD COMMAND\n"
		else 
			teletype "#{res}\n"
		end
	end
# ----------------------------------------------------------------------------
	def run_finish_ctrl
		error 'CANNOT SWITCH TO COMMAND MODE' if @mode != :control
		set_mode(:command)
		teletype "CONTROL MODE DISABLED\n"
		flush_teletype
		return 1
	end

	def run_choose_ctrl(params)
		unless params =~ /^\[([A-F][0-9A-F])\]\s+\[([0-9][0-9A-F])\]\s+IF\s+(.+)$/ then
			program_error 'BAD CHOOSE PARAMETERS', 3 
		end
		
		dist_var = $1
		index = $2
		condition = $3

		unless @global_loop.nil?
			program_error "TRYING TO WRITE INTO LOOP VARIABLE #{@global_loop_var}", 8 if @global_loop_var == dist_var
		end
	
		program_error("BAD CHOOSE RESULT VARIABLE #{dist_var}", 7) unless dist_var =~ /(A|B|C)([0-9A-F])/
		dist_var_name = $1
		dist_var_index = $2.hex

		directory = index[0, 1]
		check_directory_variable('CHOOSE', directory)
		dir = directory.to_i
		idx = index.hex

		index_type = nil
		INDEXES[dir].each { |pair|
			var, typ = pair
			if var == idx then
				index_type = typ
				break
			end
		}

		program_error("UNKNOWN INDEX #{index}", 7) if index_type.nil?

		if index_type == 0xF then 
			program_error("BAD RESULT VARIABLE FOR SUCH TYPE", 9) unless dist_var_index == 0xE or dist_var_index == 0xF

			his = history_get(dir, dist_var_index == 0xE)
			set_variable('CHOOSE', dist_var_name, dist_var_index, his)	
			return
		else 
			program_error("DISPARITY OF VARIABLE TYPE AND INDEX TYPE", 9) if index_type != dist_var_index
		end

		condition = convert_condition('CHOOSE', condition)

		field = sprintf("D%sF%s", directory, index)

		data = nil
		record = nil
		query = "SELECT D#{directory}F#{directory}1,#{field} FROM D#{directory} WHERE #{condition}"
		$log.puts "Querying DB: #{query}"
		res = @db.select(query) { |row|
			record = row[0]
			data = row[1]
		}

		if res.nil? then
			program_error "BAD CONDITION SYNTAX", 4
		elsif res == 0 then
			@machine.v[dist_var_name][dist_var_index] = nil
			@machine.e[5] = 1
		elsif res > 1 then						
			@machine.e[5] = 0
			program_error "AMBIGUOUS REQUEST OR CONDITION", 10
		elsif res == 1
			history_add(dir, [record], "READ")
			set_variable_from_string('CHOSE', dist_var_name, dist_var_index, data)
			@machine.e[5] = 0			
		else
			$log.puts "Bad query result #{res}"	
		end
	end

	def run_request_ctrl(params)
		unless params =~ /^\[([A-F][0-9A-F])\]\s+\[([0-9D][0-9A-F])\]\s+IF\s+(.+)$/ then
			program_error 'BAD REQUEST PARAMETERS', 3 
		end
		
		dist_var = $1
		index = $2
		condition = $3

		program_error("BAD REQUEST RESULT VARIABLE #{dist_var}", 7) unless dist_var =~ /(A|B|C)([A-F])/
		dist_var_name = $1
		dist_var_index = $2.hex
		dist_scalar_type = scalar_type_by_array(dist_var_index) if dist_var_index != 0xF

		if index =~ /D([0-9])/ then
			directory = $1
			idx = nil
		else			
			directory = index[0, 1]
			idx = index.hex
		end
		check_directory_variable('REQUEST', directory)
		dir = directory.to_i

		unless idx.nil?

			index_type = nil
			INDEXES[dir].each { |pair|
				var, typ = pair
				if var == idx then
					index_type = typ
					break
				end
			}

			program_error("UNKNOWN INDEX #{index}", 7) if index_type.nil?
	
			if index_type == 0xF then 
				program_error("BAD RESULT VARIABLE FOR SUCH TYPE", 9) unless dist_var_index == 0xE or dist_var_index == 0xF
	
				his = history_get(dir, dist_var_index == 0xE)
				set_variable('CHOOSE', dist_var_name, dist_var_index, his)	
				return
			else 
				program_error "UNCOMPARTIBLE VARIABLE TYPES", 7 unless compartible_types(index_type, dist_var_index)
			end

			field = sprintf("D%sF%s", directory, index)
			hash = false
		else
			program_error("CANNOT REQUEST DIRECTORY INTO SIMPLE ARRAY VARIABLE", 7) if dist_var_index != 0xF
			field = "*"
			hash = true
		end

		condition = convert_condition('REQUEST', condition)

		data = []
		records = []
		query = "SELECT D#{directory}F#{directory}1, #{field} FROM D#{directory} WHERE #{condition}"
		$log.puts "Querying DB: #{query}"
		res = @db.select(query, hash) { |row|
			if hash then
				records.push row["D#{directory}F#{directory}1"]
			else
				records.push row[0]
			end
			data.push row
		}

		if res.nil? then
			program_error "BAD CONDITION SYNTAX", 4
		elsif res == 0 then
			@machine.v[dist_var_name][dist_var_index] = []
			@machine.e[5] = 1
		elsif res >= 1 then
			res = []
			data.each { |d|
				if dist_var_index == 0xF
					row = []
					INDEXES[dir].each { |pair|
						dir_index, dir_type = pair[0]
						row.push variable_from_string(dir_type, d["D#{directory}F#{dir_index}"])
					}
					res = row
				else
					res.push variable_from_string(dist_scalar_type, d[1])
				end
			}
			history_add(dir, records.uniq, "READ")
			@machine.v[dist_var_name][dist_var_index] = res
			@machine.e[5] = 0			
		else
			$log.puts "Bad query result #{res}"	
		end		
	end

	def run_modify_ctrl(params)
		unless params =~ /^\[([0-9A-F][0-9A-F])\]\s+([^\s]+)\s+\[([0-9A-F][0-9A-F])\]\s+(.+)/
			program_error 'BAD MODIFY PARAMETERS', 3 
		end
		
		search_index = $1
		search_value = $2
		dist_index = $3
		dist_value = $4

		program_error("BAD MODIFY INDEX #{search_index}", 7) unless search_index =~ /([0-79])1/
		directory = $1
		dir = directory.to_i
		
		index_value = nil
		if search_value =~ /^\#?([0-9]+)/ then
			index_value = $1.to_i
		elsif search_value =~ /\[([ABC][01])\]/ then
			index_value = get_variable('MODIFY', $1)
		else
			program_error "BAD INDEX PARAMETER", 3
		end
		
		program_error("MODIFY INDEXES ARE FROM DIFFERENT DIRECTORIES", 7) unless dist_index[0, 1] == directory
		program_error("BAD MODIFY DESTINATION INDEX #{dist_index}", 7) unless dist_index =~ /([0-E])$/
		dist_index_type = $1.hex
	
		program_error("TRYING TO MODIFY INDEX DATA", 7) if dist_index_type == 0

		v = nil
		case dist_value
		when /^\[00\]/
			v = 'NULL'
		when /^\[([A-F])([0-9A-F])\]$/
			var_name = $1
			var_type = $2.hex
			program_error("UNCOMPARTIBLE VALUE TYPE ",7) if var_type != dist_index_type
			v = get_variable('MODIFY', "#{$1}#{$2}")
			if var_type <= 0x4 then
				v = scalar_to_string(v)
			else
				if v.nil? or not (v.kind_of? Array) then
					v = 'NULL'
				else
					if var_type == 0xE or var_type == 0xD
						v = "\"" + v.join("\n") + "\""
					elsif 
						v = "\"" + v.join(",") + "\""
					end
				end
			end

		when /^#?([0-9\.]+)$/
			v = $1
		when /^(\"[^\"]+\")$/
			v = $1
		else
			program_error "BAD MODIFY VALUE #{v}", 7
		end

		index_field = "D#{directory}F#{directory}1"
		dist_field = sprintf("D%sF%s%X", directory, directory, dist_index_type)
		query = "UPDATE D#{directory} SET #{dist_field} = #{v} WHERE #{index_field} = #{index_value}"
		$log.puts "Updating DB: #{query}"
		res = @db.modify(query)
		if res
			history_add(directory.to_i, [index_value], "MODIFY")
		else
			program_error "MODIFICATION ERROR", 11
		end
	end

	def run_add_ctrl(params)
		program_error "COMMAND UNSUPPORTED", 5

		unless params =~ /^\[D([0-9A-F])\]\s+(.+)$/ then
			program_error 'BAD ADD PARAMETERS', 3 
		end
	
		directory = $1
		values_list = $2

		new_index = nil
		res = []
		values_list.scan(/\[([0-9A-F][0-9A-F])\]\s*=\s*(\[([0-9A-F][0-9A-F])\]|\"[^\"]+\"|\#?[0-9.]+)/)	{ |pair|
			index, value = pair.split('=').collect { |s| s.strip }
			program_error "BAD INDEX #{index}" unless index =~ /^([0-79])([1-E])$/
			program_error "UNCOMPARTIBLE INDEX AND DIRECTORY", 7 unless directory == $1
			value_index = $2.hex

			index_type = nil
			INDEXES[dir].each { |pair|
				var, typ = pair
				if var == value_index then
					index_type = typ
					break
				end
			}

			program_error("UNKNOWN INDEX #{index}", 7) if index_type.nil?
				
			v = nil			
			case value
			when /^\[00\]/
				v = 'NULL'
			when /^\[([A-F])([0-9A-F])\]$/
				var_name = $1
				var_type = $2.hex
				program_error("UNCOMPARTIBLE VALUE TYPE ",7) if var_type != value_index
				v = get_variable('ADD', "#{$1}#{$2}")
				if var_type <= 0x4 then
					v = scalar_to_string(v)
				else
					if v.nil? or not (v.kind_of? Array) then
						v = 'NULL'
					else
						if var_type == 0xE or var_type == 0xD
							v = "\"" + v.join("\n") + "\""
						elsif 
							v = "\"" + v.join(",") + "\""
						end
					end
				end
			when /^#?([0-9\.]+)$/
				v = $1
			when /^(\"[^\"]+\")$/
				v = $1
			else
				program_error "BAD ADD VALUE #{v}", 7
			end

			new_index = v.to_i if value_index == 1
			field = sprintf("D%sF%s%X", directory, directory, value_index)
			res.push "#{field} = #{v}"
		}

		program_error("INDEX FIELD IS MANDATORY",7) if new_index.nil?

		query = "INSERT INTO D#{directory} SET #{res.join(',')}"
		$log.puts "Updating DB: #{query}"
		res = @db.modify(query)
		if res
			history_add(directory.to_i, [new_index], "ADD")
		else
			program_error "INSERTING ERROR", 11
		end		
	end

	def run_calc_ctrl(params)
		unless params =~ /^\[([A-F][0-9A-F])\]\s+(.+)$/ then
			program_error 'BAD CALC PARAMETERS', 3 
		end
		
		dist_var = $1
		expression = $2

		unless @global_loop.nil?
			program_error "TRYING TO WRITE INTO LOOP VARIABLE #{@global_loop_var}", 8 if @global_loop_var == dist_var
		end

		program_error("BAD CALC RESULT VARIABLE #{dist_var}", 7) unless dist_var =~ /(A|B|C|F)([0-9])/
		dist_var_name = $1
		dist_var_index = $2.hex

		if dist_var_name == 'F' then
			########
			return 
		end
		
		case dist_var_index
		when 0, 1, 2
			expression.gsub!(/\#([0-9]+)/) { $1 }
			expression.gsub!(/\[([ABC][0-9A-F])\]/) {
				variable = $1
				program_error "NON NUMERIC #{variable} IN CALC", 7 unless variable =~ /^[ABC][01]|E[0-9]|F[0-9]$/
				v = get_variable(cmd, variable)
				if v.nil? then
					'NULL'
				elsif v.kind_of? Array then
					program_error "ARRAY VARIABLE #{variable} IN CALC", 7
				else
					scalar_to_string(v)
				end
			}
			query = expression					
		when 3
			query_str = expression.split('+').collect { |s|
				s.strip!
				case s
				when /^\[([A-F][0-9A-F])\]$/
					get_variable('CALC', $1)
				when /^#?([0-9\.]+)$/
					$1
				when /^\"([^\"]+)\"$/
					$1
				else
					program_error "BAD VALUE #{s} IN CALC EXPRESSION", 7
				end
			}.collect { |s| "\"#{s}\"" }.join(",")
			query = "CONCAT(#{query_str})"
		else
			program_error "BAD CALC RESULT VARIABLE TYPE", 7
		end

		query = "SELECT #{query}"
		data = nil
		$log.puts "Querying DB: #{query}"
		res = @db.select(query) { |row|
			data = row
		}

		if res.nil? or res == 0 then
			program_error "BAD EXPRESSION SYNTAX", 4
		elsif res > 1 then						
			program_error "AMBIGUOUS EXPRESSION", 10
		elsif res == 1
			set_variable_from_string('CHOOSE', dist_var_name, dist_var_index, data[0])
		else
			$log.puts "Bad query result #{res}"	
		end
	end

	def run_stat_ctrl(params)
		unless params =~ /^\[([A-F][0-9A-F])\]\s+(.+)$/ then
			program_error 'BAD STAT PARAMETERS', 3 
		end
		
		dist_var = $1
		expression = $2

		unless @global_loop.nil?
			program_error "TRYING TO WRITE INTO LOOP VARIABLE #{@global_loop_var}", 8 if @global_loop_var == dist_var
		end

		program_error("BAD STAT RESULT VARIABLE #{dist_var}", 7) unless dist_var =~ /(A|B|C|F)([0-9])/
		dist_var_name = $1
		dist_var_index = $2.hex

		if dist_var_name == 'F' then
			########
			return 
		end
	
		expression.gsub!(/(MAX|COUNT|MIN|AVG)\(\[([A-F][0-9A-F])\]\)/) {
			func = $1
			var = $2

			program_error "BAD #{func} VARIABLE", 7 unless var =~ /[ABC][A-F]/
			v = get_variable('STAT', var)
			if v.nil? or not v.kind_of? Array
				program_error "BAD #{func} VARIABLE", 7
			end
			case func
			when 'MAX' then v.max
			when 'MIN' then v.min
			when 'COUNT' then v.size
			when 'AVG'
				if dist_var_index == 0 or dist_var_index == 1 then
					sum = 0
					v.each { |val|
						sum += val.to_i
					}
					sum / v.size
				elsif dist_var_index == 2 then
					sum = 0.0
					v.each { |val|
						sum += val.to_f
					}
					sum / v.size.to_f
				else
					program_error "NON-NUMERIC AVG VARIABLE", 7
				end
			end
		}

		case dist_var_index
		when 0, 1, 2
			expression.gsub!(/\#([0-9]+)/) { $1 }
			expression.gsub!(/\[([ABC][0-9A-F])\]/) {
				variable = $1
				program_error "NON NUMERIC #{variable} IN STAT", 7 unless variable =~ /^[ABC][01]|E[0-9]|F[0-9]$/
				v = get_variable(cmd, variable)
				if v.nil? then
					'NULL'
				elsif v.kind_of? Array then
					program_error "ARRAY VARIABLE #{variable} IN STAT", 7
				else
					scalar_to_string(v)
				end
			}
			query = expression					
		when 3
			query_str = expression.split('+').collect { |s|
				s.strip!
				case s
				when /^\[([A-F][0-9A-F])\]$/
					get_variable('CALC', $1)
				when /^#?([0-9\.]+)$/
					$1
				when /^\"([^\"]+)\"$/
					$1
				else
					program_error "BAD VALUE #{s} IN STAT EXPRESSION", 7
				end
			}.collect { |s| "\"#{s}\"" }.join(",")
			query = "CONCAT(#{query_str})"
		else
			program_error "BAD STAT RESULT VARIABLE TYPE", 7
		end

		query = "SELECT #{query}"
		data = nil
		$log.puts "Querying DB: #{query}"
		res = @db.select(query) { |row|
			data = row
		}

		if res.nil? or res == 0 then
			program_error "BAD EXPRESSION SYNTAX", 4
		elsif res > 1 then						
			program_error "AMBIGUOUS EXPRESSION", 10
		elsif res == 1
			set_variable_from_string('CHOOSE', dist_var_name, dist_var_index, data[0])
		else
			$log.puts "Bad query result #{res}"	
		end
	end
	
	def run_oracle_ctrl(params)
		program_error 'PROGRAM UNSUPPORTED', 5
	end

	def run_integral_ctrl(params)
		unless params =~ /^\[([ABC][012])\]\s+\]?([ABC][012]|\-?[0-9\.]+)\]?\s+\[?([A-C][0-2]|[0-9\.]+)\]?\s+\"([^\"]+)\"$/ then
			program_error 'BAD INTEGRAL PARAMETERS', 3 
		end
		
		dist_var = $1
		first_limit = $2
		second_limit = $3
		function = $4
		
		program_error("BAD INTEGRAL RESULT VARIABLE #{dist_var}", 7) unless dist_var =~ /([ABC])2/
		dist_var_var = $1

		case first_limit
		when /^\[([A-C][12])\]$/
			first_limit = get_variable('INTEGRAL', $1).to_f
		when /^#?(\-?[0-9\.]+)$/
			first_limit = $1.to_f
		else
			program_error "BAD VALUE #{s} IN AN INTEGRAL LIMIT", 7
		end

		case second_limit
		when /^\[([A-C][12])\]$/
			second_limit = get_variable('INTEGRAL', $1).to_f
		when /^#?([0-9\.]+)$/
			second_limit = $1.to_f
		else
			program_error "BAD VALUE #{s} IN AN INTEGRAL LIMIT", 7
		end

		res = calculate_integral(first_limit, second_limit, function)

		program_error "BAD FUNCTION", 4 if res.nil?
		set_variable('INTEGRAL', dist_var_var, 2, res)
	end

	def run_record_ctrl(params)
		unless params =~ /^\[([A-C][0-4A-F])\]\s+\[([A-C][0-9A-F])\]\s+(.+)$/ then
			program_error 'BAD RECORD PARAMETERS', 3 
		end

		dist_var = $1
		array_var = $2
		index_var = $3.strip

		program_error "DUPLICATED VARIABLES", 7 if dist_var == array_var
		program_error "BAD VARIABLE #{dist_var} AS FIRST RECORD PARAMETER", 7 unless dist_var =~ /([ABC])([0-4A-F])/
		dist_var_name = $1
		dist_var_index = $2.hex
		program_error "SCALAR VARIABLE #{array_var} AS ARRAY PARAMETER", 7 unless array_var =~ /([ABC]([A-F]))/
		array_var = $1
		array_var_index = $2.hex		
		program_error "UNCOMPARTIBLE VARIABLE TYPES", 7 unless compartible_types(dist_var_index, array_var_index)
		
		array = get_variable('RECORD', array_var)

		index_value = nil
		if index_var =~ /^\#?([0-9]+)/ then
			index_value = $1.to_i
		elsif index_var =~ /\[([A-C][0-1])\]/ then
			index_value = get_variable('RECORD', $1)
		else
			program_error "BAD INDEX PARAMETER", 3
		end

		program_error 'INCORRECT INDEX VALUE', 4 if index_value < 0 or index_value >= array.size

		set_variable('RECORD', dist_var_name, dist_var_index, array[index_value])
	end

	def run_loop_ctrl(params)
		if params == 'END' then
			if @global_loop.nil? 
				program_error 'UNMATCHED LOOP END', 3
			end

			@global_loop_var =~ /^([ABC])([01])$/
			var_name = $1
			var_index = $2.hex
			
			@global_loop_left.times { |i|
				set_variable('LOOP', var_name, var_index, i)
				$log.puts "Loop iteration #{i}"

				@global_loop.each { |cmd|
					program_error 'BAD COMMAND SYNTAX', 1 unless cmd =~ /^([A-Z]+)\s*(.*)$/ 

					@machine.e[3] = cmd

					cmd_name = $1
					cmd_params = $2.strip

					ENGINE_CMD[cmd_name].call(self, cmd_params)
					counter = calculate_cost(cmd_name, cmd_params)
					@machine.e[0] = 0
					@machine.e[1] = 0
					@machine.e[2] = ''
					@machine.e[4] = counter
					@uptime_counter += counter
				}
			}
			set_variable('LOOP', var_name, var_index, @global_loop_left)

			$log.puts "Loop finished"

			@global_loop = nil
			return
		end

		program_error 'DOUBLE LOOP DISABLED', 3  unless @global_loop.nil?
	
		unless params =~ /^\[([A-C][0-9A-F])\]\s+(.+)$/ then
			program_error 'BAD LOOP PARAMETERS', 3 
		end
		
		loop_var = $1
		loop_limit = $2.strip

		program_error("BAD LOOP VARIABLE #{loop_var}", 7) unless loop_var =~ /([ABC])([01])/
		program_error "DUPLICATED VARIABLES", 7 if loop_var == loop_limit

		loop_var_var = $1
		loop_var_index = $2.hex
	
		limit_value = nil
		if loop_limit =~ /^([0-9]+)/ then
			limit_value = $1.to_i
		elsif loop_limit =~ /\[([ABC][01])\]/ then
			limit_value = get_variable('LOOP', $1)
		else
			program_error "BAD LOOP LIMIT PARAMETER", 3
		end

		set_variable('LOOP', loop_var_var, loop_var_index, 0)

		@global_loop = []
		@global_loop_left = limit_value
		@global_loop_var = loop_var

		$log.puts "Loop started: idx = #{@global_loop_var} limit = #{@global_loop_left}"
	end

	def run_type_ctrl(params)
		unless params =~ /^((\"[^\"]*\"|\[[0-9A-F][0-9A-F]\])\s*,\s*)*(\"[^\"]*\"|\[[0-9A-F][0-9A-F]\])$/ then
			program_error 'BAD TYPE PARAMETERS', 3 
		end
		params.scan(/\"[^\"]*\"|\[[0-9A-F][0-9A-F]\]/).each { |arg|
			if arg =~ /\[([0-9A-F][0-9A-F])\]/ then
				var = get_variable('TYPE', $1)
				if var.nil? then
					teletype '[00]'
				elsif var.kind_of? Array then
					if var.empty? then
						teletype '||'
					else
						strs = []
						var.each_index { |i|
							if var[i].kind_of? Array then
								strs.push([i, "| #{var[i].join("| ")}|"])
							else
								strs.push([i, var[i].to_s])
							end
						}
						first_column_width = strs.last[0].to_s.length + 2
						strs.each { |pair|
							teletype "\n| #{pair[0].to_s.ljust(first_column_width-2)} |  #{pair[1]} |"
						}
					end
				else
					teletype var
				end
			elsif arg =~ /\"([^\"]*)\"/ then
				teletype $1
			else
				program_error 'BAD TYPE PARAMETERS', 3 
			end
		}
		teletype "\n"
	end
# ----------------------------------------------------------------------------
	def finish
		Process.kill("SIGHUP", @sound_proc_pid) unless @sound_proc_pid.nil?
		Process.wait
	end

private

	def reset
		@variables = {}
		@uptime_counter = 0
		@program = nil
		@operator = nil
		@restart_time = Time.now
		@machine = MachineState.new
		initialize_machine

		start_message
	end

	def error(str)
		raise EngineException.new(str)
	end

	def program_error(str,num)
		@machine.e[0] = num
		@machine.e[1] = 0
		@machine.e[2] = str
		@machine.e[4] = 1
		@uptime_counter += 1
		@global_loop = nil
		raise ProgramException.new(str,num)
	end

	def start_message
		teletype "DIFFERENCE ENGINE VERSION #{VERSION}\n"
		teletype "WELCOME TO THE MACHINE\n"
		teletype "DO NOT FORGET TO ENTER OPERATOR ID FIRST\n\n"
	end

	def state_to_string
		case @mode
		when :command then 'CONTROL/WAITING'
		when :low then 'COMMAND'
		when :high then 'PROGRAM'
		else
			'ERROR'
		end		
	end

	def sys_command(cmd)
		error 'BAD COMMAND STRING' unless cmd =~ /^([A-Z]+)\s*(.*)$/ 

		cmd_name = $1
		cmd_params = $2.strip

		error "BAD COMMAND '#{cmd_name}'\n" unless CONTROL_CMD.has_key? cmd_name
		
		command = CONTROL_CMD[cmd_name]
	
		if not command[:unnamed] and @operator.nil? then
			error 'ENTER OPERATOR ID FIRST'
		end

		if command[:params] then
			parameters = cmd_params.strip
			error "BAD PARAMETERS FOR COMMAND #{cmd_name}" if parameters.empty?
			command[:run].call(self, parameters)
		else
			error "BAD PARAMETERS FOR COMMAND #{cmd_name}" unless cmd_params.empty?
			command[:run].call(self)
		end
		@uptime_counter += command[:cost]
	end

	def engine_command(cmd)
		if cmd =~ /^FINISH\s*/ then
			@uptime_counter += ENGINE_CMD['FINISH'].call(self)
			return
		end

		@machine.e[3] = cmd

		program_error 'BAD COMMAND SYNTAX', 1 unless cmd =~ /^([A-Z]+)\s*(.*)$/ 

		cmd_name = $1
		cmd_params = $2.strip

		program_error "BAD COMMAND '#{cmd_name}'", 2 unless ENGINE_CMD.has_key? cmd_name
		program_error "BAD PARAMETERS FOR '#{cmd_name}'", 3 if cmd_params.empty?

		unless @global_loop.nil? or cmd_name == 'LOOP'
			@global_loop.push("#{cmd_name} #{cmd_params}")
		else
			ENGINE_CMD[cmd_name].call(self, cmd_params)
			counter = calculate_cost(cmd_name, cmd_params)
			@machine.e[0] = 0
			@machine.e[1] = 0
			@machine.e[2] = ''
			@machine.e[4] = counter
			@uptime_counter += counter 
		end
	end

	def check_directory_variable(cmd, num)
		program_error("BAD DIRECTORY IN COMMAND '#{cmd}'", 8) unless num =~ /[0-79]/
	end

	def get_system_variable(name)
		case name
		when 'F0' then @uptime_counter
		when 'F1'
			if @mode == :command then 0
			elsif @mode == :control then 1
			else nil end
		when 'F6' 
			@operator
		else
			$log.puts "Unknown system variable #{name}"
			nil
		end
	end

	def get_variable(cmd, name)
		case name
		when /^00$/ then nil
		when /^([0-9])([0-9A-F])/ then program_error "INDEX WAS USED INSTEAD VARIABLE IN COMMAND '#{cmd}'", 8
		when /^(A|B|C)([0-9A-F])/ 
			var_name = $1
			var_index = $2.hex
			@machine.v[var_name][var_index]
		when /^(D)([0-9])/ then program_error "DIRECTORY WAS USED INSTEAD VARIABLE IN COMMAND '#{cmd}'", 8
		when /^(E)(.)/ then @machine.e[$2.hex]
		when /^(F)/ then get_system_variable(name)
		else
			program_error "BAD VARIABLE '#{name}'", 7
		end
	end

	def set_variable(cmd, var, index, value)
		@machine.v[var][index] = value
	end

	def set_variable_from_string(cmd, var, index, value)
		@machine.v[var][index] = variable_from_string(index, value)
	end

	def variable_from_string(typ, value)
		res = nil
		return res if value == 'NULL'
		case typ
		when 0,1
			res = value.to_i
		when 2
			res  = value.to_f
		when 3
			res  = value
		when 4
			value =~ /([0-9]+)-([0-9]+)-([0-9]+)\s+([0-9]+):([0-9]+):([0-9]+)/
			res = Time.mktime($1, $2, $3, $4, $5, $6, 0)
		when 0xA,0xB
			res = value.nil? ? [] : value.split(',').collect { |s| s.to_i }
		when 0xC
			res = value.nil? ? [] : value.split(',').collect { |s| s.to_f }
		when 0xD
			res = value.nil? ? [] : value.split(',').collect { |s|
				data =~ /([0-9]+)-([0-9]+)-([0-9]+)\s+([0-9]+):([0-9]+):([0-9]+)/
				Time.mktime($1, $2, $3, $4, $5, $6, 0)
			}				
		when 0xE
			res = value.nil? ? [] : value.split("\n").collect { |s| s.strip }
		when 0xF
			res = []
			value.each_line { |line|
				line.strip!
				next if line.empty?
				record = line.split(',')
				next unless record[0] =~ /([0-9]+)-([0-9]+)-([0-9]+)\s+([0-9]+):([0-9]+):([0-9]+)/
				record[0] = Time.mktime($1, $2, $3, $4, $5, $6, 0)
				record[1] = record[1].to_i
				res.push record
			}
		else
			$log.puts "Bad index #{index}" 
		end
		res
	end

	def compartible_types(scalar, array)
		(scalar == 0 and array == 0xA) or (scalar == 1 and array == 0xB) or (scalar == 2 and array == 0xC) or
			(scalar == 3 and array == 0xE) or (scalar == 4 and array == 0xD) or array == 0xF
	end

	def scalar_type_by_array(array)
		case array
		when 0xA then 0
		when 0xB then 1
		when 0xC then 2
		when 0xD then 4
		when 0xE then 3
		else
			$log.puts "Bad array type #{array}"
			nil
		end
	end

	def convert_condition(cmd, condition)
		
		# константы
		condition.gsub!(/\#([0-9]+)/) { $1 }

		# операторы
		condition.gsub!(/~\s*"([^"]+)"/) {
			 " LIKE '%#{$1}%' "
		}
		condition.gsub!(/\s*=\s*\[00\]/, " IS NULL ")
		condition.gsub!(/\s*!=\s*\[00\]/, " IS NOT NULL ")
		condition.gsub!(/\[([ABC][0-9A-F])\]\s+INCLUDES\s+([^\s]+)/) {
			var = $1
			value = $2
			program_error "SCALAR VARIABLE BEFORE INCLUDES OPERATOR", 7 unless var =~ /[ABC][A-F]/
			array = get_variable(cmd, var)
			if array.nil? or array.empty? then
				'FALSE'
			else
				res = []
				array.each { |element|
					element = scalar_to_string(element)
	
					if value =~ /\[([ABC][0-9A-F])\]/ then
						v2 = $1
						program_error "ARRAY VARIABLE AFTER INCLUDES OPERATOR", 7 unless v2 =~ /[ABC][0-4]/					
						var2 = get_variable(cmd, v2)
						if not var2.nil? then
							var2 = scalar_to_string(var2)
							res.push "#{element} = #{var2}"
						end
					elsif value =~ /\[([0-9])([0-9A-F])\]/ then
						res.push "#{element} = D#{$1}F#{$1}#{$2}"
					else
						res.push "#{element} = #{value}"
					end
				}
				"((#{res.join(') OR (')}))"
			end
		}

		# оставшиеся переменные
		condition.gsub!(/\[([ABC][0-9A-F])\]/) {
			variable = $1
			v = get_variable(cmd, variable)
			if v.nil? then
				'NULL'
			elsif v.kind_of? Array then
				program_error "ARRAY VARIABLE #{variable} IN CONDITION", 7
			else
				scalar_to_string(v)
			end
		}

		# индексы
		condition.gsub!(/\[([0-9])([0-9A-F])\]/) {
			"D#{$1}F#{$1}#{$2}"
		}
		
		condition
	end

	def scalar_to_string(v)
		if v.nil?
			'NULL'
		elsif v.kind_of? Time
			"\"#{v.to_s}\""
		elsif v.kind_of? String
			"\"#{v}\""
		else
			v.to_s		
		end
	end

	def calculate_cost(cmd, params)
		# это работает только для машинных команд
		
		cost = 0
		case cmd 
		when 'FINISH'
			cost = 1
		when 'CHOOSE'
			cost = 15

			if params =~ /^\[([ABC][0-9A-F])\]\s+\[([0-9A-F][0-9A-F])\]\s+IF\s+(.+)$/ then		
				dist_var = $1
				index = $2
				condition = $3

				cost += 5 unless dist_var =~ /[ABC]0/

				condition.scan(/(AND|OR|NOT|=|>|<)/) { cost += 1 }
				condition.scan(/~/) { cost += 10 }
				condition.scan(/\[([ABC][0-9A-F])\]/) { cost += 1 }
				condition.scan(/\[([0-9][2-9A-F])\]/) { cost += 1 }				
				condition.scan(/INCLUDES/) { cost += 10 }
			end
			
		when 'REQUEST'
			cost = 20

			if params =~ /^\[([ABC][0-9A-F])\]\s+\[([0-9A-F][0-9A-F])\](\s+IF\s+(.+))?$/ then		
				dist_var = $1
				index = $2
				condition = $4

				cost += 10 unless dist_var =~ /[ABC]0/

				unless condition.nil? 
					cost += 1
					condition.scan(/(AND|OR|NOT|=|>|<)/) { cost += 1 }
					condition.scan(/~/) { cost += 10 }
					condition.scan(/\[([ABC][0-9A-F])\]/) { cost += 1 }
					condition.scan(/\[([0-9][2-9A-F])\]/) { cost += 1 }				
					condition.scan(/INCLUDES/) { cost += 10 }
				end
			end

		when 'MODIFY'
			cost = 10

			if params =~ /^\[([0-9][0-9A-F])\]\s+([^\[]+|\[[ABC][0-9A-F]\])\s+\[([0-9][0-9A-F])\]\s+([^\[]+|\[[ABC][0-9A-F]\])$/ then
				select_index = $1
				select_value = $2.strip
				modify_index = $3
				modify_value = $4.strip				
	
				cost += 1 if select_value =~ /\[[ABC][0-9A-F]\]/
				cost += 1 if modify_value =~ /\[[ABC][0-9A-F]\]/
				cost += 5 unless modify_index =~ /[0-9]0/
			end			

		when 'ADD'
			cost = 30

			if params =~ /^\[D([0-9])\]\s+(.+)/
				dir_num = $1.to_i
				$2.split(',') { |pair|
					if pair.split =~ /\[([0-9][0-9A-F])\]\s+(.+)/
						index = $1
						value = $2
							
						cost += 1 if value =~ /\[[ABC][0-9A-F]\]/
					end
				}
			end

		when 'CALC'
			cost = 2
			params.scan(/\[([ABC][0-9A-F])\]/) { cost += 1 }
			params.scan(/\+|-/) { cost += 1 }
			params.scan(/\*|\/|%/) { cost += 4 }
			params.scan(/SIN|COS/) { cost += 1 }
			params.scan(/SQRT|EXP|LN/) { cost += 8 }
			params.scan(/\^/) { cost += 10 }
		when 'STAT'
			cost = 8
			params.scan(/\[([ABC][0-9A-F])\]/) { cost += 1 }
			params.scan(/\+|-/) { cost += 1 }
			params.scan(/\*|\/|%/) { cost += 4 }
			params.scan(/SIN|COS/) { cost += 1 }
			params.scan(/SQRT|EXP|LN/) { cost += 8 }
			params.scan(/\^/) { cost += 10 }
			params.scan(/SIZE/) { cost += 5 }
			params.scan(/AVG|MIN|MAX/) { cost += 10 }
		when 'RECORD'
			cost = 2
		when 'TYPE'
			cost = 10
			params.scan(/\[([ABC][0-4])\]/) { cost += 1 }
			params.scan(/\[([ABC][A-F])\]/) { cost += 4 }
		when 'ORACLE'
			cost = 0
			params.scan(/[A-Z]/) { cost += 1000 }
		when 'INTEGRAL'
			cost = 300
			iter = 0
			params.scan(/\[([ABC][0-9A-F])\]/) { cost += 1 }
			params.scan(/\+|-/) { iter += 1 }
			params.scan(/\*|\/|%/) { iter += 4 }
			params.scan(/SIN|COS/) { iter += 1 }
			params.scan(/SQRT|EXP|LN/) { iter += 8 }
			params.scan(/\^/) { iter += 10 }
			cost += iter * 20
		when 'LOOP'
			cost = 4
			params.scan(/\[([ABC][0-9A-F])\]/) { cost += 1 }
		else
			$log.puts "Bad command in time calculation #{cmd}"
			cost = 0
		end		
		return cost
	end

	def set_mode(mode)
		@mode = mode

		if @mode == :control then
			initialize_machine
		end

		unless @sound_proc_pid.nil?
			sleep 1
			Process.kill("SIGHUP", @sound_proc_pid) 
			Process.wait
		end
		@sound_proc_pid = fork() {
			case @mode
			when :command then filename = 'low.mp3'
			when :control then filename = 'medium.mp3'
			when :program then filename = 'high.mp3'
			else
				filename = 'low.mp3'
			end

			exec("mpg123 -q --loop -1 sounds/#{filename}")
		}
	end

	def initialize_machine
		@global_loop = nil
	end

	def history_add(dir, records, history)
		str = "#{Time.now.to_s},#{@operator},#{records.join(' ')},#{history}"
		
		new_id = 0
		res = @db.select("select max(HISNUMBER) from HISTORY where HISDIR = #{dir}") { |row|
			new_id = row[0].nil? ? 0 : row[0].to_i + 1
		}
		if res != 1 then
			$log.puts "Can't find maximum in history table"
			return 
		end
	
		query = "insert into HISTORY values (NULL,#{dir},#{new_id},\"#{str}\")"
		$log.puts "Inserting history #{query}"
		res = @db.modify(query)
		unless res
			$log.puts "Can't insert history"
		end
	end

	def history_get(directory, as_string = false)
		query = "select HISSTRING from HISTORY where HISDIR = #{directory} order by HISNUMBER"
		$log.puts "Quering history #{query}"
		history = []
		res = @db.select(query) { |row|
			history.push row[0]
		}
		if res.nil? or res == 0 then
			$log.puts "Empty history"				
		else	
			history_add(directory, [], "HISTORY")
		end
		if as_string
			history
		else
			history.collect { |string|
				fields = string.split(',')
				fields[1] = fields[1].to_i
				if fields[2].nil?
					fields[2] = []
				else
					fields[2] = fields[2].split(' ').collect { |s| s.to_i } 
				end
				fields
			}
		end
	end

	def calculate_integral(from, to, func)
		$log.puts "Calculating integral #{func}"
		step = 0.01
		result = 0.0	
		x = from
		while x <= to 
			func_x = func.gsub('x', x.to_s)
			query = "SELECT #{func_x}"
			data = nil
			res = @db.select(query) { |row|
				data = row[0]
			}
			if res.nil? or res != 1 then
				program_error "ERROR CALCULATING INTEGRAL", 4
			end
			result += data.to_f * step
			x += step
		end
		result = (result * 100.0).to_i.to_f / 100.0
	end
end
# ----------------------------------------------------------------------------

