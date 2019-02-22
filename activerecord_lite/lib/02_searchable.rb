require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
  def where(params)
    colsets = params.keys.map { |col| col.to_s + " = ? AND "}.join[0..-5]
    values = params.values #must have distinct string values; can't do .join(", ")
    results = DBConnection.execute(<<-SQL, *values)
    SELECT 
      * 
    FROM
      #{self.table_name}
    WHERE 
      #{colsets}
    SQL
    return results if results.empty?
    results.map { |hash_obj| self.new(hash_obj) }
  end
end

class SQLObject
  extend Searchable
end
