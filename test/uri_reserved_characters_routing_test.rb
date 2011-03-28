require 'test_helper'

# See RFC 3986, section 3.3 for allowed path characters.
class UriReservedCharactersRoutingTest < Test::Unit::TestCase
  include RoutingTestHelpers

  def setup
    set.draw { |map| map.connect ':controller/:action/:variable/*additional' }

    safe, unsafe = %w(: @ & = + $ , ;), %w(^ ? # [ ])
    hex = unsafe.map { |char| '%' + char.unpack('H2').first.upcase }

    @segment = "#{safe.join}#{unsafe.join}".freeze
    @escaped = "#{safe.join}#{hex.join}".freeze
  end

  def test_route_generation_escapes_unsafe_path_characters
    url_for(
      :controller => "content",
      :action => "act#{@segment}ion",
      :variable => "variable",
      :additional => "foo"
    )

    assert_equal "/content/act#{@escaped}ion/var#{@escaped}iable/add#{@escaped}itional-1/add#{@escaped}itional-2",
      url_for(
        :controller => "content",
        :action => "act#{@segment}ion",
        :variable => "var#{@segment}iable",
        :additional => ["add#{@segment}itional-1", "add#{@segment}itional-2"]
      )
  end

  def test_route_recognition_unescapes_path_components
    options = {
      :controller => "content",
      :action => "act#{@segment}ion",
      :variable => "var#{@segment}iable",
      :additional => ["add#{@segment}itional-1", "add#{@segment}itional-2"]
    }

    assert_equal options, recognize_path("/content/act#{@escaped}ion/var#{@escaped}iable/add#{@escaped}itional-1/add#{@escaped}itional-2")
  end

  def test_route_generation_allows_passing_non_string_values_to_generated_helper
    assert_equal "/content/action/variable/1/2",
      url_for(
        :controller => "content",
        :action => "action",
        :variable => "variable",
        :additional => [1, 2]
      )
  end
end
