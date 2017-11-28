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
  # +driver+::
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
  def self.set_db(db: nil,
                  driver: 'postgres',
                  database:,
                  user: ENV['LOGNAME'],
                  password: nil,
                  host: 'localhost',
                  port: '5432',
                  socket: '/tmp/.s.PGSQL.5432')
    if db
      self.handle = db
    else
      raise UserError, 'must supply database name to set_db' unless database

      valid_drivers = %w[postgres mysql mysql2 sqlite]
      unless valid_drivers.include?(driver)
        msg = "'#{driver}' driver must be one of #{valid_drivers.join(' or ')}"
        raise UserError, msg
      end
      if database.blank?
        raise UserError, 'must supply database parameter to set_db'
      end

      if driver == 'sqlite'
        dsn = "sqlite://#{database}"
      else
        pw_part = password ? ":#{password}" : ''
        hst_part = host ? "@#{host}" : ''
        prt_part = port ? ":#{port}" : ''
        dsn = "#{driver}:://#{user}#{pw_part}#{hst_part}#{prt_part}/#{database}"
      end

      # Set the dsn for Sequel
      begin
        self.handle = Sequel.connect(dsn)
      rescue Sequel::Error => ex
        raise TransientError, "#{dsn}: #{ex}"
      end
    end
    handle
  end

  # Return the +Sequel+ database handle.
  def self.db
    handle
  end

  # Directly set the db handle to a Sequel connection formed without
  # FatTable.set_db.
  def self.db=(db)
    self.handle = db
  end
end
