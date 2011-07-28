# ----------------------------------------------------------------------------
class FleetDirectory < Directory 
	def initialize()
		super
		@name = 'fleet'
		@descr = 'Директория флота'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D6F61 from D6') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 6)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_text('61','Номер корабля', random_id)
		Output.input_text('62','Тип')
		Output.input_text('63','Название', "HMS-#{random_id}")
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('64','Владелец',values)
		Output.input_select('65','Капитан',values)
		Output.input_text('66','Грузоподъемность')
		Output.input_text('67','Местоположение')
		Output.input_large_text('68','История перемещений')
		Output.input_large_text('6E','Дополнительные сведения')
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['61']

		res = @db.modify("INSERT INTO D6 VALUES (" +
				values['61'] + ',"' +
				values['62'] + '","' +
				values['63'] + '",' +
				((not values.has_key? '64') ? 'NULL': values['64']) + ',' +
				((not values.has_key? '65') ? 'NULL': values['65']) + ',' +
				values['66'] + ',"' +
				values['67'] + '","' +
				values['68'] + '","' +
				values['6E'] + '")')
	
		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D6 WHERE D6F61 = #{id}") { |row|
			fields = row
		}

		if res.nil? or res == 0 then
			Output.text	"Неверный индекс #{id}."
			Output.text Output.link_to(list_address(@name),"Вернуться к директории")
			return nil
		end

		Output.header "#{@descr}. Изменить запись с индексом #{id}"
		Output.form_header(post_field_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('61',fields[0]);
		Output.text("Номер корабля: #{fields[0]}")	
		Output.input_text('62','Тип',fields[1])
		Output.input_text('63','Название',fields[2])
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('64','Владелец',values,fields[3])
		Output.input_select('65','Капитан',values,fields[4])
		Output.input_text('66','Грузоподъемность',fields[5])
		Output.input_text('67','Местоположение',fields[6])
		Output.input_large_text('68','История перемещений',fields[7])
		Output.input_large_text('6E','Дополнительные сведения',fields[8])
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('61',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['61']

		res = @db.modify('UPDATE D6 SET D6F62="' +
				values['62'] + '", D6F63="' +
				values['63'] + '", D6F64=' +
				((not values.has_key? '64') ? 'NULL': values['64']) + ', D6F65=' +
				((not values.has_key? '65') ? 'NULL': values['65']) + ', D6F66="' +
				values['66'] + '", D6F67="' +
				values['67'] + '", D6F68="' +
				values['68'] + '", D6F6E="' + values['6E'] + '" WHERE D6F61 = ' + index)

		return res ? index : nil
	end

	def post_delete(values)
		index = values['61']
		res = @db.modify('DELETE FROM D6 WHERE D6F61 = ' + index)
		return res ? index : nil
	end

	def short_list

		Output.header "#{@descr}"
		Output.table_header	'Номер корабля',
					'Тип',
					'Название',
					'Владелец',
					'Капитан',
					'Грузоподъемность',
					'Местоположение',
					'История перемещений',
					'Дополнительно'

		size = @db.select('SELECT * from D6') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = row[1]
			fields[2] = row[2]
			fields[3] = row[3].nil? ? 'НЕТ': Output.link_to(direct_address('gov', row[3]), row[3])
			fields[4] = row[4].nil? ? 'НЕТ': Output.link_to(direct_address('gov', row[4]), row[4])
			fields[5] = row[5]
			fields[6] = row[6]
			fields[7] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[8] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		Output.link_to(history_address(@name),"Редактировать историю доступа к директории")
		Output.text		"Число записей: #{size}"
		Output.text		Output.link_to(add_address(@name),"Добавить новую запись")
		Output.text		Output.link_to(index_address,"Вернуться в начало")
	end

	def query_list(field,value)
	end
end
# ----------------------------------------------------------------------------

