module RailsLegacyMapper
  # This gem provides an extraction of the DeprecatedMapper from Rails 3.0

  # Returns the current resource action separator - defaults to '/'
  def self.resource_action_separator
    @resource_action_separator ||= '/'
  end

  # Set the resource action separator, e.g:
  #
  #   # config/initializers/rails_legacy_mapper.rb
  #   RailsLegacyMapper.resource_action_separator = ';'
  def self.resource_action_separator=(value)
    @resource_action_separator = value
  end
end

require 'rails_legacy_mapper/mapper'
require 'rails_legacy_mapper/route_set_extensions'
require 'rails_legacy_mapper/version'
require 'action_dispatch'

ActionDispatch::Routing::RouteSet.send(:include, RailsLegacyMapper::RouteSetExtensions)
