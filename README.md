# forestify

forestify creates forests out of your Active Record models : it implements a simple data-structure which hierarchizes your data.

For example, given the following model :

```ruby
class Tag < ActiveRecord::Base
  attr_accessible :name
  forestify
end
```

You can then do something like this :

```ruby
vehicle = Tag.new(name: "Vehicle")
vehicle.save!
car = Tag.new(name: "Car", parent: vehicle.id)
car.save!
audi = Tag.new(name: "Audi", parent: car.id)
audi.save!

audi.parents
# => [vehicle, car]
car.is_leaf?
# => false
car.is_node?
# => true
```

# Installation

Run ```gem install forestify``` or add this line to your Gemfile  ```gem 'forestify``` then run ```bundle install```

Although I will add generators later, you still need to manually add migrations to make your models "forestify-ready".

```ruby
change_table :tags do |t|
	t.string :name
	t.integer :left_position
	t.integer :right_position
	t.integer :level
end
```

# LICENSE

Copyright 2012 Gabriel Malkas. Released under MIT License. See LICENSE for details.
