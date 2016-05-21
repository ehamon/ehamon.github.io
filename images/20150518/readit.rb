#!/usr/bin/ruby

# Author: Eric HAMON
# File: readIt.rb
# Version: 20081017 first public release
# Licence: same as ruby licence (http://www.ruby-lang.org/en/LICENSE.txt)

require 'rubygems'
require 'xmlsimple'
require 'uri'

require 'sqlite3'
# sudo apt-get install sqlite3 libsqlite3-dev

class String
	def quote
		self.gsub( /'/, "''" )
	end
	def quote!
		self.gsub!( /'/, "''" )
	end
end

base='Datashield.db3'
if File.exist?( base) then
		File.delete( base )
end
db = SQLite3::Database.new( base )
sql = <<SQL
BEGIN TRANSACTION;
CREATE TABLE Categorie (id INTEGER PRIMARY KEY, libelle TEXT);
CREATE TABLE Modele (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE ChampDuModele (id INTEGER, id_modele INTEGER, libelle TEXT);
CREATE TABLE Fiche (id INTEGER PRIMARY KEY, id_categorie INTEGER, id_modele INTEGER, id_created TEXT, id_note TEXT);
CREATE TABLE ChampDeFiche (id INTEGER, id_fiche INTEGER, valeur TEXT);
COMMIT;
SQL

db.execute_batch( sql )

tree_config = XmlSimple.xml_in('Datashield.xml')

db.execute_batch( "BEGIN TRANSACTION;")

tree_config['CATEGORIES'][0]['category'].each do |rec|
	id = rec['id']
	libelle = URI.unescape( rec['content'].gsub("\n","").strip )
	# Instruction SQL
	sql="INSERT INTO Categorie VALUES ( #{id} , '#{libelle.quote}' );"
	puts sql
  db.execute_batch( sql )
end
db.execute_batch( "COMMIT;" )

db.execute_batch( "BEGIN TRANSACTION;")
tree_config['TEMPLATES'][0]['template'].each do |rec|
	id = rec['id']
	name = URI.unescape( rec['name'] )
	# Instruction SQL
	sql="INSERT INTO Modele VALUES ( #{id} , '#{name.quote}' );"
	puts sql
  db.execute_batch( sql )
	rec['fields'][0]['field'].each do |champ|
		c_id = champ['id']
		c_content = URI.unescape( champ['content'].gsub("\n","").strip )
	  # Instruction SQL
	  sql="INSERT INTO ChampDuModele VALUES ( #{c_id} , #{id}, '#{c_content.quote}' );"
	  puts sql
    db.execute_batch( sql )
	end
end
db.execute_batch( "COMMIT;" )

db.execute_batch( "BEGIN TRANSACTION;")

tree_config['RECORDS'][0]['record'].each do |rec|
	id_fiche = rec['id']
	id_modele = rec['template']
	id_created = URI.unescape( rec['created'] ).strip
	id_categorie = rec['category']
	if rec.has_key?( 'note')
		id_note = (rec['note'][0]).gsub('\n','').strip
		id_note = URI.unescape( id_note )
	else
		id_note = ''
	end
  # Instruction SQL
	sql="INSERT INTO Fiche VALUES ( #{id_fiche} , #{id_categorie}, #{id_modele}, '#{id_created.quote}', '#{id_note.quote}' );"
	puts sql
  db.execute_batch( sql )
	rec['values'][0]['value'].each do |champ|
		c_id = champ['id']
		c_content = URI.unescape( champ['content'].gsub("\n","").strip )
	  # Instruction SQL
	  sql="INSERT INTO ChampDeFiche VALUES ( #{c_id} , #{id_fiche}, '#{c_content.quote}' );"
	  puts sql
    db.execute_batch( sql )
	end
end
db.execute_batch( "COMMIT;" )

db.close
