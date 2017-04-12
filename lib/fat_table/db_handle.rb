module FatTable
  class << self; attr_accessor :handle; end

  def self.set_db(driver: 'Pg',
                  database:,
                  user:,
                  password:,
                  host: 'localhost',
                  port: '5432',
                  socket: '/tmp/.s.PGSQL.5432')
    raise ArgumentError, 'must supply database name to set_db' unless database
    raise ArgumentError, 'must supply user to set_db' unless user
    raise ArgumentError, 'must supply password to set_db' unless password

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
    self.handle = ::DBI.connect(dsn, user, password)
    raise 'Could not connect to #{dsn}' unless handle
    handle
  end

  def self.db
    handle
  end
end
