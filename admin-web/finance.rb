# ----------------------------------------------------------------------------
class FinanceDirectory < Directory 
	def initialize()
		super
		@name = 'fin'
		@descr = 'Директория финансов'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D2F21 from D2') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 2)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);

		Output.input_text('21','Номер счета',random_id.to_s)
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('22','Владелец',values,values.empty? ? nil : values.first.first,false)
		Output.input_select_multiple('23','Пайщики',values)
		Output.input_text('24','Баланс')
		Output.input_large_text('25','История транзакций в виде -- дата+время,номер счета отправителя, +/- сумма, описание')
		values = []		
		@db.select('SELECT D6F61,D6F62,D6F63 from D6 ORDER BY D6F61') { |row|
			values.push([row[0], "#{row[1]} #{row[2]} (\##{row[0]})"])
		}
		Output.input_select_multiple('26','Корабли',values)
		Output.input_text('27','Собственность')
		Output.input_text('28','Черные металлы',0)
		Output.input_text('29','Цветные металлы',0)
		Output.input_text('2A','Уголь',0)
		Output.input_text('2B','Каучук',0)
		Output.input_text('2C','Химия',0)
		Output.input_large_text('2E','Дополнительные сведения')
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['21']

		res = @db.modify("INSERT INTO D2 VALUES (" +
				values['21'] + ',"' +
				values['22'] + '",' +
				((not values.has_key? '23') ? 'NULL': "\"" + values.params['23'].join(',') + "\"") + ',"' +
				values['24'] + '","' +
				values['25'] + '",' +
				((not values.has_key? '26') ? 'NULL': "\"" + values.params['26'].join(',') + "\"") + ',"' +
				values['27'] + '","' +
				values['28'] + '","' +
				values['29'] + '","' +
				values['2A'] + '","' +
				values['2B'] + '","' +
				values['2C'] + '","' +
				values['2E'] + '")')
		
		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D2 WHERE D2F21 = #{id}") { |row|
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
		Output.input_value('21',fields[0]);
		Output.input_value('id',fields[0]);
		Output.text("Номер счета: #{fields[0]}")
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('22','Владелец',values,fields[1],false)
		Output.input_select_multiple('23','Пайщики',values,fields[2])
		Output.input_text('24','Баланс',fields[3])
		Output.input_large_text('25','История транзакций в виде -- дата+время,номер счета отправителя, +/- сумма, описание',fields[4])
		values = []		
		@db.select('SELECT D6F61,D6F62,D6F63 from D6 ORDER BY D6F61') { |row|
			values.push([row[0], "#{row[1]} #{row[2]} (\##{row[0]})"])
		}
		Output.input_select_multiple('26','Корабли',values,fields[5])
		Output.input_text('27','Собственность',fields[6])
		Output.input_text('28','Черные металлы',fields[7])
		Output.input_text('29','Цветные металлы',fields[8])
		Output.input_text('2A','Уголь',fields[9])
		Output.input_text('2B','Каучук',fields[10])
		Output.input_text('2C','Химия',fields[11])
		Output.input_large_text('2E','Дополнительные сведения',fields[12])
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('21',fields[0]);
		Output.input_value('id',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['21']

		res = @db.modify('UPDATE D2 SET D2F22=' +
				values['22'] + ', D2F23=' +
				((not values.has_key? '23') ? 'NULL': "\"" + values.params['23'].join(',') + "\"") + ', D2F24=' +
				values['24'] + ', D2F25="' +
				values['25'] + '", D2F26=' +
				((not values.has_key? '26') ? 'NULL': "\"" + values.params['26'].join(',') + "\"") + ', D2F27="' +
				values['27'] + '", D2F28=' +
				values['28'] + ', D2F29=' +
				values['29'] + ', D2F2A=' +
				values['2A'] + ', D2F2B=' +
				values['2B'] + ', D2F2C=' +
				values['2C'] + ', D2F2E="' +
				values['2E'] + '" WHERE D2F21 = ' + index)
		
		return res ? index : nil
	end

	def post_delete(values)
		index = values['21']
		res = @db.modify('DELETE FROM D2 WHERE D2F21 = ' + index)
		return res ? index : nil
	end

	def short_list
		Output.header "#{@descr}"
		Output.table_header	'Номер счета', 	
					'Владелец',		
					'Пайщики',		
					'Баланс',			
					'История',			
					'Корабли',
					'Собственность',
					'Черные металлы',
					'Цветные металлы',
					'Уголь',
					'Каучук',
					'Химия',
					'Дополнительно'					

		size = @db.select('SELECT * from D2') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = Output.link_to(direct_address('gov', row[1]), row[1])
			fields[2] = (row[2].nil? or row[2].empty?) ? 'НЕТ': row[2].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[3] = sprintf("%10.2f",row[3])
			fields[4] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")	
			fields[5] = (row[5].nil? or row[5].empty?) ? 'НЕТ': row[5].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('fleet',num), num) + ' '
			}
			fields[6] = (row[6].nil? or row[6].strip.empty?) ? 'НЕТ': row[6]
			(7..12).each { |i|
				fields[i] = row[i]
			}
			fields[12] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")	
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		Output.link_to(history_address(@name),"Редактировать историю доступа к директории")
		Output.text		"Число записей: #{size}"
		Output.text		Output.link_to(add_address(@name),"Добавить новую запись")
		Output.text		Output.link_to(index_address,"Вернуться в начало")
	end

	def query_list(field,value)
		return if field != 'owner_id'
		id = value

		Output.header "#{@descr}. Счета, принадлежащие #{id}"
		Output.table_header	'Номер счета', 	
					'Владелец',		
					'Пайщики',		
					'Баланс',			
					'История',			
					'Корабли',
					'Собственность',
					'Черные металлы',
					'Цветные металлы',
					'Уголь',
					'Каучук',
					'Химия',
					'Дополнительно'					

		size = @db.select("SELECT * from D2 WHERE D2F22 = #{id} OR D2F23 LIKE '%#{id}%'") { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = Output.link_to(direct_address('gov', row[1]), row[1])
			fields[2] = (row[2].nil? or row[2].empty?) ? 'НЕТ': row[2].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[3] = sprintf("%10.2f",row[3])
			fields[4] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")	
			fields[5] = (row[5].nil? or row[5].empty?) ? 'НЕТ': row[5].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('fleet',num), num) + ' '
			}
			fields[6] = (row[6].nil? or row[6].strip.empty?) ? 'НЕТ': row[6]
			(7..12).each { |i|
				fields[i] = row[i]
			}
			fields[12] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")	
			Output.table_row *fields
		}
		Output.table_footer
		Output.text		"Число найденных записей: #{size}"
		Output.text		Output.link_to(list_address(@name),"Вся директория")
	end
end
# ----------------------------------------------------------------------------

