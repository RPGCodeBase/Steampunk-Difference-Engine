#!/usr/bin/ruby
# ----------------------------------------------------------------------------
require 'cgi'
require 'directory'
# ----------------------------------------------------------------------------
d = Directory.new
Output.start
Output.header 'Машина различий - директории'
Output.text Output.link_to(d.list_address('gov'), 'Директория граждан')
Output.text Output.link_to(d.list_address('crime'), 'Директория преступлений')
Output.text Output.link_to(d.list_address('pat'), 'Директория патентов')
Output.text Output.link_to(d.list_address('fin'), 'Директория финансов')
Output.text Output.link_to(d.list_address('oracle'), 'Директория предсказаний')
Output.text Output.link_to(d.list_address('fore'), 'Директория внешних связей')
Output.text Output.link_to(d.list_address('fleet'), 'Директория флота')
Output.text Output.link_to(d.list_address('army'), 'Директория армий')
Output.header 'Машина различий - функции'
Output.text Output.link_to('checkdb.cgi', 'Проверка целостности базы данных')
Output.finish
# ----------------------------------------------------------------------------

