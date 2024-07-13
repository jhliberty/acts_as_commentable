require 'rails/generators/migration'

class CommentGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  def self.source_root
    @source_root ||= File.expand_path('templates', __dir__)
  end

  def self.next_migration_number(_path)
    Time.now.utc.strftime('%Y%m%d%H%M%S')
  end

  def create_model_file
    template 'comment.rb', 'app/models/comment.rb'
    migration_template 'create_comments.rb', 'db/migrate/create_comments.rb'
  end
end
