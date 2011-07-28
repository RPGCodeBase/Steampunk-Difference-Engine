# ----------------------------------------------------------------------------
class GovernmentDirectory < Directory 
	def initialize()
		super
		@name = 'gov'
		@descr = 'Директория граждан'
		@db = Database.new
	end

	def add
		numbers = []
		@db.select('select D0F01 from D0') { |row| numbers.push(row[0].to_i) }
		random_id = gen_random_id(numbers, 1)

		Output.header "#{@descr}. Добавить запись"
		Output.form_header(post_add_address)
		Output.input_value('post','');
		Output.input_value('dir',@name);
		Output.input_text('01','Личный индекс', random_id.to_s)
		Output.input_select('02','Статус',[['ALIVE','Жив'],['RIP','Мертв']], 'ALIVE',false)
		Output.input_text('03','Фамилия')
		Output.input_text('04','Имя')
		Output.input_select('05','Пол',[['MALE','Мужчина'],['FEMALE','Женщина']], 'MALE',false)
		Output.input_text('06','Возраст')
		Output.input_text('07','Социальный статус')
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 WHERE D0F05 = "MALE" ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('08','Отец',values)
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 WHERE D0F05 = "FEMALE" ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('09','Мать',values)
		Output.input_text('0A','Внешний вид')		

		values = []
		@db.select('SELECT D0F01,D0F03,D0F04,D0F05 from D0 ORDER BY D0F05,D0F03') { |row|
			values.push([row[0], "#{row[3] == 'MALE'? '(м)':'(ж)'} #{row[1]} #{row[2]}"])
		}
		Output.input_select('0B','Супруг(а)',values)
		Output.input_select_multiple('0C','Дети',values)
		Output.input_text('0D','Код')
		Output.input_large_text('0E','Дополнительные сведения')
		Output.submit('Добавить запись в директорию')
		Output.form_footer
	end

	def post_add(values)
		index = values['01']

		res = @db.modify("INSERT INTO D0 VALUES (" +
				values['01'] + ',"' +
				values['02'] + '","' +
				values['03'] + '","' +
				values['04'] + '","' +
				values['05'] + '","' +
				values['06'] + '","' +
				values['07'] + '",' +
				((not values.has_key? '08') ? 'NULL': values['08']) + ',' +
				((not values.has_key? '09') ? 'NULL': values['09']) + ',"' +
				values['0A'] + '",' +
				((not values.has_key? '0B') ? 'NULL': values['0B']) + ', ' +
				((not values.has_key? '0C') ? 'NULL': "\"" + values.params['0C'].join(',') + "\"") + ',"' +
				values['0E'] + '",' + 
				(((values.has_key? '0D') and (values['0D'].length > 0)) ? values['0D'] : 'NULL') + ')')
		
		return res ? index : nil
	end

	def field(id)

		fields = []
		res = @db.select("SELECT * from D0 WHERE D0F01 = #{id}") { |row|
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
		Output.input_value('01',fields[0]);		
		Output.text("Личный индекс: #{fields[0]}")
		Output.input_select('02','Статус',[['ALIVE','Жив'],['RIP','Мертв']], fields[1], false)
		Output.input_text('03','Фамилия', fields[2])
		Output.input_text('04','Имя', fields[3])
		Output.input_select('05','Пол',[['MALE','Мужчина'],['FEMALE','Женщина']], fields[4], false)
		Output.input_text('06','Возраст', fields[5])
		Output.input_text('07','Социальный статус', fields[6])
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 WHERE D0F05 = "MALE" ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('08','Отец',values, fields[7])
		values = []
		@db.select('SELECT D0F01,D0F03,D0F04 from D0 WHERE D0F05 = "FEMALE" ORDER BY D0F03') { |row|
			values.push([row[0], "#{row[1]} #{row[2]}"])
		}
		Output.input_select('09','Мать',values, fields[8])
		Output.input_text('0A','Внешний вид', fields[9])		

		values = []
		@db.select('SELECT D0F01,D0F03,D0F04,D0F05 from D0 ORDER BY D0F05,D0F03') { |row|
			values.push([row[0], "#{row[3] == 'MALE'? '(м)':'(ж)'} #{row[1]} #{row[2]}"])
		}
		Output.input_select('0B','Супруг(а)',values, fields[10])
		Output.input_select_multiple('0C','Дети',values, fields[11])
		Output.input_text('0D','Код',fields[13])
		Output.input_large_text('0E','Дополнительные сведения', fields[12])
		Output.submit('Изменить запись в директории')
		Output.form_footer
		Output.form_header(post_delete_address)
		Output.input_value('dir',@name);
		Output.input_value('id',fields[0]);
		Output.input_value('01',fields[0]);
		Output.input_check('delete','Да, я уверен, эту запись нужно удалить ');
		Output.submit('УДАЛИТЬ')
		Output.form_footer

		Output.text Output.link_to(list_address(@name),"Вернуться к директории")
	end

	def post_field(values)
		index = values['01']

		res = @db.modify('UPDATE D0 SET D0F02="' +
				values['02'] + '", D0F03="' +
				values['03'] + '", D0F04="' +
				values['04'] + '", D0F05="' +
				values['05'] + '", D0F06="' +
				values['06'] + '", D0F07="' +
				values['07'] + '", D0F08=' +
				((not values.has_key? '08') ? 'NULL': values['08']) + ', D0F09=' +
				((not values.has_key? '09') ? 'NULL': values['09']) + ', D0F0A="' +
				values['0A'] + '", D0F0B=' +
				((not values.has_key? '0B') ? 'NULL': values['0B']) + ', D0F0C=' +
				((not values.has_key? '0C') ? 'NULL': "\"" + values.params['0C'].join(',') + "\"") + 
				', D0F0E="' + values['0E'] + '", D0F0D=' +
				(((values.has_key? '0D') and (values['0D'].length > 0)) ? values['0D'] : 'NULL') + ' WHERE D0F01 = ' + index)
		
		return res ? index : nil
	end

	def post_delete(values)
		index = values['01']
		res = @db.modify('DELETE FROM D0 WHERE D0F01 = ' + index)
		return res ? index : nil
	end

	def short_list

		Output.header "#{@descr}"
		Output.table_header	'Личный индекс', 	#0
					'Статус',		#1
					'Фамилия',		#2
					'Имя',			#3
					'Пол',			#4
					'Возраст',		#5
					'Социальный статус',	#6
					'Отец',			#7
					'Мать',			#8
					'Внешний вид',		#9
					'Супруг(а)',		#10
					'Дети',			#11
					'Дополнительные сведения', #12
					'Код', 
					'Счета (finance)',	#13
					'Дела (crime)',		#14
					'Патенты (patents)'	#15

		size = @db.select('SELECT * from D0') { |row|
			fields = []
			fields[0] = Output.link_to(direct_address(@name, row[0]), row[0])
			(1..4).each { |i| fields[i] = row[i] }
			fields[5] = row[5].split(' ').first
			fields[6] = row[6]
			fields[7] = row[7].nil? ? 'НЕТ': Output.link_to(direct_address(@name, row[7]), row[7])
			fields[8] = row[8].nil? ? 'НЕТ': Output.link_to(direct_address(@name, row[8]), row[8])
			fields[9] = row[9]
			fields[10] = row[10].nil? ? 'НЕТ': Output.link_to(direct_address(@name, row[10]), row[10])
			fields[11] = (row[11].nil? or row[11].empty?) ? 'НЕТ': row[11].split(',').collect { |num|
				num.strip!
				Output.link_to(direct_address(@name,num), num) + ' '
			}
			fields[12] = Output.link_to(direct_address(@name, row[0]), "Подробнее...")
			fields[13] = row[13].nil? ? 'НЕТ' : row[13]
			fields[14] = Output.link_to(query_list_address('fin', 'owner_id', row[0]), "См. счета")
			fields[15] = Output.link_to(query_list_address('crime', 'related_id', row[0]), "См. связанные дела")
			fields[16] = Output.link_to(query_list_address('pat', 'author_id', row[0]), "См. патенты")
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

