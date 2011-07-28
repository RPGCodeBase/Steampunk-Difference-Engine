# ----------------------------------------------------------------------------
class CrimeDirectory < Directory 
	def initialize()
		super
		@name = 'crime'
		@descr = 'Директория преступлений'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D1F11 from D1') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 1)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_text('11','Номер преступления', random_id.to_s)
		Output.input_select('12','Статус',[['OPEN','Открыто'],['CLOSED','Закрыто']], 'OPEN',false)
		Output.input_text('13','Тип, статья')
		Output.input_text('14','Место')
		Output.input_text('15','Дата и время (ГГГГ-ММ-ДД ЧЧ:ММ)')
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select_multiple('16','Подозреваемые',values)
		Output.input_select_multiple('17','Свидетели',values)
		Output.input_select_multiple('18','Потерпевшие',values)		
		Output.input_large_text('1E','Дополнительные сведения')
		Output.input_check('VALID','<strong>Эта запись является игровой</strong>', true)
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['11']

		res = @db.modify("INSERT INTO D1 VALUES (" +
				values['11'] + ',"' +
				values['12'] + '","' +
				values['13'] + '","' +
				values['14'] + '","' +
				values['15'] + '",' +
				((not values.has_key? '16') ? 'NULL': "\"" + values.params['16'].join(',') + "\"") + ',' +
				((not values.has_key? '17') ? 'NULL': "\"" + values.params['17'].join(',') + "\"") + ',"' +
				values['1E'] + '", ' + 
				((values.params.has_key? 'VALID') ? 'TRUE' : 'FALSE') + ', ' + 
				((not values.has_key? '18') ? 'NULL': "\"" + values.params['18'].join(',') + "\"") + ')')
		
		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D1 WHERE D1F11 = #{id}") { |row|
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
		Output.input_value('11',fields[0]);		

		Output.text "Номер преступления: #{fields[0]}"
		Output.input_select('12','Статус',[['OPEN','Открыто'],['CLOSED','Закрыто']], fields[1],false)
		Output.input_text('13','Тип, статья',fields[2])
		Output.input_text('14','Место',fields[3])
		Output.input_text('15','Дата и время (ГГГГ-ММ-ДД ЧЧ:ММ)',fields[4])
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select_multiple('16','Подозреваемые',values,fields[5])
		Output.input_select_multiple('17','Свидетели',values,fields[6])
		Output.input_select_multiple('18','Потерпевшие',values,fields[9])
		Output.input_large_text('1E','Дополнительные сведения',fields[7])
		Output.input_check('VALID','<strong>Эта запись является игровой</strong>', fields[8] != '0')
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('11',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['11']

		res = @db.modify('UPDATE D1 SET D1F12="' +
				values['12'] + '", D1F13="' +
				values['13'] + '", D1F14="' +
				values['14'] + '", D1F15="' +
				values['15'] + '", D1F16=' +
				((not values.has_key? '16') ? 'NULL': "\"" + values.params['16'].join(',') + "\"") + ', D1F17=' +
				((not values.has_key? '17') ? 'NULL': "\"" + values.params['17'].join(',') + "\"") + ', D1F18=' +
				((not values.has_key? '18') ? 'NULL': "\"" + values.params['18'].join(',') + "\"") + ', D1F1E="' +
				values['1E'] + '", D1VALID = ' + 
				((values.params.has_key? 'VALID') ? 'TRUE' : 'FALSE') +
				' WHERE D1F11 = ' + index)
		
		return res ? index : nil
	end

	def post_delete(values)
		index = values['11']
		res = @db.modify('DELETE FROM D1 WHERE D1F11 = ' + index)
		return res ? index : nil
	end

	def short_list

		Output.header "#{@descr}"
		Output.table_header	'Номер',
					'Статус',
					'Тип, статья',
					'Место',
					'Дата и время',
					'Подозреваемые',
					'Свидетели',
					'Потерпевшие',
					'Дополнительные сведения',
					'В ИГРЕ'

		size = @db.select('SELECT D1F11,D1F12,D1F13,D1F14,D1F15,D1F16,D1F17,D1F18,D1F1E,D1VALID from D1 ORDER BY D1VALID') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			(1..4).each { |i| fields[i] = row[i] }
			fields[5] = (row[5].nil? or row[5].empty?) ? 'НЕТ': row[5].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[6] = (row[6].nil? or row[6].empty?) ? 'НЕТ': row[6].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[7] = (row[7].nil? or row[7].empty?) ? 'НЕТ': row[7].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[8] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[9] = (row[9] != '0') ? 'ДА' : 'НЕТ'
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		Output.link_to(history_address(@name),"Редактировать историю доступа к директории")
		Output.text		"Число записей: #{size}"
		Output.text		Output.link_to(add_address(@name),"Добавить новую запись")
		Output.text		Output.link_to(index_address,"Вернуться в начало")
	end

	def query_list(field,value)
		return if field != 'related_id'
		id = value

		Output.header "#{@descr}. Преступления, связанные с #{id}"
		Output.table_header	'Номер',
					'Статус',
					'Тип, статья',
					'Место',
					'Дата и время',
					'Подозреваемые',
					'Свидетели',
					'Потерпевшие',
					'Дополнительные сведения',
					'В ИГРЕ'

		size = @db.select("SELECT D1F11,D1F12,D1F13,D1F14,D1F15,D1F16,D1F17,D1F18,D1F1E,D1VALID from D1 WHERE D1F16 LIKE '%#{id}%' OR D1F17 LIKE '%#{id}%' OR D1F18 LIKE '%#{id}%'") { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			(1..4).each { |i| fields[i] = row[i] }
			fields[5] = (row[5].nil? or row[5].empty?) ? 'НЕТ': row[5].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[6] = (row[6].nil? or row[6].empty?) ? 'НЕТ': row[6].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[7] = (row[7].nil? or row[7].empty?) ? 'НЕТ': row[7].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[8] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[9] = (row[9] != '0') ? 'ДА' : 'НЕТ'
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		"Число найденных записей: #{size}"
		Output.text		Output.link_to(list_address(@name),"Вся директория")
	end
end
# ----------------------------------------------------------------------------

