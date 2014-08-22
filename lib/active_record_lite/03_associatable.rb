require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key]
    @foreign_key ||= name.to_s.foreign_key.to_sym
    @class_name = options[:class_name]
    @class_name ||= name.to_s.classify
    @primary_key = options[:primary_key]
    @primary_key ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key]
    @foreign_key ||= self_class_name.foreign_key.to_sym
    @class_name = options[:class_name]
    @class_name ||= name.to_s.classify
    @primary_key = options[:primary_key]
    @primary_key ||= :id
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    
    assoc_options[name] = options
    
    define_method name do 
      f_key = send(options.foreign_key)
      options.model_class.where("#{ options.primary_key }" => f_key).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method name do
      p_key = send(options.primary_key)
      options.model_class.where("#{ options.foreign_key }" => p_key)
    end
  end

  def assoc_options
    @assoc_options ||= { }
    @assoc_options
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
