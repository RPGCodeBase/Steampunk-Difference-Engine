#!/usr/bin/ruby
# ----------------------------------------------------------------------------
require 'cgi'
require 'directory'
# ----------------------------------------------------------------------------
d = Directory.new
db = Database.new
# ----------------------------------------------------------------------------
Output.start
Output.header 'Проверка ссылочной целостности'
# ----------------------------------------------------------------------------
Output.header 'Директория граждан', 2
people = []
db.select("select D0F01,D0F08,D0F09 from D0 WHERE D0F08 IS NOT NULL OR D0F09 IS NOT NULL") { |row|
	people.push([
		row[0],
		row[1].nil? ? '0': row[1],
		row[2].nil? ? '0': row[2]])
}

people.each { |p|
	child = p[0]
	db.select("select D0F01,D0F0C from D0 where D0F01 = #{p[1]} OR D0F01 = #{p[2]}") { |row|
		parent = row[0]
		children = row[1]
		unless children.include?(child)
			Output.text 'Родительская запись ' + Output.link_to(d.direct_address('gov',parent), parent) +
				' не содержит ссылки на ребенка ' + Output.link_to(d.direct_address('gov',child), child)
		end
	}
}

people = []
db.select("select D0F01,D0F05,D0F0C from D0 where LENGTH(D0F0C) > 0") { |row|
	people.push([row[0], row[1], row[2]])
}

people.each { |p|
	parent = p[0]
	sex = p[1]
	p[2].split(',').each { |child|
		child.strip!
		res = db.select("select D0F01,D0F08,D0F09 from D0 where D0F01 = #{child}") { |row|		
			father = row[1]
			mother = row[2]
			if sex == 'MALE'
				unless father == parent
					Output.text 'Отец ' + Output.link_to(d.direct_address('gov',parent), parent) + ' ребенка ' +
						Output.link_to(d.direct_address('gov',child), child) + ' не прописан в ' +
						Output.link_to(d.direct_address('gov',child), 'записи ребенка')
				end
			else
				unless mother == parent
					Output.text 'Мать ' + Output.link_to(d.direct_address('gov',parent), parent) + ' ребенка ' +
						Output.link_to(d.direct_address('gov',child), child) + ' не прописана в ' +
						Output.link_to(d.direct_address('gov',child), 'записи ребенка')
				end
			end
		}
		if res == 0 then
			Output.text 'У родителя ' + Output.link_to(d.direct_address('gov',parent), parent) + ' задан несуществующий ребенок ' + child
		end
	}
}

people = {}
db.select("select D0F01,D0F05,D0F0B from D0 WHERE D0F0B IS NOT NULL") { |row|
	people[row[0]] = row[2]
}

people.each_key { |p|
	spouse = people[p]
	if spouse == p then 
		Output.text 'В записи ' + Output.link_to(d.direct_address('gov',p), p) + ' поле Супруг(а) указывает на себя'
	elsif people[spouse] != p then
		Output.text 'Супруги ' + Output.link_to(d.direct_address('gov',p), p) + ' и ' + 
			Output.link_to(d.direct_address('gov',spouse), spouse) + ' не связаны взаимными ссылками'
	end
}
# ----------------------------------------------------------------------------
Output.header 'Директория преступлений', 2

crimes = []
db.select("select D1F11,D1F16,D1F17,D1F18 from D1 WHERE D1F16 IS NOT NULL OR D1F17 IS NOT NULL OR D1F18 IS NOT NULL") { |row|
	crimes.push [row[0], row[1], row[2], row[3]]
}

crimes.each { |c|
	crime_id = c[0]
	crime_suspect = c[1]
	crime_witness = c[2]
	crime_victim = c[3]

	crime_suspect.split(',').each { |susp|
		if db.select("select D0F01 from D0 where D0F01 = #{susp}") == 0 then
			Output.text 'В подозреваемых преступления ' + Output.link_to(d.direct_address('crime', crime_id), crime_id) +
				" указан несуществующий гражданин #{susp}"
		end
	} unless crime_suspect.nil?

	crime_witness.split(',').each { |witn|
		if db.select("select D0F01 from D0 where D0F01 = #{witn}") == 0 then
			Output.text 'В свидетелях преступления ' + Output.link_to(d.direct_address('crime', crime_id), crime_id) +
				" указан несуществующий гражданин #{witn}"
		end
	} unless crime_witness.nil?

	crime_victim.split(',').each { |vict|
		if db.select("select D0F01 from D0 where D0F01 = #{vict}") == 0 then
			Output.text 'В потерпевших преступления ' + Output.link_to(d.direct_address('crime', crime_id), crime_id) +
				" указан несуществующий гражданин #{vict}"
		end
	} unless crime_victim.nil?
}	

