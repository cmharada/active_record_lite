require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_criterion = params.map do |col, val|
      value = val.is_a?(String) ? "\"#{ val }\"" : val.to_s
      " #{ col.to_s } = #{ value }"
    end
    sql_results = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{ self.table_name }
    WHERE
      #{ where_criterion.join(" AND ") }
    SQL
    sql_results.map do |hash|
      self.new(hash)
    end
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
