#!/usr/bin/env ruby

require 'json'
require File.expand_path('../../lib/rabbit_feed', __FILE__)

if ARGV.empty?
  puts 'Usage: ./scripts/snowplow_jsonschema_generator.rb FILE_PATH_TO_THE_RABBIT_EVENT_DEFINITIONS'
  exit(0)
end

rabbit_file_path = ARGV.first

load rabbit_file_path

RabbitFeed::Producer.event_definitions.events.each do |name, event|
  hash = {}

  hash['$schema'] = 'http://json-schema.org/schema#'
  hash['type'] = 'object'
  hash['additionalProperties'] = true
  hash['self'] = {
    'vendor'  => 'com.simplybusiness',
    'name'    => name,
    'format'  => 'jsonschema',
    'version' => event.version.gsub('.','-')
  }
  hash['properties'] = {
    'host'        => { 'type' => ['string'] },
    'environment' => { 'type' => ['string'] }
  }

  event.fields.each do |field|
    hash['properties'].merge({
      field.name => {'type' => Array(field.type)}
    })
  end

  puts '************************************'
  puts hash.to_json
end