# ----------------------------------------------------------------------------
Output.header 'Директория финансов', 2

db.select("select D2F21,D2F22 from D2 WHERE D2F22 IS NOT NULL") { |row|
	id = row[1]
	if db.select("select D0F01 from D0 where D0F01 = #{id}") == 0 then
			Output.text 'Счет ' + Output.link_to(d.direct_address('fin', row[0]), row[0]) +
				" указывает на несуществующего владельца #{id}"
	end
}

db.select("select D2F21,D2F22,D2F23 from D2 WHERE LENGTH(D2F23) > 0") { |row|
	list = row[2].split(',')

	unless list.include? row[1]
		Output.text 'Список пайщиков счета ' + Output.link_to(d.direct_address('fin',row[0]), row[0]) + ' не содержит владельца счета ' +
			Output.link_to(d.direct_address('gov',row[1]), row[1])
	end

	list.each { |id|
		if db.select("select D0F01 from D0 where D0F01 = #{id}") == 0 then
			Output.text 'Счет ' + Output.link_to(d.direct_address('fin', row[0]), row[0]) +
				" указывает на несуществующего пайщика #{id}"
		end
	}
}

ships = []
db.select("select D2F21,D2F22,D2F23,D2F26 from D2 WHERE LENGTH(D2F26) > 0") { |row|
	ships.push [row[0],row[1],row[2],row[3]]
}

ships.each { |s|
	account = s[0]
	owners = [s[1]] + (s[2].nil? ? [] : s[2].split(','))
	s[3].split(',').each { |ship|
		res = db.select("select D6F61,D6F64 from D6 WHERE D6F61 = #{ship}") { |shipinfo|
			ship_owner = shipinfo[1]
			unless owners.include? ship_owner
				Output.text 'В счете ' + Output.link_to(d.direct_address('fin', account), account) + " корабль " +
					Output.link_to(d.direct_address('fleet', ship), ship) + " не принадлежит ни владельцу счета, ни пайщикам"
			end
		}
		if res == 0 then
			Output.text 'В счете ' + Output.link_to(d.direct_address('fin', account), account) + " указан несуществующий корабль #{ship}"
		end
	}
}

# ----------------------------------------------------------------------------
Output.header 'Директория патентов', 2

patents = []
db.select("select D3F31,D3F32 from D3") { |row|
	patents.push [row[0], row[1]]
}

patents.each { |c|
	patent_id = c[0]
	patent_authors = c[1]

	patent_authors.split(',').each { |a|
		if db.select("select D0F01 from D0 where D0F01 = #{a}") == 0 then
			Output.text 'В авторах патента ' + Output.link_to(d.direct_address('pat', patent_id), patent_id) +
				" указан несуществующий гражданин #{a}"
		end
	} unless patent_authors.nil?
}

# ----------------------------------------------------------------------------
Output.header 'Директория кораблей', 2

ships = []
db.select("select D6F61,D6F65 from D6 WHERE D6F65 IS NOT NULL") { |row|
	ships.push([row[0],row[1]])
}
ships.each { |s|
	ship = s[0]
	captain = s[1]
	if db.select("select D0F01 from D0 where D0F01 = #{captain}") == 0 then
		Output.text 'Корабль ' + Output.link_to(d.direct_address('fleet', ship), ship) +
			" имеет несуществующего капитана #{captain}"
	end
}

ships = []
db.select("select D6F61,D6F64 from D6 WHERE D6F64 IS NOT NULL") { |row|
	ships.push([row[0],row[1]])
}
ships.each { |s|
	ship = s[0]
	owner = s[1]
	have_ship = false
	res = db.select("select D2F21,D2F26 from D2 WHERE D2F22 = #{owner} OR D2F23 LIKE '%#{owner}%'") { |row|
		account = row[0]
		owner_ships = row[1]
		if (not owner_ships.nil?) and owner_ships.include? ship 
			if have_ship then
				Output.text 'Корабль ' + Output.link_to(d.direct_address('fleet', ship), ship) +
				" числится в нескольких счетах"
			end
			have_ship = true
		end
	}
	unless have_ship
		Output.text 'Владелец ' + Output.link_to(d.direct_address('gov', owner), owner) +
				' корабля ' + Output.link_to(d.direct_address('fleet', ship), ship) +
				' не имеет его на балансе ни одного из своих счетов'
	end
	if res == 0 then
		Output.text 'Корабль ' + Output.link_to(d.direct_address('fleet', ship), ship) +
			" имеет владельца #{owner} без личного счета"
	end
}
# ----------------------------------------------------------------------------
Output.text "Проверка закончена."
Output.text Output.link_to('index.cgi','Вернуться к началу')
Output.finish
# ----------------------------------------------------------------------------

