module Forestify
  def forestify
		unless included_modules.include? InstanceMethods
			include InstanceMethods
		end
		before_create :initialize_position
		attr_accessor :parent
	end

	module InstanceMethods

		# Initialize position fields
		# Should be run only once
		def initialize_position
			# @parent = -1 is the option 'No parent'
			if @parent.nil? || @parent == "-1"
				# No parent has been specified, we need to add this leaf
				# to the right side of the last root node.
				last = self.class.order("right_position DESC").first
				self.left_position = (last.nil?) ? 0 : last.right_position + 1
				self.right_position = self.left_position + 1
				self.level = 0
			else
				# Makes sure it's an integer
				@parent = @parent.to_i
				p = self.class.find(@parent)
				self.left_position = p.right_position
				self.right_position = self.left_position + 1
				self.level = p.level + 1
				# update nodes on the right hand side of parent
				self.class.update_all "left_position = left_position + 2", ['left_position > ?', p.right_position]
				self.class.update_all "right_position = right_position + 2", ['right_position > ?', p.right_position]
				# update parent
				p.update_attribute 'right_position', p.right_position + 2
			end
		end

		def children
      [] if is_leaf?
			self.class.where('left_position > ?', self.left_position).where('right_position < ?', self.right_position)
		end

    def is_node?
			(self.right_position - self.left_position) > 1
		end
		
		def is_leaf?
			!is_node?
		end
	end
end

ActiveRecord::Base.send :extend, Forestify
