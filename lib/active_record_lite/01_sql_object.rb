require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
      #{ self.table_name }
    SQL
    cols.first.map do |column|
      column.to_sym
    end
  end

  def self.finalize!
    self.columns.each do |column_name|
      define_method column_name.to_s do
        self.attributes[column_name]
      end
      define_method "#{ column_name.to_s }=" do |value|
        self.attributes[column_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name = self.name.tableize if @table_name.nil?
    @table_name
  end

  def self.all
    sql_result = DBConnection.execute(<<-SQL)
    SELECT
      #{ self.table_name }.*
    FROM
      #{ self.table_name }
    SQL
    self.parse_all(sql_result)
  end

  def self.parse_all(results)
    results.map do |row|
      next_obj = self.new
      row.each do |column, value|
        next_obj.send("#{ column.to_sym }=", value)
      end
      next_obj
    end
  end

  def self.find(id)
    sql_result = DBConnection.execute(<<-SQL, id)
    SELECT
      #{ self.table_name }.*
    FROM
      #{ self.table_name }
    WHERE
      id = ?
    SQL
    self.parse_all(sql_result).first
  end

  def attributes
    @attributes = {} if @attributes.nil?
    @attributes
  end

  def insert
    col_names = self.class.columns.map { |c| c.to_s }
    col_names.delete("id")
    values = attribute_values.compact.map do |el|
      el.is_a?(String) ? "\'#{ el.to_s }\'" : el.to_s
    end.join(",")
    DBConnection.execute(<<-SQL)
    INSERT INTO
      #{ self.class.table_name} (#{ col_names.join(",") }) 
    VALUES 
      (#{ values })
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    params.each do |key, value|
      attr_name = key.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute \'#{ attr_name }\'"
      end
      self.send("#{ key }=", value)
    end
  end

  def save
    id.nil? ? insert : update
  end

  def update
    set_values = self.class.columns.map do |col|
      el = self.send(col.to_s)
      value = el.is_a?(String) ? "\'#{ el }'" : el.to_s
      "#{ col.to_s } = #{ value }"
    end
    DBConnection.execute(<<-SQL)
    UPDATE
    #{ self.class.table_name }
    SET
    #{ set_values.join(",") }
    WHERE
    id = #{ self.id }
    SQL
  end

  def attribute_values
    self.class.columns.map { |c| self.send(c.to_s) }
  end
end
