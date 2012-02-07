# == Forestify
# 
# Provides a tree structure to Active Record models.
#
# New leaves are added to the right.
#
# For example, a Tag model could implement it like this :
#
#  class Tag < ActiveRecord::Base
#    forestify
#  end
#
# We'll use the following example throughout this documentation :
#   
#  @vehicle = Tag.create!(name: "Vehicle")
#  @animal = Tag.create!(name: "Animal")
#  @car = Tag.create!(name: "Car", parent_id: @vehicle.id)
#  @plane = Tag.create!(name: "plane", parent_id: @vehicle.id)
#  @boat = Tag.create!(name: "Boat", parent_id: @vehicle.id)
#  @audi = Tag.create!(name: "Audi", parent_id: @car.id)
#
# This code produces the following tree :
#    
#  { forestify_left_position, name, forestify_right_position, forestify_level }
#  { 0, Vehicle, 9, 0 } { 10, Animal, 11, 0}
#  { 1, Car, 4, 1 } { 5, Plane, 6, 1 } { 7, Boat, 8, 1 }
#  { 2, Audi, 3, 2}
#
module Forestify

  def forestify
    unless included_modules.include? InstanceMethods
      include InstanceMethods
    end

    before_create :initialize_position
    before_destroy :update_positions_after_delete

    attr_accessor :parent_id
  end

  module InstanceMethods

    # Initialize position fields
    # Should be run only once
    def initialize_position
      # @parent = -1 is the option 'No parent'
      if @parent_id.nil? || @parent_id == "-1"
        # No parent has been specified, we need to add this leaf
        # to the right side of the last root node.
        last = self.class.order("forestify_right_position DESC").first
        self.forestify_left_position = (last.nil?) ? 0 : last.forestify_right_position + 1
        self.forestify_right_position = self.forestify_left_position + 1
        self.forestify_level = 0
      else
        @parent_id = @parent_id.to_i
        p = self.class.find(@parent_id)
        self.forestify_left_position = p.forestify_right_position
        self.forestify_right_position = self.forestify_left_position + 1
        self.forestify_level = p.forestify_level + 1
        # update nodes on the right hand side of parent
        self.class.update_all "forestify_left_position = forestify_left_position + 2", ['forestify_left_position > ?', p.forestify_right_position]
        self.class.update_all "forestify_right_position = forestify_right_position + 2", ['forestify_right_position > ?', p.forestify_right_position]
        # update parent
        p.update_attribute 'forestify_right_position', p.forestify_right_position + 2
      end
    end

    def update_positions_after_delete
      if is_node?
        # Update nodes to the right
        self.class.update_all "forestify_left_position = forestify_left_position - 2", ['forestify_left_position > ?', self.forestify_right_position]
        self.class.update_all "forestify_right_position = forestify_right_position - 2", ['forestify_right_position > ?', self.forestify_right_position]
        # Update children
        self.class.update_all "forestify_level = forestify_level - 1", ['forestify_left_position > ? AND forestify_right_position < ?', self.forestify_left_position, self.forestify_right_position]
        self.class.update_all "forestify_left_position = forestify_left_position - 1, forestify_right_position = forestify_right_position - 1", ['forestify_left_position > ? AND forestify_right_position < ?', self.forestify_left_position, self.forestify_right_position]
      else
        # Update nodes to the right
        self.class.update_all "forestify_left_position = forestify_left_position - 2", ['forestify_left_position > ?', self.forestify_right_position]
        self.class.update_all "forestify_right_position = forestify_right_position - 2", ['forestify_right_position > ?', self.forestify_right_position]
      end
    end

    # Returns an ActiveRecord::Relation looking for ancestors.
    #
    # Example :
    # 
    #   @audi.parents.all # => [@vehicle, @car]
    #
    def parents
      self.class.where('forestify_left_position < ?', self.forestify_left_position).where('forestify_right_position > ?', self.forestify_right_position)
    end

    # Returns the direct parent, or +nil+ if none exists.
    #
    # Example :
    #
    #   @vehicle.parent # => nil
    #   @car.parent # => @vehicle
    #
    def parent
      self.parents.where('forestify_level = ?', self.forestify_level - 1).first
    end

    # Returns an ActiveRecord::Relation looking for descendents. 
    #
    # Example :
    #
    #   @audi.children.all # => []
    #   @vehicle.children.all # => [@car, @plane, @boat, @audi]
    #   
    def children
      [] if is_leaf?
      self.class.where('forestify_left_position > ?', self.forestify_left_position).where('forestify_right_position < ?', self.forestify_right_position)
    end

    # Returns an ActiveRecord::Relation looking for siblings.
    #
    # Example :
    #   
    #   @vehicle.siblings.all => # [@animal]
    #
    def siblings
      if self.parent.nil?
        self.class.where('forestify_level = 0').where('id != ?', self.id)
      else
        self.parent.children.where('forestify_level = ?', self.forestify_level).where('id != ?', self.id)
      end
    end

    # Returns whether the instance is a node or not.
    #
    # Example :
    #
    #   @car.is_node? # => true
    #   @animal.is_node? # => false
    #
    def is_node?
      (self.forestify_right_position - self.forestify_left_position) > 1
    end
    
    # Returns whether the instance is a leaf or not.
    #
    # Example :
    #
    #   @car.is_leaf? # => false
    #   @animal.is_leaf? # => true
    #
    def is_leaf?
      !is_node?
    end
  end
end

ActiveRecord::Base.send :extend, Forestify
