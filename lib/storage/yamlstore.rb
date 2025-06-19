#
# file::    yamlstore.rb
# author::  Jon A. Lambert
# version:: 2.8.0
# date::    01/19/2006
#
# This source code copyright (C) 2005, 2006 by Jon A. Lambert
# All rights reserved.
#
# Released under the terms of the TeensyMUD Public License
# See LICENSE file for additional information.
#
$:.unshift "lib" if !$:.include? "lib"
$:.unshift "vendor" if !$:.include? "vendor"

require 'yaml'
require 'utility/log'
require 'storage/store'

class YamlStore < Store
  logger 'DEBUG'

  def initialize(dbfile)
    super()
    @dbfile = "#{dbfile}.yaml"

    build_database
    log.info "Loading world..."
    @db = {}

    # Add all used object classes here
    PERMITTED_CLASSES = [Exit, Room, Player, Item, NPC, Command] rescue []

    yaml_data = File.read(@dbfile)
    objects = Psych.safe_load(yaml_data, permitted_classes: PERMITTED_CLASSES, aliases: true)

    objects.each do |o|
      @dbtop = o.id if o.id > @dbtop
      @db[o.id] = o
    end

    log.info "Database '#{@dbfile}' loaded...highest id = #{@dbtop}."
  rescue => e
    log.fatal "Error loading database"
    log.fatal e
    raise
  end
