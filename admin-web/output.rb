# ----------------------------------------------------------------------------
require 'web'
# ----------------------------------------------------------------------------
class Output
	def Output.error
		print "Content-type: text/plain\n\n"
	end

	def Output.start
		print "Content-type: text/html\n\n"
		print "<html>
<head>
<style>
	body { font-family: georgia}
	table, th, td { border: 1px solid black; }
</style>
<title>Машина различий</title>
</head>"
		print "<body>\n"
	end

	def Output.finish
		print "</body></html>\n"
	end

	def Output.header(t,level = 1)
		print "<h#{level}>#{t}</h#{level}>\n"
	end

	def Output.text(t)
		print "<p>#{t}</p>\n"
	end

	def Output.table_header(*fields)
		print '<table><tr>'
		fields.each { |f|
			print "<th>#{f}</th>"
		}
		print "</tr>\n"
	end

	def Output.table_row(*fields)
		print '<tr>'
		fields.each { |f|
			print "<td>#{f}</td>"
		}
		print "</tr>\n"
	end

	def Output.table_footer
		print "</table>\n"
	end

	def Output.link_to(link, text)
		"<a href=\"#{link}\">#{text}</a>"
	end

	def Output.form_header(address)
		print "<form action='#{address}' method='get'>\n"
	end

	def Output.form_footer
		print "</form>\n"
	end

	def Output.input_value(name, value)
		puts "<input type='hidden' name='#{name}' value='#{value}'/>"
	end

	def Output.input_text(name, descr, value = '')
		print "<p>#{descr}: <input type='text' name='#{name}' value='#{value}'/></p>\n"
	end

	def Output.input_important_text(name, descr, value = '')
		print "<p><font color='red'>#{descr}</font>: <input type='text' name='#{name}' value='#{value}'/></p>\n"
	end

	def Output.input_select(name, descr, values, selected = nil, allow_null = true)
		print "<p>#{descr}: <select name='#{name}'>\n"
		print "<option value='NULL' #{'selected' if selected.nil?}>НЕТ</option>\n" if allow_null
		values.each {|v|
			if v.kind_of? Array then
				print "<option value='#{v[0]}' #{'selected' if selected == v[0]}>#{v[1]}</option>\n"
			else
				print "<option value='#{v}' #{'selected' if selected == v}>#{v}</option>\n"
			end
		}	
		print "</select></p>\n"
	end

	def Output.input_select_multiple(name, descr, values, selected = '')
		print "<p>#{descr} (для выбора жмите CTRL): <select multiple size='4' name=#{name}>\n"
		sel = selected.nil? ? [] : selected.split(',')
		values.each {|v|
			print "<option value='#{v[0]}' #{'selected' if sel.include? v[0]}>#{v[1]}</option>\n"
		}	
		print "</select></p>\n"
	end

	def Output.input_large_text(name, descr, value = '')
		print "<p>#{descr}:<br/><textarea name='#{name}' cols='80' rows='10'>#{value}</textarea></p>\n"
	end

	def Output.input_check(name, descr, value = false)
		print "<p>#{descr} <input type='checkbox' name='#{name}' value='true' #{value ? 'checked' : ''}/></p>\n"
	end

	def Output.submit(text)
		print "<p><input type='submit' value='#{text}'/></p>"
	end
end
# ----------------------------------------------------------------------------

