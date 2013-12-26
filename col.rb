#! /usr/bin/env ruby
require 'trollop'
require 'mysql'
require './lib/friend.rb'
require './lib/facebook.rb'
require './lib/site.rb'
require 'watir'

def get_age_number(f_age)
  # puts "Age: #{f_age}"
  if (/\d{2}\/\d{2}\/(\d{4})/).match(f_age)
    year = $1.to_i
  end
  time = Time.new
  age_number = time.year - year
  return age_number
end

def fill_out_form(l, f, last, first, checkbox, button)
  @agent.text_field(:name, "#{l}").set(last)
  @agent.text_field(:name, "#{f}").set(first)
  # check checkbox exists
  if @agent.checkbox.exists?
    @agent.checkbox(:name => checkbox).set
  end
  if @agent.button(:name => button).exists?
    @agent.button(:name => button).click
  end
end

# Helper method to get answer from user
def get_answer(answer)
  until (/no/i).match(answer) || (/yes/i).match(answer) || (answer.eql? "n") || (answer.eql? "y")
    puts 'Please enter yes or no.'
    answer = gets.chomp
  end
  if (/no/i).match(answer) || (answer.eql? "n")
    return "no"
  elsif (/yes/i).match(answer) || (answer.eql? "y")
    return "yes"
  end
end

def get_form_last_and_first(current_site, body)
  # last name text field
  if (body.input(:name => current_site.l_field))
    # if (body.input(:name => /LName/im)).exists?
    # l = body.input(:name => /LName/im)
    l = body.input(:name => current_site.l_field)
    l = l.name.to_s
  end
  # first name text field
  if (body.input(:name => current_site.f_field)).exists?
    # if (body.input(:name => /FName/im)).exists?
    # f = body.input(:name => /FName/im)
    f = body.input(:name => current_site.f_field)
    f = f.name.to_s
  end
  return f, l
end

def get_links(pages)
  @agent.links.each do |link|
    if (/^\.\.\.$/).match(link.text)
      @extend_pagination = true
    else
      if (/^\d$/).match(link.text) || (/^\d{2}$/).match(link.text)
        pages << link.href
      end
    end
  end
  return pages
end

def input_site_data
  puts "Input site url that has the input form on it: "
  url = gets.chomp
  puts "Input form first name input field name: "
  first = gets.chomp
  puts "Input form last name input field name: "
  last = gets.chomp
  puts "Is there a checkbox that needs to be clicked?"
  puts "Yes/No"
  answer = gets.chomp
  if get_answer(answer).eql? "yes"
    puts "Input the checkbox name: "
    checkbox = gets.chomp
  else
    checkbox = nil
  end
  puts "Input form submit button name: "
  submit = gets.chomp
  site = Site.new(url,first,last,checkbox,submit)
  puts "Onward!"
  return site
end

def full_birthday_person_check(f_age,f_first,f_last)
  age_number = get_age_number(f_age).to_i
  puts "Complete birthday #{f_age} for #{f_first} #{f_last}"
  puts "Age number: #{age_number}"
  if @agent.text.include?(f_age) || @agent.body(:text, /^age_number$/).exists?
    pst = @db.prepare "UPDATE friends SET altercation = ? WHERE last = ? AND age = ?"
    pst.execute "1", "#{f_last}", "#{f_age}"
    puts "We have a winner: #{f_first} #{f_last}"
    return true
  else
    return false
  end
end

def partial_birthday_person_check(age,f_age,f_first,f_last)
  age_number = get_age_number(age).to_s
  puts "Incomplete birthday #{age} for #{f_first} #{f_last}"
  if @agent.text.include?(age) || @agent.body(:text, /^age_number$/).exists?
    pst = @db.prepare "UPDATE friends SET altercation = ? WHERE last = ? AND age = ?"
    pst.execute "1", "#{f_last}", "#{f_age}"
    puts "After some work, we have a winner: #{f_first} #{f_last}"
    return true
  else
    return false
  end
end

opts = Trollop::options do
  version "test 0.0.1 (c) 2013 Jayson Grace."
  banner <<-EOS
  The Circle of Trust program can be used to determine if someone has a higher risk of commiting a crime based on relationships with people in their Facebook friends list.

    Options:

    EOS
  opt :help, "Displays help message"
  opt :token, "Facebook API token to use", :type => String
  opt :age, "The year you were born", :type => String
end
# p opts
if !opts[:age]
  abort ("You need to include your name as an argument. Please run the program with -a <the year you were born>.")
end
if !opts[:token]
  puts "You have not input a Facebook API token, therefore we will assume that your database has Facebook information in it."
  puts "Is this alright?"
  puts "Yes/No"
  answer = gets.chomp
  if get_answer(answer).eql? "no"
    abort "Get a valid Facebook API token and use it as an argument to this program."
  end
end

connect_to_db
puts "Input the name of the database table: "
table = gets.chomp

# Populate database using Facebook friends information
if opts[:token]
  populate_database(opts[:token], table)
