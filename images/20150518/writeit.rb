#!/usr/bin/ruby

# Author: Eric HAMON
# File: writeIt.rb
# Version: 20081017 first public release
# Licence: same as ruby licence (http://www.ruby-lang.org/en/LICENSE.txt)

require 'rubygems'
require 'sqlite3'

base='Datashield.db3'
db = SQLite3::Database.new( base )

fichier_entete="splashId-ego.vid"
fichier_liste = "splashId-listetypes.txt"
fichier_enregs="splashId-ego.csv"


db.create_aggregate("champs_concat", 1) do
   step do |func, value|
   if String(func[:concat]).empty? then
     func[:concat] = String(value)
   else
  func[:concat] = String(func[:concat]) + '","' + String(value)
  end
  end
  
  finalize do |func|
    func.result = func[:concat]
  end
end

def liste_type( db, fichier_types )
  sql = <<-SQL
  BEGIN TRANSACTION;
  CREATE TEMPORARY TABLE tmp_modeles (id INTEGER PRIMARY KEY, champs TEXT);
  INSERT INTO tmp_modeles SELECT id_modele, champs_concat(libelle) FROM ChampDuModele GROUP BY id_modele;
  COMMIT;
  SQL
  db.execute_batch( sql )
  
  sql = <<-SQL
  select modele.name, tmp_modeles.champs
  FROM tmp_modeles, modele, (select id_modele FROM fiche GROUP BY id_modele) AS fiche_utilise
  WHERE tmp_modeles.id=modele.id and fiche_utilise.id_modele=modele.id ORDER BY modele.name;
  SQL
  file = File.new( fichier_types , "w" )
  
  db.execute( sql ) do |row|
    #p row
    ligne = ""
    ligne += "\"#{row[0]}\",\"#{row[1]}\""
    nbchamps=(row[1].split("\",\"")).size
    #nbchamps += 1
    #(nbchamps..9).each do |i|
    #  ligne += ",\"Field #{i}\""
    #end
    #ligne += ",\"Date Mod\""
    #ligne += ",\"0\"\n"
    ligne += "\n"
    
    print ligne
    file.print( ligne )
  end
  db.execute( "DROP TABLE tmp_modeles")
  file.close  
end


def entete( db, fichier_entete )
  sql = <<-SQL
  BEGIN TRANSACTION;
  CREATE TEMPORARY TABLE tmp_modeles (id INTEGER PRIMARY KEY, champs TEXT);
  INSERT INTO tmp_modeles SELECT id_modele, champs_concat(libelle) FROM ChampDuModele GROUP BY id_modele;
  COMMIT;
  SQL
  db.execute_batch( sql )
  
  sql = <<-SQL
  select modele.name, tmp_modeles.champs
  FROM tmp_modeles, modele
  WHERE tmp_modeles.id=modele.id ;
  SQL

  file = File.new( fichier_entete , "w" )
  print file, "#SplashID vID File -v3.0\n"
  print file, "#F\n"
  
  db.execute( sql ) do |row|
    #p row
    ligne = "T,24,"
    ligne += "\"#{row[0]}\",\"#{row[1]}\""
    nbchamps=(row[1].split("\",\"")).size
    nbchamps += 1
    (nbchamps..9).each do |i|
      ligne += ",\"Field #{i}\""
    end
    ligne += ",\"Date Mod\""
    ligne += ",\"0\"\n"
    print ligne
    file.print( ligne )
  end
  db.execute( "DROP TABLE tmp_modeles")
  file.close
end

def corps( db, fichier_enregs )
  sql = <<-SQL
  BEGIN TRANSACTION;  
  CREATE TEMPORARY TABLE tmp_champs (id INTEGER PRIMARY KEY, champs TEXT);
  INSERT INTO tmp_champs select id_fiche, champs_concat(valeur) from ChampDeFiche group by id_fiche;
  COMMIT;
  SQL
  db.execute_batch( sql )

  file = File.new( fichier_enregs , "w" )
  
  sql = <<-SQL
  select modele.name, tmp_champs.champs, fiche.id_note, categorie.libelle
  FROM tmp_champs, fiche, categorie, modele
  WHERE tmp_champs.id=fiche.id AND fiche.id_categorie=categorie.id AND modele.id=fiche.id_modele ORDER BY modele.name;
  SQL
  db.execute( sql ) do |row|
    ligne =""
    #p row
    ligne += "\"#{row[0]}\",\"#{row[1]}\""
    nbchamps=(row[1].split("\",\"")).size
    (nbchamps..9).each do |i|
      ligne += ",\"\""
    end
    # traitement du champ 'note'.
    row[2].gsub!("\n","\v")
    ligne += ",\"#{row[2]}\""
    ligne += ",\"#{row[3]}\"\n"
    file.print( ligne )
    print ligne
  end
  db.execute( "DROP TABLE tmp_champs" )
  file.close
end

liste_type(db, fichier_liste)
#entete(db, fichier_entete)
corps(db, fichier_enregs)

db.close
