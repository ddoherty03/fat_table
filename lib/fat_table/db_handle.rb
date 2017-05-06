module FatTable
  class << self;
    # The +DBI+ database handle returned by the last successful call to
    # FatTable.set_db.
    attr_accessor :handle
  end

  # This method must be called before calling FatTable.from_sql or
  # FatTable::Table.from_sql in order to specify the database to use.  All of
  # the keyword parameters have a default except +database:+, which must contain
  # the name of the database to query.
  #
  # +driver+::
  #    One of 'Pg' (for Postgresql), 'Mysql' (for Mysql), or 'SQLite3' (for
  #    SQLite3) to specify the +DBI+ driver to use.  You may have to install the
  #    driver to make this work.  By default use 'Pg'.
  #
  # +database+::
  #    The name of the database to access. There is no default for this.
  #
  # +user+::
  #    The user name to use for accessing the database.  It defaults to nil,
  #    which may be interpreted as a default user by the DBI driver being used.
  #
  # +password+::
  #    The password to use for accessing the database.  It defaults to nil,
  #    which may be interpreted as a default password by the DBI driver being used.
  #
  # +host+::
  #    The name of the host on which to look for the database connection,
  #    defaulting to 'localhost'.
  #
  # +port+::
  #    The port number as a string or integer on which to access the database on
  #    the given host.  Defaults to '5432'.  Only used if host is not 'localhost'.
  #
  # +socket+::
  #    The socket to use to access the database if the host is 'localhost'.
  #    Defaults to the standard socket for the Pg driver, '/tmp/.s.PGSQL.5432'.
  #
  # If successful the database handle for DBI is return.
  # Once called successfully, this establishes the database handle to use for
  # all subsequent calls to FatTable.from_sql or FatTable::Table.from_sql.  You
  # can then access the handle if needed with FatTable.db.
  def self.set_db(driver: 'Pg',
                  database:,
                  user: nil,
                  password: nil,
                  host: 'localhost',
                  port: '5432',
                  socket: '/tmp/.s.PGSQL.5432')
    raise UserError, 'must supply database name to set_db' unless database

    valid_drivers = ['Pg', 'Mysql', 'SQLite3']
    unless valid_drivers.include?(driver)
      raise UserError, "set_db driver must be one of #{valid_drivers.join(' or ')}"
    end
    # In case port is given as an integer
    port = port.to_s if port

    # Set the dsn for DBI
    dsn =
      if host == 'localhost'
        "DBI:Pg:database=#{database};host=#{host};socket=#{socket}"
      else
        "DBI:Pg:database=#{database};host=#{host};port=#{port}"
      end
    begin
      self.handle = ::DBI.connect(dsn, user, password)
    rescue DBI::OperationalError => ex
      raise TransientError, "#{dsn}: #{ex}"
    end
    handle
  end

  # Return the +DBI+ database handle as returned by the last call to
  # FatTable.set_db.
  def self.db
    handle
  end
end
