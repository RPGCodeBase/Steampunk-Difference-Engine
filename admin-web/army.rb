# ----------------------------------------------------------------------------
class ArmyDirectory < Directory 
	def initialize()
		super
		@name = 'army'
		@descr = 'Директория Военного министерства'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D7F71 from D7') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 7)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_text('71','Номер армии/флота', random_id)
		Output.input_text('72','Тип армии/флота')
		Output.input_text('73','Название', "Division #{random_id}")
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('74','Командующий',values,values.first,false)
		Output.input_text('75','Местоположение')
		Output.input_large_text('76','Текущий состав (армия)')
		values = []		
		@db.select('SELECT D6F61,D6F62,D6F63 from D6 ORDER BY D6F61') { |row|
			values.push([row[0], "#{row[1]} #{row[2]} (\##{row[0]})"])
		}
		Output.input_select_multiple('77','Текущий состав (флот)',values)
		Output.input_large_text('78','История боевых действий')
		Output.input_large_text('7E','Дополнительные сведения')
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['71']

		res = @db.modify("INSERT INTO D7 VALUES (" +
				values['71'] + ',"' +
				values['72'] + '","' +
				values['73'] + '",' +
				((not values.has_key? '74') ? 'NULL': values['74']) + ',"' +
				values['75'] + '","' +
				values['76'] + '",' +
				((not values.has_key? '77') ? 'NULL': "\"" + values.params['77'].join(',') + "\"") + ',"' +
				values['78'] + '","' +
				values['7E'] + '")')
	
		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D7 WHERE D7F71 = #{id}") { |row|
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
		Output.input_value('71',fields[0]);
		Output.text("Номер армии/флота: #{fields[0]}")	

		Output.input_text('72','Тип армии/флота', fields[1])
		Output.input_text('73','Название', fields[2])
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('74','Командующий',values,fields[3])
		Output.input_text('75','Местоположение',fields[4])
		Output.input_large_text('76','Текущий состав (армия)',fields[5])
		values = []		
		@db.select('SELECT D6F61,D6F62,D6F63 from D6 ORDER BY D6F61') { |row|
			values.push([row[0], "#{row[1]} #{row[2]} (\##{row[0]})"])
		}
		Output.input_select_multiple('77','Текущий состав (флот)',values, fields[6])
		Output.input_large_text('78','История боевых действий', fields[7])
		Output.input_large_text('7E','Дополнительные сведения', fields[8])
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('71',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['71']

		res = @db.modify('UPDATE D7 SET D7F72="' +
				values['72'] + '", D7F73="' +
				values['73'] + '", D7F74=' +
				((not values.has_key? '74') ? 'NULL': values['74']) + ', D7F75="' +
				values['75'] + '", D7F76="' +
				values['76'] + '", D7F77=' +
				((not values.has_key? '77') ? 'NULL': "\"" + values.params['77'].join(',') + "\"") + ', D7F78="' +
				values['78'] + '", D7F7E="' + values['7E'] + '" WHERE D7F71 = ' + index)

		return res ? index : nil
	end

	def post_delete(values)
		index = values['71']
		res = @db.modify('DELETE FROM  D7 WHERE D7F71 = ' + index)
		return res ? index : nil
	end

	def short_list

		Output.header "#{@descr}"
		Output.table_header	'Номер',
					'Тип армии/флота',
					'Название',
					'Командующий',
					'Местоположение',
					'Текущий состав (для армии)',
					'Состав кораблей (для армии)',
					'История',
					'Дополнительно'

		size = @db.select('SELECT * from D7') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = row[1]
			fields[2] = row[2]
			fields[3] = Output.link_to(direct_address('gov', row[3]), row[3])
			fields[4] = row[4]
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

