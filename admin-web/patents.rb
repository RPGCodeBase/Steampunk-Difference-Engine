# ----------------------------------------------------------------------------
class PatentsDirectory < Directory 
	def initialize()
		super
		@name = 'pat'
		@descr = 'Директория патентов'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D3F31 from D3') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 3)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_text('31','Номер патента', random_id.to_s)
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select_multiple('32','Подозреваемые',values)
		Output.input_text('33', 'Название')
		Output.input_select('34','Научная область',['механика', 'электрика', 'оптика', 'акустика',
							    'химия', 'магнетизм', 'термодинамика', 'кинетика', 'иное'], 'механика',false)
		Output.input_large_text('35', 'Вид действия')
		Output.input_text('36', 'Дата выдачи (ГГГГ-ММ-ДД)')
		Output.input_text('39', 'Набор слов (через пробел)')
		Output.input_large_text('37', 'Формула (если есть)')
		Output.input_text('38', 'Результат расчета (если есть)')
		Output.input_large_text('3E', 'Дополнительные ограничения')
		Output.input_check('VALID','<strong>Эта запись является игровой</strong>', true)
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['31']
		
		res = @db.modify("INSERT INTO D3 VALUES (" +
				values['31'] + ',' +
				((not values.has_key? '32') ? 'NULL': "\"" + values.params['32'].join(',') + "\"") + ',"' +
				values['33'] + '","' +
				values['34'] + '","' +
				values['35'] + '","' +
				values['36'] + '","' +
				values['3E'] + '",' +
				((values.params.has_key? 'VALID') ? 'TRUE' : 'FALSE') + ',"' + 
				values['37'] + '","' +
				values['38'] + '","' +
				values['39'] + '")')

		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D3 WHERE D3F31 = #{id}") { |row|
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
		Output.input_value('31',fields[0]);		
		Output.text "Номер патента: #{fields[0]}"
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select_multiple('32','Подозреваемые',values,fields[1])
		Output.input_text('33', 'Название',fields[2])
		Output.input_select('34','Научная область',['механика', 'электрика', 'оптика', 'акустика',
							    'химия', 'магнетизм', 'термодинамика', 'кинетика', 'иное'], fields[3],false)
		Output.input_large_text('35', 'Вид действия',fields[4])
		Output.input_text('36', 'Дата выдачи (ГГГГ-ММ-ДД)',fields[5])
		Output.input_text('39', 'Набор слов (через пробел)',fields[10])
		Output.input_large_text('37', 'Формула (если есть)',fields[8])
		Output.input_text('38', 'Результат расчета (если есть)',fields[9])
		Output.input_large_text('3E', 'Дополнительные ограничения',fields[6])
		Output.input_check('VALID','<strong>Эта запись является игровой</strong>', fields[7] != '0')
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('31',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['31']

		res = @db.modify('UPDATE D3 SET D3F32=' +
				((not values.has_key? '32') ? 'NULL': "\"" + values.params['32'].join(',') + "\"") + ', D3F33="' +
				values['33'] + '", D3F34="' +
				values['34'] + '", D3F35="' +
				values['35'] + '", D3F36="' +
				values['36'] + '", D3F3E="' +
				values['3E'] + '", D3VALID=' +
				((values.params.has_key? 'VALID') ? 'TRUE' : 'FALSE') + ', D3F37="' + 
				values['37'] + '", D3F38="' +
				values['38'] + '", D3F39="' +
				values['39'] + '" WHERE D3F31 = ' + index)

		return res ? index : nil
	end

	def post_delete(values)
		index = values['31']
		res = @db.modify('DELETE FROM D3 WHERE D3F31 = ' + index)
		return res ? index : nil
	end

	def short_list

		Output.header "#{@descr}"
		Output.table_header	'Номер',
					'Первооткрыватели',
					'Название',
					'Научная область',
					'Вид действия',
					'Дата и время выдачи',
					'Набор слов',
					'Результат расчета',
					'Мат. формула',
					'Дополнительные ограничения',
					'В ИГРЕ'

		size = @db.select('SELECT * from D3 ORDER BY D3VALID') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = (row[1].nil? or row[1].empty?) ? 'НЕТ': row[1].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[2] = row[2]
			fields[3] = row[3]
			fields[4] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[5] = row[5]
			fields[6] = row[10]
			fields[7] = row[9]
			fields[8] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[9] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[10] = (row[7] != '0') ? 'ДА' : 'НЕТ'
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

		Output.header "#{@descr}. Патенты, принадлежащие #{id}"
		Output.table_header	'Номер',
					'Первооткрыватели',
					'Название',
					'Научная область',
					'Вид действия',
					'Дата и время выдачи',
					'Набор слов',
					'Результат расчета',
					'Мат. формула',
					'Дополнительные ограничения',
					'В ИГРЕ'

		size = @db.select("SELECT * from D3 WHERE D3F32 LIKE '%#{id}%'") { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			fields[1] = (row[1].nil? or row[1].empty?) ? 'НЕТ': row[1].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address('gov',num), num) + ' '
			}
			fields[2] = row[2]
			fields[3] = row[3]
			fields[4] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[5] = row[5]
			fields[6] = row[10]
			fields[7] = row[9]
			fields[8] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[9] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[10] = (row[7] != '0') ? 'ДА' : 'НЕТ'
			Output.table_row *fields
		}

		Output.table_footer
		Output.text		"Число найденных записей: #{size}"
		Output.text		Output.link_to(list_address(@name),"Вся директория")
	end
end
# ----------------------------------------------------------------------------

