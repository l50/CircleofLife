#! /usr/bin/env ruby

class Site

  attr_accessor :url, :f_field, :l_field, :checkbox, :submit_button

  def initialize(url, f_field, l_field, checkbox, submit_button)
    @url = url
    @f_field = f_field
    @l_field = l_field
    @checkbox = checkbox
    @submit_button = submit_button
  end
end
