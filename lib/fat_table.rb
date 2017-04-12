require "fat_table/version"

module FatTable
  require 'fat_core'
  require 'dbi'
  require 'active_support'
  require 'active_support/core_ext'
  require 'active_support/number_helper'

  require 'fat_table/evaluator'
  require 'fat_table/column'
  require 'fat_table/table'
  require 'fat_table/formatters'
  require 'fat_table/db_handle'
end
