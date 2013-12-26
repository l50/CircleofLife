#! /usr/bin/env ruby

class Friend

  attr_accessor :first, :last, :age, :location

  def initialize(first, last, age, location)
    @first = first
    @last = last
    @age = age
    @location = location
  end
end