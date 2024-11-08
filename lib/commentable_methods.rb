require 'active_record'

# ActsAsCommentable
module Juixe
  module Acts # :nodoc:
    module Commentable # :nodoc:
      def self.included(base)
        base.extend ClassMethods
      end

      module HelperMethods
        private

        def define_role_based_inflection(role)
          return if method_defined?(:"#{role}_comments")

          has_many :"#{role}_comments",
                   -> { where(role: role.to_s) },
                   **has_many_options(role)
        end

        def has_many_options(role)
          { class_name: 'Comment',
            as: :commentable,
            dependent: :destroy,
            before_add: proc { |_x, c| c.role = role.to_s } }
        end
      end

      module ClassMethods
        include HelperMethods

        def acts_as_commentable(*args)
          # Detect if we already loaded
          return if method_defined?(:comment_types)

          options = args.to_a.flatten.compact.partition { |opt| opt.is_a? Hash }
          comment_roles = options.last.blank? ? nil : options.last.flatten.compact.map(&:to_sym)

          join_options = options.first.blank? ? [{}] : options.first
          throw 'Only one set of options can be supplied for the join' if join_options.length > 1
          join_options = join_options.first

          class_attribute :comment_types
          self.comment_types = (comment_roles.blank? ? [:comments] : comment_roles)

          if comment_roles.blank?
            has_many :comments, as: :commentable, dependent: :destroy, **join_options
          else
            comment_roles.each do |role|
              define_role_based_inflection(role)
            end
            has_many :all_comments, as: :commentable, dependent: :destroy, class_name: 'Comment', **join_options
          end

          comment_types.each do |role|
            method_name = (role == :comments ? 'comments' : "#{role}_comments").to_s

            class_eval %{
              def self.find_#{method_name}_for(obj)
                commentable = self.base_class.name
                Comment.find_comments_for_commentable(commentable, obj.id, "#{role}")
              end

              def self.find_#{method_name}_by_user(user)
                commentable = self.base_class.name
                Comment.where([
                  "user_id = ? and commentable_type = ? and role = ?", user.id, commentable, "#{role}"
                ]).order("created_at DESC")
              end

              def #{method_name}_ordered_by_submitted
                Comment.find_comments_for_commentable(self.class.name, id, "#{role}").order("created_at")
              end

              def add_#{method_name.singularize}(comment)
                comment.role = "#{role}"
                #{method_name} << comment
              end
            }, __FILE__, __LINE__ - 21
          end
        end
      end
    end
  end
end

ActiveRecord::Base.include Juixe::Acts::Commentable
