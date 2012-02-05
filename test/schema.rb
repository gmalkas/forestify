ActiveRecord::Schema.define(:version => 0) do
create_table :tags, :force => true do |t|
	t.string :name
	t.integer :left_position
	t.integer :right_position
	t.integer :level
	t.index :left_position, :unique => true
	t.index :right_position, :unique => true
end
end
