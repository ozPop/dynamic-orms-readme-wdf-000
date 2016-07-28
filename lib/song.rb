require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    # interpolated tabled_name is a class method call
    # PRAGMA table_info returns an array of hashes
    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      # "name" selects only name values from each row
      column_names << row["name"]
    end
    # using `compact` to remove nil in case any exist
    # returns array of only column names
    column_names.compact
  end

  # sets up attr_accessors using the column names
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  # expects a `new` to b called with a hash
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  # uses helper methods to insert table/column names, and values
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # relies on table_name method above to get instance of the class, NOT the class itself!
  # here we use a class method inside an instance method
  def table_name_for_insert
    self.class.table_name
  end

  # getting values to insert into table
  # using column_names method return, iterate over each name invoking the send 
  # using that name and capture return of send as value in values (handle id = nil)
  # formats the array into a comma separated string (with quotes)
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # getting column names to insert into table
  # removes `id` from column_names array before using in `send`
  # formats the array into a comma separated string
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



