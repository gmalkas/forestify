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
# This produces the following tree
# { left_position, name, right_position, level }
# { 0, Vehicle, 9, 0 } { 10, Animal, 11, 0}
# { 1, Car, 4, 1 } { 5, Plane, 6, 1 } { 7, Boat, 8, 1 }
# { 2, Audi, 3, 2}

vehicle = Tag.create!(name: "Vehicle")
animal = Tag.create!(name: "Animal")
car = Tag.create!(name: "Car", parent_id: vehicle.id)
plane = Tag.create!(name: "plane", parent_id: vehicle.id)
boat = Tag.create!(name: "Boat", parent_id: vehicle.id)
audi = Tag.create!(name: "Audi", parent_id: car.id)

[vehicle, animal, car, plane, boat, audi].each { |n| n.reload }

audi.parents
# => [vehicle, car]
car.is_leaf?
# => false
car.is_node?
# => true
vehicle.parent.nil?
# => true
car.siblings.all
# => [plane, boat]
```

# Installation

Run ```gem install forestify``` or add this line to your Gemfile  ```gem 'forestify'``` then run ```bundle install```

Although I will add generators later, you still need to manually add migrations to make your models "forestify-ready".

```ruby
change_table :tags do |t|
  t.integer :left_position
  t.integer :right_position
  t.integer :level
end
```

# Updates
## 2012-02-06 version 1.0.1
* Cleaned up tests, added two methods: 'siblings' and 'parent'

## 2012-02-05 version 1.0.0
* First draft

# LICENSE

Copyright 2012 Gabriel Malkas. Released under MIT License. See LICENSE for details.
