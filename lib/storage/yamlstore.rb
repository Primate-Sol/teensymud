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

# The YamlStore class manages access to all object storage using YAML files.
#
# YamlStore provides YAML-based persistent storage for game objects.
# It deserializes data using Psych.safe_load with an explicit list of permitted classes
# and disables YAML aliases to mitigate deserialization vulnerabilities such as 
# memory exhaustion or reference abuse attacks.
#
# [+db+]     stores the hash of loaded game objects.
# [+dbtop+]  tracks the highest object ID in the database.
class YamlStore < Store
  logger 'DEBUG'

  # Define the list of classes allowed to be deserialized from YAML
  PERMITTED_CLASSES = [Exit, Room, Player, Item, NPC, Command] rescue []

  def initialize(dbfile)
    super()
    @dbfile = "#{dbfile}.yaml"

    build_database
    log.info "Loading world..."
    @db = {}

    # Read and safely load YAML data with permitted classes
    # SECURITY: aliases disabled to prevent memory exhaustion attacks
    yaml_data = File.read(@dbfile)
    objects = Psych.safe_load(
      yaml_data,
      permitted_classes: PERMITTED_CLASSES,
      aliases: false
    )

    # Populate database and track highest object ID
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

  # Save the world
  def save
    File.open(@dbfile, 'w') do |f|
      YAML.dump(@db.values, f)
    end
  end

  def put(obj)
    @db[obj.id] = obj
    obj
  end

  def delete(oid)
    @db.delete(oid)
  end

  def get(oid)
    @db[oid]
  end

  def check(oid)
    @db.has_key?(oid)
  end

  def each(&blk)
    @db.each_value(&blk)
  end

private

  def build_database
    unless File.exist?(@dbfile)
      log.info "Building minimal world database..."
      File.open(@dbfile, 'w') do |f|
        f.write(MINIMAL_DB)
      end
    end
  rescue => e
    log.fatal "Unable to find or build database '#{@dbfile}'"
    log.fatal e
    raise
  end
end
