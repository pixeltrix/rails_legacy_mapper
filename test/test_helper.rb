require 'test/unit'
require 'mocha'
require 'action_controller'
require 'fake_controllers'
require 'rails_legacy_mapper'

ROUTING = ActionDispatch::Routing

class MockController
  def self.build(helpers)
    Class.new do
      def url_for(options)
        options[:protocol] ||= "http"
        options[:host] ||= "test.host"

        super(options)
      end

      include helpers
    end
  end
end

module RoutingTestHelpers
  def extra_keys(options, recall = {})
    set.extra_keys(options, recall)
  end

  def generate_extras(options, recall = {})
    set.generate_extras(options, recall)
  end

  def recognize_path(path, env = {})
    set.recognize_path(path, env)
  end

  def request
    @request ||= ActionDispatch::TestRequest.new
  end

  def set
    @set ||= ROUTING::RouteSet.new
  end

  def url_for(options, recall = nil)
    set.send(:url_for, options.merge(:only_path => true, :_path_segments => recall))
  end
end
