# Set and access a database by module-level methods.
module FatTable
  class << self
    # The +Sequel+ database handle to use in calls to +FatTable.from_sql+.
    attr_accessor :handle
  end

  # This method must be called before calling +FatTable.from_sql+ or
  # +FatTable::Table.from_sql+ in order to specify the database to use.
  #
  # You can pass in a +Sequel+ connection with +db+, or have fat_table construct
  # a uri from given components. In the latter case, all of the keyword
  # parameters have a default except +database:+, which must contain the name of
  # the database to query.
  #
  # +db+::
  #    Inject a Sequel connection constructed +Sequel.connect+ or one of
  #    Sequel's adapter-specific connection methods.
  #    http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html
  #
  # +adapter+::
  #    One of 'pg' (for Postgresql), 'mysql' or 'mysql2' (for Mysql), or
  #    'sqlite' (for SQLite3) to specify the +Sequel+ driver to use. You may
  #    have to install the driver to make this work. By default use 'Pg'.
  #
  # +database+::
  #    The name of the database to access. There is no default for this.
  #
  # +user+::
  #    The user name to use for accessing the database. It defaults to nil,
  #    which may be interpreted as a default user by the Sequel driver being
  #    used.
  #
  # +password+::
  #    The password to use for accessing the database. It defaults to nil, which
  #    may be interpreted as a default password by the Sequel driver being used.
  #
  # +host+::
  #    The name of the host on which to look for the database connection,
  #    defaulting to 'localhost'.
  #
  # +port+::
  #    The port number as a string or integer on which to access the database on
  #    the given host. Defaults to '5432'. Only used if host is not 'localhost'.
  #
  # +socket+::
  #    The socket to use to access the database if the host is 'localhost'.
  #    Defaults to the standard socket for the Pg driver, '/tmp/.s.PGSQL.5432'.
  #
  # If successful the database handle for Sequel is return. Once called
  # successfully, this establishes the database handle to use for all subsequent
  # calls to FatTable.from_sql or FatTable::Table.from_sql. You can then access
  # the handle if needed with FatTable.db.
  def self.connect(args)
    # Set the dsn for Sequel
    begin
      self.handle = Sequel.connect(args)
    rescue Sequel::Error => ex
      raise TransientError, "#{args}: #{ex}"
    end
    handle
  end

  # Return the +Sequel+ database handle.
  def self.db
    handle
  end

  # Directly set the db handle to a Sequel connection formed without
  # FatTable.connect.
  def self.db=(db)
    self.handle = db
  end
end
