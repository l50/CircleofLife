#! /usr/bin/env ruby
require 'koala'
require 'mysql'

# Use to connect to MySQL DB
def connect_to_db
  puts "Please enter IP storing Mysql DB: "
  db_ip = gets.chomp
  puts "Please input db username: "
  db_user = gets.chomp
  puts "Please input db password: "
  db_pass = gets.chomp
  puts "Please input db name: "
  database = gets.chomp
  begin
    @db = Mysql.new(db_ip, db_user, db_pass, database)
  rescue Mysql::Error
    puts "Can\'t connect to the database"
  end
end

# Debug method to make sure we were getting info properly
def get_birthday(friend)
  if !friend["birthday"].eql?(nil)
    puts "#{f['name']} has a birthday on #{friend["birthday"]}"
  end
end

def populate_database(fb_token, table)
  graph = Koala::Facebook::API.new(fb_token)
  friends = graph.get_connections("me", "friends")
  puts 'Gathering results and putting them into a database table, be patient...'
  friends.each do |f|
    friend = graph.get_object(f['id'])
    # puts friend.inspect
    # puts friend["name"]
    fn = friend["first_name"]
    ln = friend["last_name"]
    b = friend["birthday"]
    if friend["location"].class.to_s.eql?('Hash')
      lo = friend["location"]["name"]
    end
    begin
      # puts "First: #{fn}"
      # puts "Last: #{ln}"
      # puts "Birthday: #{b}"
      # puts "#{lo}"
      results = @db.query("INSERT INTO #{table}(first,last,age,location) VALUES ('#{fn}','#{ln}','#{b}','#{lo}')")
    rescue Exception => e
      puts "Couldn't put #{fn} #{ln} into the DB, omitting."
    end
  end
end