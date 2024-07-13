# frozen_string_literal: true

ActiveRecord::Schema.define(version: 0) do
  create_table :posts do |t|
    t.text :text
    t.timestamps
  end

  create_table :users do |u|
    u.string :name
  end

  create_table :walls do |w|
    w.string :name
  end
end
