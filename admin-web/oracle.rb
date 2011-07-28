# ----------------------------------------------------------------------------
class OracleDirectory < Directory 
	def initialize()
		super
		@name = 'oracle'
		@descr = 'Директория прогнозов'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D4F41 from D4') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 4)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_text('41','Номер запроса', random_id.to_s)
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('42','Автор запроса',values,values.first,false)
		Output.input_large_text('43', 'Текст запроса')
		Output.input_text('44', 'Зависимость')
		Output.input_large_text('45', 'Ответ')
		Output.input_check('VALID','<strong>Расчет произведен</strong>', false)
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['41']
		
		res = @db.modify("INSERT INTO D4 VALUES (" +
				values['41'] + ',' +
				values['42'] + ',"' +
				values['43'] + '","' +
				values['44'] + '","' +
				values['45'] + '",NULL,' +
				((values.params.has_key? 'VALID') ? 'TRUE' : 'FALSE') + ')')

		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D4 WHERE D4F41 = #{id}") { |row|
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
		Output.input_value('41',fields[0]);		
		Output.text "Номер запроса: #{fields[0]}"
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('42','Автор запроса',values,fields[1],false)
		Output.input_large_text('43', 'Текст запроса',fields[2])
		Output.input_text('44', 'Зависимость',fields[3])
		Output.input_large_text('45', 'Ответ',fields[4])
		Output.input_check('VALID','<strong>Расчет произведен</strong>', fields[6] != '0')
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('41',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['41']

		res = @db.modify('UPDATE D4 SET D4F42=' + 
				values['42'] + ',  D4F43="' +
				values['43'] + '", D4F44="' +
				values['44'] + '", D4F45="' +
				values['45'] + '", D4VALID=' +
				((values.params.has_key? 'VALID') ? 'TRUE' : 'FALSE') + ' WHERE D4F41 = ' + index)

		return res ? index : nil
	end

	def post_delete(values)
		index = values['41']
		res = @db.modify('DELETE FROM D4 WHERE D4F41 = ' + index)
		return res ? index : nil
	end

	def short_list

		Output.header "#{@descr}"
		Output.table_header	'Номер',
					'Автор запроса',
					'Текст запроса',
					'Зависимость',
					'Ответ',
					'Расчет произведен'

		size = @db.select('SELECT * from D4 ORDER BY D4VALID') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = Output.link_to(direct_address('gov', row[1]), row[1])
			fields[2] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[3] = row[3]
			fields[4] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[5] = (row[6] != '0') ? 'ДА' : 'НЕТ'
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		Output.link_to(history_address(@name),"Редактировать историю доступа к директории")
		Output.text		"Число записей: #{size}"
		Output.text		Output.link_to(add_address(@name),"Добавить новую запись")
		Output.text		Output.link_to(index_address,"Вернуться в начало")
	end

	def query_list(field,value)
		return if field != 'author_id'
		id = value

		Output.header "#{@descr}. Запросы, принадлежащие #{id}"

		Output.table_header	'Номер',
					'Автор запроса',
					'Текст запроса',
					'Зависимость',
					'Ответ',
					'Расчет произведен'

		size = @db.select('SELECT * from D4 WHERE D4F42 = #{id}') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = Output.link_to(direct_address('gov', row[1]), row[1])
			fields[2] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[3] = row[3]
			fields[4] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[5] = (row[6] != '0') ? 'ДА' : 'НЕТ'
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		"Число найденных записей: #{size}"
		Output.text		Output.link_to(list_address(@name),"Вся директория")
	end
end
# ----------------------------------------------------------------------------

