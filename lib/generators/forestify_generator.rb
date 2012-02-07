require 'rails/generators/active_record'

# See https://github.com/olkarls/has_permalink/blob/master/lib/generators/has_permalink_generator.rb
class ForestifyGenerator < ActiveRecord::Generators::Base

  desc "This generator creates a migration file to make your existing model 'forestify-ready'"

  def self.source_root
    @source_root ||= File.expand_path('../templates', __FILE__)
  end

  def generate_migration
    migration_template "forestify_migration.rb.erb", "db/migrate/#{migration_file_name}"
  end

  protected

  def migration_name
    "add_forestify_to_#{name.underscore}"
  end

  def migration_file_name
    "#{migration_name}.rb"
  end

  def migration_class_name
    migration_name.camelize
  end

end
