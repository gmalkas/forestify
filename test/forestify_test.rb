# encoding: utf-8

require 'test_helper'

class ForestifyTest < Test::Unit::TestCase
	load_schema

	class Tag < ActiveRecord::Base
		forestify
	end

	def setup
    Tag.delete_all 
	end

	def test_should_initialize_position_without_parent
    tag = Tag.new(name: "Car")
		tag.save!
		assert_equal 0, tag.left_position
		assert_equal 1, tag.right_position
		assert_equal 0, tag.level
	end

	def test_should_initialize_position_with_parent
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent: vehicle.id)
		car.save!

		assert_equal 1, car.left_position
		assert_equal 2, car.right_position
		assert_equal 1, car.level
	end

	def test_should_be_leaf
    car = Tag.new(name: "Car")
		car.save!

		assert car.is_leaf?
	end

end
