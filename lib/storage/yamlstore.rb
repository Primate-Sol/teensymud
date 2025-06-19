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

    # Define all known serializable classes expected in YAML
    PERMITTED_CLASSES = [Exit, Room, Player, Item, NPC, Command] rescue []

    # Read raw YAML content
    yaml_data = File.read(@dbfile)

    # Safely deserialize YAML while allowing only explicitly permitted classes.
    # WARNING: 'aliases: true' allows YAML anchors and references which may lead to 
    # potential memory abuse or DoS if used with untrusted input.
    # This is acceptable here because the source (our .yaml file) is trusted and internal.
    objects = Psych.safe_load(
      yaml_data,
      permitted_classes: PERMITTED_CLASSES,
      aliases: true
    )

    # Populate internal object store and track the highest ID
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
  # [+return+] Undefined.
  def save
    File.open(@dbfile, 'w') do |f|
      YAML.dump(@db.values, f)
    end
  end

  # Adds a new object to the database.
  # [+obj+] is a reference to object to be added
  # [+return+] Undefined.
  def put(obj)
    @db[obj.id] = obj
    obj
  end

  # Deletes an object from the database.
  # [+oid+] is the id to be deleted.
  # [+return+] Undefined.
  def delete(oid)
    @db.delete(oid)
  end

  # Finds an object in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] Handle to the object or nil.
  def get(oid)
    @db[oid]
  end

  # Check if an object is in the database by its id.
  # [+oid+] is the id to use in the search.
  # [+return+] true or false
  def check(oid)
    @db.has_key?(oid)
  end

  # Iterate through all objects
  # [+yield+] Each object in database to block of caller.
  def each(&blk)
    @db.each_value(&blk)
  end

private

  # Checks that the database exists and builds one if not
  # Will raise an exception if something goes wrong.
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
