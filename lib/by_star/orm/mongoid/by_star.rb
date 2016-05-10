# In keeping with Mongoid standards, this module must be included into your model class, i.e.
#
#   include Mongoid::ByStar
#
module Mongoid
  module ByStar
    extend ActiveSupport::Concern

    module ClassMethods
      include ::ByStar::Base

      protected

      def by_star_end_field_with_mongoid(options = {})
        database_field_name by_star_end_field_without_mongoid(options)
      end
      alias_method_chain :by_star_end_field, :mongoid

      def by_star_start_field_with_mongoid(options = {})
        database_field_name by_star_start_field_without_mongoid(options)
      end
      alias_method_chain :by_star_start_field, :mongoid

      def by_star_default_field
        :created_at
      end

      def by_star_point_query(scope, field, range)
        scope.where(field => range)
      end

      def by_star_strict_span_query(scope, start_field, end_field, range)
        scope.where(start_field => range).where(end_field => range)
      end

      def by_star_overlap_span_query(scope, start_field, end_field, range, options)
        index_start = by_star_eval_index_start(range, options)
        scope = scope.gt(end_field => range.first).lt(start_field => range.last)
        scope = scope.gte(start_field => index_start) if index_start
        scope
      end

      def before_query(time, options={})
        field = by_star_start_field(options)
        by_star_scope(options).lte(field => time)
      end

      def after_query(time, options={})
        field = by_star_start_field(options)
        by_star_scope(options).gte(field => time)
      end

      def oldest_query(options={})
        field = by_star_start_field(options)
        by_star_scope(options).all.reorder(field => :asc).first
      end

      def newest_query(options={})
        field = by_star_start_field(options)
        by_star_scope(options).all.reorder(field => :desc).first
      end
    end

    def previous(options={})
      field = self.class.by_star_start_field(options)
      self.class.by_star_scope(options.merge(scope_args: self)).lt(field => self.send(field)).reorder(field => :desc).first
    end

    def next(options={})
      field = self.class.by_star_start_field(options)
      self.class.by_star_scope(options.merge(scope_args: self)).gt(field => self.send(field)).reorder(field => :asc).first
    end
  end
end