end

ages = Array.new
# Change these years to suit your age group, which will help get more accurate results with incomplete birthdays
starting_age = opts[:age].to_i
ages << starting_age
for i in 0..8
  starting_age = starting_age - 1
  ages << starting_age
end
starting_age = opts[:age].to_i
for i in 0..4
  starting_age = starting_age + 1
  ages << starting_age
end
# ages = ["1980","1981","1982","1983","1984","1985","1986","1987","1988","1989","1990","1991","1992","1993"]

puts "How many sites are we crawling today? Give me a number: "
number = gets.chomp.to_i

prison_query_pages = Array.new

for i in 1..number
  # target_site = input_site_data
  puts "Input site url that has the input form on it: "
  url = gets.chomp
  puts "Input form first name input field name: "
  first = gets.chomp
  puts "Input form last name input field name: "
  last = gets.chomp
  puts "Is there a checkbox that needs to be clicked?"
  puts "Yes/No"
  answer = gets.chomp
  if get_answer(answer).eql? "yes"
    puts "Input the checkbox name: "
    checkbox = gets.chomp
  else
    checkbox = nil
  end
  puts "Input form submit button name: "
  submit = gets.chomp
  site = Site.new(url,first,last,checkbox,submit)
  puts "Onward!"
  prison_query_pages << site
end

@agent = Watir::Browser.new

#debug stuff
# prison_query_pages.each do |prison|
#   puts prison.inspect
#   puts prison.url
# end
# prison_query_pages = {"Santa Fe" => "http://216.161.39.6", "Albuquerque" => "http://app.bernco.gov/custodylist/CustodySearchInter.aspx"}

# Get friend info out of database
current = @db.query("SELECT first,last,age,location FROM #{table}")
# n_rows = current.num_rows

# Iterate through each friend, and check them against the database
current.each_hash do |friend|
  fn = friend['first']
  ln = friend['last']
  age = friend['age']
  location = friend['location']
  current_friend = Friend.new(fn,ln,age,location)
  if !current_friend.age.empty?
    prison_query_pages.each do |prison|
      @agent.goto(prison.url)
      body = @agent.body
      
      # I did try to do these fields with a simple regex, but I can't guarantee that they will work for any site
      # This is why I ask you to put them in manually. Let me know if you want me to add something different,
      # like parsing a text file as an argument, or throwing the info into a database.

      f, l = get_form_last_and_first(prison, body)

      fill_out_form(l, f, current_friend.last, current_friend.first[0..1], prison.checkbox, prison.submit_button)

      @extend_pagination = false
      pages = Array.new
      pages = get_links(pages)

      # if we have the birthday
      if (/\d{2}\/\d{2}\/\d{4}/).match(current_friend.age)
        if (!full_birthday_person_check(current_friend.age, current_friend.first, current_friend.last)) && (!pages.empty?)
          pages.each do |link|
            @agent.goto(link)
            break if full_birthday_person_check(current_friend.age, current_friend.first, current_friend.last)
          end
          # add a letter to the first name to improve accuracy if we have too many results from our initial query -- f#*k javascript
          if @extend_pagination
            fill_out_form(l, f, current_friend.last, current_friend.first[0..2], prison.checkbox, prison.submit_button)
            pages = get_links(pages)
            if (!full_birthday_person_check(current_friend.age, current_friend.first, current_friend.last)) && (!pages.empty?)
              pages.each do |link|
                @agent.goto(link)
                break if full_birthday_person_check(current_friend.age, current_friend.first, current_friend.last)
              end
            end
          end
        end
        # use a range of years for birthdays with no year associated with them
      elsif (/\d{2}\/\d{2}/).match(current_friend.age)
        temp = current_friend.age
        ages.each do |year|
          full_birthday = "#{temp}/#{year}"
          break if partial_birthday_person_check(full_birthday,current_friend.age, current_friend.first, current_friend.last)
        end
        pages.each do |link|
          @agent.goto(link)
          ages.each do |year|
            full_birthday = "#{temp}/#{year}"
            break if partial_birthday_person_check(full_birthday,current_friend.age, current_friend.first, current_friend.last)
          end
        end
        if @extend_pagination
          fill_out_form(l, f, current_friend.last, current_friend.first[0..2], prison.checkbox, prison.submit_button)
          pages = get_links(pages)
          ages.each do |year|
            full_birthday = "#{temp}/#{year}"
            break if partial_birthday_person_check(full_birthday,current_friend.age, current_friend.first, current_friend.last)
          end
          pages.each do |link|
            @agent.goto(link)
            ages.each do |year|
              full_birthday = "#{temp}/#{year}"
              break if partial_birthday_person_check(full_birthday,current_friend.age, current_friend.first, current_friend.last)
            end
          end
        end
        # We don't have the birthday
      else
        puts "No age found for #{current_friend.first} #{current_friend.last}"
      end
    end
  end
end
@agent.close
