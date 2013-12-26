#! /usr/bin/env ruby
require 'mysql'
require './lib/facebook.rb'

# Debug file with method to delete info from your MySQL table programmatically

# Debug method to hose a table and reset the auto_incremented ID
def delete_entire_table(table)
  # delete everything
  @db.query("DELETE FROM #{table}")
  # Reset the auto incrementer
  @db.query("ALTER TABLE #{table} AUTO_INCREMENT = 1")
end

connect_to_db
puts "Input the name of the database table: "
table = gets.chomp
delete_entire_table(table)
