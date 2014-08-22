require_relative '03_associatable'

# Phase V
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]
    
    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]
      through_table = through_options.model_class.table_name
      source_table = source_options.model_class.table_name
      sql_result = DBConnection.execute(<<-SQL)
      SELECT
        #{ source_table }.*
      FROM
        #{ self.class.table_name }
      JOIN
        #{ through_table }
      ON
        #{ self.class.table_name }.#{ through_options.foreign_key } =
        #{ through_table }.#{ through_options.primary_key }
      JOIN
        #{ source_table }
      ON
        #{ through_table }.#{ source_options.foreign_key } = 
        #{ source_table }.#{ source_options.primary_key }
      WHERE
        #{ self.class.table_name }.id = #{ self.id }
      SQL
      source_options.model_class.new(sql_result.first)
    end
  end
end
