require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if @columns 
      return @columns 
    else 
      hash = DBConnection.execute2(<<-SQL)
      SELECT 
        * 
      FROM 
        #{self.table_name}
      SQL
      cols = hash.first
      @columns = cols.map(&:to_sym)
    end
  end

  def self.finalize!
     self.columns.each do |col|
      method_name_get = "#{col}"
      method_name_set = method_name_get + "="
      define_method(method_name_get.to_sym) do
        self.attributes[col]
      end 
      define_method(method_name_set.to_sym) do |new_val = nil|
        self.attributes[col] = new_val
      end
    end 
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    hash_objs = DBConnection.execute(<<-SQL)
      SELECT 
        * 
      FROM 
        #{self.table_name}
    SQL
   self.parse_all(hash_objs)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end 
  end

  def self.find(id)
    hash_obj = DBConnection.execute(<<-SQL, id)
      SELECT 
        * 
      FROM 
        #{self.table_name}
      WHERE id = ?
    SQL
    return nil if hash_obj.empty?
    self.new(hash_obj.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym
      if self.class.columns.include?(attr_sym)
        self.send("#{attr_name}=", value)
      else  
        raise(Exception, "unknown attribute '#{attr_name}'")
      end 
    end
    self
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    colnames = self.class.columns[1..-1].join(", ") #don't use id column
    question_marks = colnames.split(", ").map { |val| "?" }.join(", ")
    values = self.attribute_values

    DBConnection.execute(<<-SQL, *values)
    INSERT INTO
      #{self.class.table_name} (#{colnames})
    VALUES 
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    colsets = self.class.columns[1..-1].map { |col| col.to_s + " = ?, "}.join[0..-3]
    values = self.attribute_values[1..-1] #don't use id value
    DBConnection.execute(<<-SQL, *values, self.id)
    UPDATE
      #{self.class.table_name}
    SET 
      #{colsets}
    WHERE 
      id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert 
    else  
      self.update 
    end 
  end
end
