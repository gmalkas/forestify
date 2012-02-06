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

	def test_should_initialize_position_with_existing_root
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!

		animal = Tag.new(name: "Animal")
		animal.save!

		assert_equal 2, animal.left_position
		assert_equal 3, animal.right_position
	end

	def test_should_initialize_position_with_parent
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!

		# We have to reload the data
		vehicle.reload
		
    assert_equal 3, vehicle.right_position, "Right position should have been updated"
		assert_equal 1, car.left_position
		assert_equal 2, car.right_position
		assert_equal 1, car.level
	end

	def test_should_be_leaf
    car = Tag.new(name: "Car")
		car.save!

		assert car.is_leaf?
	end

	def test_should_not_be_leaf
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!

		vehicle.reload

    assert (not vehicle.is_leaf?)
	end

	def test_should_be_node
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!

    vehicle.reload

		assert vehicle.is_node?
	end

	def test_should_not_be_node
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!

		assert (not vehicle.is_node?)
	end

	def test_should_have_children_when_node
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!
		plane = Tag.new(name: "plane", parent_id: vehicle.id)
		plane.save!
		boat = Tag.new(name: "Boat", parent_id: vehicle.id)
		boat.save!

		vehicle.reload

		assert_equal 3, vehicle.children.size
	end

	def test_should_not_have_children_when_leaf
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!

		assert_equal 0, vehicle.children.size
	end
	
	def test_should_have_parents
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!
		porsche = Tag.new(name: "Porsche", parent_id: car.id)
		porsche.save!

		vehicle.reload
		car.reload

		assert_equal Set.new([vehicle, car]), Set.new(porsche.parents)
	end

	def test_should_update_nodes_when_parent_is_deleted
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!
		porsche = Tag.new(name: "Porsche", parent_id: car.id)
		porsche.save!
    
		car.reload
    car.destroy
    
		vehicle.reload
		porsche.reload

		assert_equal 3, vehicle.right_position, "Vehicle's right position should have been updated"
		assert_equal 2, porsche.right_position, "Porsche's right position should have been updated"
	end

	def test_should_updates_leafs_when_node_is_deleted
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!
		animal = Tag.new(name: "Animal")
		animal.save!
    
    car.reload
		car.destroy

		vehicle.reload
		animal.reload
    
		assert_equal 1, vehicle.right_position, "Vehicle's right position should have been updated"
		assert_equal 2, animal.left_position, "Animal's left position should have been updated"
	end

	def test_should_have_a_parent
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!
		car = Tag.new(name: "Car", parent_id: vehicle.id)
		car.save!

	  vehicle.reload

		assert_equal vehicle.id, car.parent.id
	end

	def test_should_not_have_a_parent
    vehicle = Tag.new(name: "Vehicle")
		vehicle.save!

		assert_equal nil, vehicle.parent
	end

	# def test_should_have_siblings
    # vehicle = Tag.new(name: "Vehicle")
	# 	vehicle.save!
	# 	car = Tag.new(name: "Car", parent: vehicle.id)
	# 	car.save!
    # plane = Tag.new(name: "Plane", parent: vehicle.id)
	# 	plane.save!
	# 	rocket = Tag.new(name: "Rocket", parent: vehicle.id)
	# 	rocket.save!

	# 	vehicle.reload
	# 	car.reload
	# 	plane.reload
	# 	rocket.reload

	# 	assert_equal 2, car.siblings.size
	# end

end
