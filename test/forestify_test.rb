# encoding: utf-8

require 'test_helper'

class ForestifyTest < Test::Unit::TestCase
	load_schema

	class Tag < ActiveRecord::Base
		forestify
	end

	def setup
   
	end

	def test_should_initialize_position_without_parent
    tag = Tag.new(name: "Car")
		tag.save!
		assert_equal 0, tag.left_position
		assert_equal 1, tag.right_position
		assert_equal 0, tag.level
	end

end
