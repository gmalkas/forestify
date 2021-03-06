# encoding: utf-8

require 'test_helper'

class ForestifyTest < Test::Unit::TestCase
  load_schema

  class Tag < ActiveRecord::Base
    forestify
  end

  def setup
    Tag.delete_all 

    # We create some items to play with
    # This produces the following tree
    # { forestify_left_position, name, forestify_right_position, forestify_level }
    # { 0, Vehicle, 9, 0 } { 10, Animal, 11, 0}
    # { 1, Car, 4, 1 } { 5, Plane, 6, 1 } { 7, Boat, 8, 1 }
    # { 2, Audi, 3, 2}

    @vehicle = Tag.create!(name: "Vehicle")
    @animal = Tag.create!(name: "Animal")
    @car = Tag.create!(name: "Car", parent_id: @vehicle.id)
    @plane = Tag.create!(name: "plane", parent_id: @vehicle.id)
    @boat = Tag.create!(name: "Boat", parent_id: @vehicle.id)
    @audi = Tag.create!(name: "Audi", parent_id: @car.id)

    [@vehicle, @animal, @car, @plane, @boat, @audi].each { |n| n.reload }
  end

  def test_should_initialize_position_without_parent
    assert_equal 10, @animal.forestify_left_position
    assert_equal 11, @animal.forestify_right_position
    assert_equal 0, @animal.forestify_level
  end

  def test_should_initialize_position_with_existing_root
    assert_equal 10, @animal.forestify_left_position
    assert_equal 11, @animal.forestify_right_position
  end

  def test_should_initialize_position_with_parent
    assert_equal 4, @car.forestify_right_position, "Right position should have been updated"
    assert_equal 2, @audi.forestify_left_position
    assert_equal 3, @audi.forestify_right_position
    assert_equal 2, @audi.forestify_level
  end

  def test_should_be_leaf
    assert @audi.leaf?
  end

  def test_should_not_be_leaf
    assert (not @vehicle.leaf?)
  end

  def test_should_be_node
    assert @vehicle.node?
  end

  def test_should_not_be_node
    assert (not @animal.node?)
  end

  def test_should_have_children_when_node
    assert_equal 4, @vehicle.children.size
  end

  def test_should_not_have_children_when_leaf
    assert_equal 0, @animal.children.size
  end
  
  def test_should_have_parents
    assert_equal Set.new([@vehicle, @car]), Set.new(@audi.parents)
  end

  def test_should_update_nodes_when_parent_is_deleted
    @car.destroy
    
    @vehicle.reload
    @audi.reload

    assert_equal 7, @vehicle.forestify_right_position, "Vehicle's right position should have been updated"
    assert_equal 2, @audi.forestify_right_position, "Audi's right position should have been updated"
    assert_equal 1, @audi.forestify_level, "Audi's level should have been updated"
  end

  def test_should_updates_leafs_when_node_is_deleted
    @car.destroy

    @vehicle.reload
    @animal.reload
    
    assert_equal 7, @vehicle.forestify_right_position, "Vehicle's right position should have been updated"
    assert_equal 8, @animal.forestify_left_position, "Animal's left position should have been updated"
  end

  def test_should_have_a_parent
    assert_equal @vehicle.id, @car.parent.id
  end

  def test_should_not_have_a_parent
    assert_nil @vehicle.parent
  end

  def test_should_have_siblings
    assert_equal 2, @car.siblings.size
  end

  def test_should_not_have_any_siblings
    assert_equal 0, @audi.siblings.size
  end

  def test_should_have_siblings_when_root
    assert_equal 1, @vehicle.siblings.size
  end

end
