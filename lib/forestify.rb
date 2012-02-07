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
        # Makes sure it's an integer
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
        self.class.update_all "forestify_left_position = forestify_left_position - 2", ['forestify_left_position > ?', self.forestify_right_position]
        self.class.update_all "forestify_right_position = forestify_right_position - 2", ['forestify_right_position > ?', self.forestify_right_position]
      end
    end

    def parents
      self.class.where('forestify_left_position < ?', self.forestify_left_position).where('forestify_right_position > ?', self.forestify_right_position)
    end

    def parent
      self.parents.where('forestify_level = ?', self.forestify_level - 1).first
    end

    def children
      [] if is_leaf?
      self.class.where('forestify_left_position > ?', self.forestify_left_position).where('forestify_right_position < ?', self.forestify_right_position)
    end

    def siblings
      if self.parent.nil?
        self.class.where('forestify_level = 0').where('id != ?', self.id)
      else
        self.parent.children.where('forestify_level = ?', self.forestify_level).where('id != ?', self.id)
      end
    end

    def is_node?
      (self.forestify_right_position - self.forestify_left_position) > 1
    end
    
    def is_leaf?
      !is_node?
    end
  end
end

ActiveRecord::Base.send :extend, Forestify
