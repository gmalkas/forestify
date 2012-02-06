require 'rubygems'
require 'active_record'
require 'test/unit'
require 'forestify'

def load_schema
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:", :encoding => "utf8")
  load(File.join(File.dirname(__FILE__), "schema.rb"))
end
