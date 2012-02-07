ActiveRecord::Schema.define(:version => 0) do
  create_table :tags, :force => true do |t|
    t.string :name
    t.integer :forestify_left_position
    t.integer :forestify_right_position
    t.integer :forestify_level
  end
end
