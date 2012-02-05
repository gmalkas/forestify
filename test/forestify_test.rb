# encoding: utf-8

require 'test_helper'

class ForestifyTest < Test::Unit::TestCase
	load_schema

	class Tag < ActiveRecord::Base
	end

	def test_should_pass
		assert true
	end
end
