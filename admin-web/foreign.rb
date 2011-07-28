# ----------------------------------------------------------------------------
class ForeignDirectory < Directory 
	def initialize()
		super
		@name = 'fore'
		@descr = 'Директория внешних связей'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D5F51 from D5') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 5)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_text('51','Номер письма', random_id.to_s)
		Output.input_select('52','Тип',[['IN','Входящее'],['OUT','Исходящее']], 'IN',false)
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('53','Респондент в Британии',values,values.first,false)
		Output.input_text('54', 'Внешний респондент')
		Output.input_text('55', 'Дата и время отправления (ГГГГ-ММ-ДД ЧЧ:ММ)')
		Output.input_large_text('5E', 'Текст запроса')
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['51']
		
		res = @db.modify("INSERT INTO D5 VALUES (" +
				values['51'] + ',"' +
				values['52'] + '",' +
				values['53'] + ',"' +
				values['54'] + '","' +
				values['55'] + '","' +
				values['5E'] + '")')

		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D5 WHERE D5F51 = #{id}") { |row|
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
		Output.input_value('51',fields[0]);
		Output.text "Номер запроса: #{fields[0]}"
		Output.input_select('52','Тип',[['IN','Входящее'],['OUT','Исходящее']], fields[1],false)
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('53','Респондент в Британии',values,fields[2],false)
		Output.input_text('54', 'Внешний респондент', fields[3])
		Output.input_text('55', 'Дата и время отправления (ГГГГ-ММ-ДД ЧЧ:ММ)', fields[4])
		Output.input_large_text('5E', 'Текст запроса', fields[5])
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('51',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['51']

		res = @db.modify('UPDATE D5 SET D5F52="' + 
				values['52'] + '",  D5F53=' +
				values['53'] + ', D5F54="' +
				values['54'] + '", D5F55="' +
				values['55'] + '", D5F5E="' +
				values['5E'] + '" WHERE D5F51 = ' + index)

		return res ? index : nil
	end

	def post_delete(values)
		index = values['51']
		res = @db.modify('DELETE FROM D5 WHERE D5F51 = ' + index)
		return res ? index : nil
	end

	def short_list

		Output.header "#{@descr}"
		Output.table_header	'Номер',
					'Тип письма',
					'Гражданин',
					'Внешний адресат',
					'Дата и время отправления',
					'Текст'

		size = @db.select('SELECT * from D5') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = row[1]
			fields[2] = Output.link_to(direct_address('gov', row[2]), row[2])
			fields[3] = row[3]
			fields[4] = row[4]
			fields[5] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
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

		Output.header "#{@descr}. Связи, относящиеся к #{id}"
		Output.table_header	'Номер',
					'Тип письма',
					'Гражданин',
					'Внешний адресат',
					'Дата и время отправления',
					'Текст'

		size = @db.select('SELECT * from D5 WHERE D5F53 = #{id}') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = row[1]
			fields[2] = Output.link_to(direct_address('gov', row[2]), row[2])
			fields[3] = row[3]
			fields[4] = row[4]
			fields[5] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		"Число найденных записей: #{size}"
		Output.text		Output.link_to(list_address(@name),"Вся директория")
	end
end
# ----------------------------------------------------------------------------

