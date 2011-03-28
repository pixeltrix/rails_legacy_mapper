require 'test_helper'

class RouteSetTest < ActiveSupport::TestCase
  include RoutingTestHelpers

  def default_set
    @default_route_set ||= begin
      set = ROUTING::RouteSet.new
      set.draw do |map|
        map.connect '/:controller/:action/:id/'
      end
      set
    end
  end

  def default_recognize_path(path, env = {})
    default_set.recognize_path(path, env)
  end

  def default_url_for(options, recall = nil)
    default_set.send(:url_for, options.merge(:only_path => true, :_path_segments => recall))
  end

  def test_generate_extras
    set.draw { |m| m.connect ':controller/:action/:id' }
    path, extras = generate_extras(:controller => "foo", :action => "bar", :id => 15, :this => "hello", :that => "world")
    assert_equal "/foo/bar/15", path
    assert_equal %w(that this), extras.map { |e| e.to_s }.sort
  end

  def test_extra_keys
    set.draw { |m| m.connect ':controller/:action/:id' }
    extras = extra_keys(:controller => "foo", :action => "bar", :id => 15, :this => "hello", :that => "world")
    assert_equal %w(that this), extras.map { |e| e.to_s }.sort
  end

  def test_generate_extras_not_first
    set.draw do |map|
      map.connect ':controller/:action/:id.:format'
      map.connect ':controller/:action/:id'
    end
    path, extras = generate_extras(:controller => "foo", :action => "bar", :id => 15, :this => "hello", :that => "world")
    assert_equal "/foo/bar/15", path
    assert_equal %w(that this), extras.map { |e| e.to_s }.sort
  end

  def test_generate_not_first
    set.draw do |map|
      map.connect ':controller/:action/:id.:format'
      map.connect ':controller/:action/:id'
    end
    assert_equal "/foo/bar/15?this=hello", url_for(:controller => "foo", :action => "bar", :id => 15, :this => "hello")
  end

  def test_extra_keys_not_first
    set.draw do |map|
      map.connect ':controller/:action/:id.:format'
      map.connect ':controller/:action/:id'
    end
    extras = set.extra_keys(:controller => "foo", :action => "bar", :id => 15, :this => "hello", :that => "world")
    assert_equal %w(that this), extras.map { |e| e.to_s }.sort
  end

  def test_draw
    assert_equal 0, set.routes.size
    set.draw do |map|
      map.connect '/hello/world', :controller => 'a', :action => 'b'
    end
    assert_equal 1, set.routes.size
  end

  def test_draw_symbol_controller_name
    assert_equal 0, set.routes.size
    set.draw do |map|
      map.connect '/users/index', :controller => :users, :action => :index
    end
    params = recognize_path('/users/index', :method => :get)
    assert_equal 1, set.routes.size
  end

  def test_named_draw
    assert_equal 0, set.routes.size
    set.draw do |map|
      map.hello '/hello/world', :controller => 'a', :action => 'b'
    end
    assert_equal 1, set.routes.size
    assert_equal set.routes.first, set.named_routes[:hello]
  end

  def test_later_named_routes_take_precedence
    set.draw do |map|
      map.hello '/hello/world', :controller => 'a', :action => 'b'
      map.hello '/hello', :controller => 'a', :action => 'b'
    end
    assert_equal set.routes.last, set.named_routes[:hello]
  end

  def setup_named_route_test
    set.draw do |map|
      map.show '/people/:id', :controller => 'people', :action => 'show'
      map.index '/people', :controller => 'people', :action => 'index'
      map.multi '/people/go/:foo/:bar/joe/:id', :controller => 'people', :action => 'multi'
      map.users '/admin/users', :controller => 'admin/users', :action => 'index'
    end

    MockController.build(set.url_helpers).new
  end

  def test_named_route_hash_access_method
    controller = setup_named_route_test

    assert_equal(
      { :controller => 'people', :action => 'show', :id => 5, :use_route => :show, :only_path => false },
      controller.send(:hash_for_show_url, :id => 5))

    assert_equal(
      { :controller => 'people', :action => 'index', :use_route => :index, :only_path => false },
      controller.send(:hash_for_index_url))

    assert_equal(
      { :controller => 'people', :action => 'show', :id => 5, :use_route => :show, :only_path => true },
      controller.send(:hash_for_show_path, :id => 5)
    )
  end

  def test_named_route_url_method
    controller = setup_named_route_test

    assert_equal "http://test.host/people/5", controller.send(:show_url, :id => 5)
    assert_equal "/people/5", controller.send(:show_path, :id => 5)

    assert_equal "http://test.host/people", controller.send(:index_url)
    assert_equal "/people", controller.send(:index_path)

    assert_equal "http://test.host/admin/users", controller.send(:users_url)
    assert_equal '/admin/users', controller.send(:users_path)
    assert_equal '/admin/users', url_for(controller.send(:hash_for_users_url), {:controller => 'users', :action => 'index'})
  end

  def test_named_route_url_method_with_anchor
    controller = setup_named_route_test

    assert_equal "http://test.host/people/5#location", controller.send(:show_url, :id => 5, :anchor => 'location')
    assert_equal "/people/5#location", controller.send(:show_path, :id => 5, :anchor => 'location')

    assert_equal "http://test.host/people#location", controller.send(:index_url, :anchor => 'location')
    assert_equal "/people#location", controller.send(:index_path, :anchor => 'location')

    assert_equal "http://test.host/admin/users#location", controller.send(:users_url, :anchor => 'location')
    assert_equal '/admin/users#location', controller.send(:users_path, :anchor => 'location')

    assert_equal "http://test.host/people/go/7/hello/joe/5#location",
      controller.send(:multi_url, 7, "hello", 5, :anchor => 'location')

    assert_equal "http://test.host/people/go/7/hello/joe/5?baz=bar#location",
      controller.send(:multi_url, 7, "hello", 5, :baz => "bar", :anchor => 'location')

    assert_equal "http://test.host/people?baz=bar#location",
      controller.send(:index_url, :baz => "bar", :anchor => 'location')
  end

  def test_named_route_url_method_with_port
    controller = setup_named_route_test
    assert_equal "http://test.host:8080/people/5", controller.send(:show_url, 5, :port=>8080)
  end

  def test_named_route_url_method_with_host
    controller = setup_named_route_test
    assert_equal "http://some.example.com/people/5", controller.send(:show_url, 5, :host=>"some.example.com")
  end

  def test_named_route_url_method_with_protocol
    controller = setup_named_route_test
    assert_equal "https://test.host/people/5", controller.send(:show_url, 5, :protocol => "https")
  end

  def test_named_route_url_method_with_ordered_parameters
    controller = setup_named_route_test
    assert_equal "http://test.host/people/go/7/hello/joe/5",
      controller.send(:multi_url, 7, "hello", 5)
  end

  def test_named_route_url_method_with_ordered_parameters_and_hash
    controller = setup_named_route_test
    assert_equal "http://test.host/people/go/7/hello/joe/5?baz=bar",
      controller.send(:multi_url, 7, "hello", 5, :baz => "bar")
  end

  def test_named_route_url_method_with_ordered_parameters_and_empty_hash
    controller = setup_named_route_test
    assert_equal "http://test.host/people/go/7/hello/joe/5",
      controller.send(:multi_url, 7, "hello", 5, {})
  end

  def test_named_route_url_method_with_no_positional_arguments
    controller = setup_named_route_test
    assert_equal "http://test.host/people?baz=bar",
      controller.send(:index_url, :baz => "bar")
  end

  def test_draw_default_route
    set.draw do |map|
      map.connect '/:controller/:action/:id'
    end

    assert_equal 1, set.routes.size

    assert_equal '/users/show/10', url_for(:controller => 'users', :action => 'show', :id => 10)
    assert_equal '/users/index/10', url_for(:controller => 'users', :id => 10)

    assert_equal({:controller => 'users', :action => 'index', :id => '10'}, recognize_path('/users/index/10'))
    assert_equal({:controller => 'users', :action => 'index', :id => '10'}, recognize_path('/users/index/10/'))
  end

  def test_draw_default_route_with_default_controller
    set.draw do |map|
      map.connect '/:controller/:action/:id', :controller => 'users'
    end
    assert_equal({:controller => 'users', :action => 'index'}, recognize_path('/'))
  end

  def test_route_with_parameter_shell
    set.draw do |map|
      map.connect 'page/:id', :controller => 'pages', :action => 'show', :id => /\d+/
      map.connect '/:controller/:action/:id'
    end

    assert_equal({:controller => 'pages', :action => 'index'}, recognize_path('/pages'))
    assert_equal({:controller => 'pages', :action => 'index'}, recognize_path('/pages/index'))
    assert_equal({:controller => 'pages', :action => 'list'}, recognize_path('/pages/list'))

    assert_equal({:controller => 'pages', :action => 'show', :id => '10'}, recognize_path('/pages/show/10'))
    assert_equal({:controller => 'pages', :action => 'show', :id => '10'}, recognize_path('/page/10'))
  end

  def test_route_constraints_on_request_object_with_anchors_are_valid
    assert_nothing_raised do
      set.draw do
        match 'page/:id' => 'pages#show', :constraints => { :host => /^foo$/ }
      end
    end
  end

  def test_route_constraints_with_anchor_chars_are_invalid
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'page/:id', :controller => 'pages', :action => 'show', :id => /^\d+/
      end
    end
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'page/:id', :controller => 'pages', :action => 'show', :id => /\A\d+/
      end
    end
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'page/:id', :controller => 'pages', :action => 'show', :id => /\d+$/
      end
    end
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'page/:id', :controller => 'pages', :action => 'show', :id => /\d+\Z/
      end
    end
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'page/:id', :controller => 'pages', :action => 'show', :id => /\d+\z/
      end
    end
  end

  def test_route_requirements_with_invalid_http_method_is_invalid
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'valid/route', :controller => 'pages', :action => 'show', :conditions => {:method => :invalid}
      end
    end
  end

  def test_route_requirements_with_options_method_condition_is_valid
    assert_nothing_raised do
      set.draw do |map|
        map.connect 'valid/route', :controller => 'pages', :action => 'show', :conditions => {:method => :options}
      end
    end
  end

  def test_route_requirements_with_head_method_condition_is_invalid
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'valid/route', :controller => 'pages', :action => 'show', :conditions => {:method => :head}
      end
    end
  end

  def test_recognize_with_encoded_id_and_regex
    set.draw do |map|
      map.connect 'page/:id', :controller => 'pages', :action => 'show', :id => /[a-zA-Z0-9\+]+/
    end

    assert_equal({:controller => 'pages', :action => 'show', :id => '10'}, recognize_path('/page/10'))
    assert_equal({:controller => 'pages', :action => 'show', :id => 'hello+world'}, recognize_path('/page/hello+world'))
  end

  def test_recognize_with_conditions
    set.draw do |map|
      map.with_options(:controller => "people") do |people|
        people.people  "/people",     :action => "index",   :conditions => { :method => :get }
        people.connect "/people",     :action => "create",  :conditions => { :method => :post }
        people.person  "/people/:id", :action => "show",    :conditions => { :method => :get }
        people.connect "/people/:id", :action => "update",  :conditions => { :method => :put }
        people.connect "/people/:id", :action => "destroy", :conditions => { :method => :delete }
      end
    end

    params = recognize_path("/people", :method => :get)
    assert_equal("index", params[:action])

    params = recognize_path("/people", :method => :post)
    assert_equal("create", params[:action])

    params = recognize_path("/people", :method => :put)
    assert_equal("update", params[:action])

    assert_raise(ActionController::UnknownHttpMethod) {
      recognize_path("/people", :method => :bacon)
    }

    params = recognize_path("/people/5", :method => :get)
    assert_equal("show", params[:action])
    assert_equal("5", params[:id])

    params = recognize_path("/people/5", :method => :put)
    assert_equal("update", params[:action])
    assert_equal("5", params[:id])

    params = recognize_path("/people/5", :method => :delete)
    assert_equal("destroy", params[:action])
    assert_equal("5", params[:id])

    assert_raise(ActionController::RoutingError) {
      recognize_path("/people/5", :method => :post)
    }
  end

  def test_recognize_with_alias_in_conditions
    set.draw do |map|
      map.people "/people", :controller => 'people', :action => "index",
        :conditions => { :method => :get }
      map.root   :people
    end

    params = recognize_path("/people", :method => :get)
    assert_equal("people", params[:controller])
    assert_equal("index", params[:action])

    params = recognize_path("/", :method => :get)
    assert_equal("people", params[:controller])
    assert_equal("index", params[:action])
  end

  def test_typo_recognition
    set.draw do |map|
      map.connect 'articles/:year/:month/:day/:title',
             :controller => 'articles', :action => 'permalink',
             :year => /\d{4}/, :day => /\d{1,2}/, :month => /\d{1,2}/
    end

    params = recognize_path("/articles/2005/11/05/a-very-interesting-article", :method => :get)
    assert_equal("permalink", params[:action])
    assert_equal("2005", params[:year])
    assert_equal("11", params[:month])
    assert_equal("05", params[:day])
    assert_equal("a-very-interesting-article", params[:title])
  end

  def test_routing_traversal_does_not_load_extra_classes
    assert !Object.const_defined?("Profiler__"), "Profiler should not be loaded"
    set.draw do |map|
      map.connect '/profile', :controller => 'profile'
    end

    params = recognize_path("/profile") rescue nil

    assert !Object.const_defined?("Profiler__"), "Profiler should not be loaded"
  end

  def test_recognize_with_conditions_and_format
    set.draw do |map|
      map.with_options(:controller => "people") do |people|
        people.person  "/people/:id", :action => "show",    :conditions => { :method => :get }
        people.connect "/people/:id", :action => "update",  :conditions => { :method => :put }
        people.connect "/people/:id.:_format", :action => "show", :conditions => { :method => :get }
      end
    end

    params = recognize_path("/people/5", :method => :get)
    assert_equal("show", params[:action])
    assert_equal("5", params[:id])

    params = recognize_path("/people/5", :method => :put)
    assert_equal("update", params[:action])

    params = recognize_path("/people/5.png", :method => :get)
    assert_equal("show", params[:action])
    assert_equal("5", params[:id])
    assert_equal("png", params[:_format])
  end

  def test_generate_with_default_action
    set.draw do |map|
      map.connect "/people", :controller => "people"
      map.connect "/people/list", :controller => "people", :action => "list"
    end

    url = url_for(:controller => "people", :action => "list")
    assert_equal "/people/list", url
  end

  def test_root_map
    set.draw { |map| map.root :controller => "people" }

    params = recognize_path("", :method => :get)
    assert_equal("people", params[:controller])
    assert_equal("index", params[:action])
  end

  def test_namespace
    set.draw do |map|

      map.namespace 'api' do |api|
        api.route 'inventory', :controller => "products", :action => 'inventory'
      end

    end

    params = recognize_path("/api/inventory", :method => :get)
    assert_equal("api/products", params[:controller])
    assert_equal("inventory", params[:action])
  end

  def test_namespaced_root_map
    set.draw do |map|

      map.namespace 'api' do |api|
        api.root :controller => "products"
      end

    end

    params = recognize_path("/api", :method => :get)
    assert_equal("api/products", params[:controller])
    assert_equal("index", params[:action])
  end

  def test_namespace_with_path_prefix
    set.draw do |map|
      map.namespace 'api', :path_prefix => 'prefix' do |api|
        api.route 'inventory', :controller => "products", :action => 'inventory'
      end
    end

    params = recognize_path("/prefix/inventory", :method => :get)
    assert_equal("api/products", params[:controller])
    assert_equal("inventory", params[:action])
  end

  def test_namespace_with_blank_path_prefix
    set.draw do |map|
      map.namespace 'api', :path_prefix => '' do |api|
        api.route 'inventory', :controller => "products", :action => 'inventory'
      end
    end

    params = recognize_path("/inventory", :method => :get)
    assert_equal("api/products", params[:controller])
    assert_equal("inventory", params[:action])
  end

  def test_generate_changes_controller_module
    set.draw { |map| map.connect ':controller/:action/:id' }
    current = { :controller => "bling/bloop", :action => "bap", :id => 9 }
    url = url_for({:controller => "foo/bar", :action => "baz", :id => 7}, current)
    assert_equal "/foo/bar/baz/7", url
  end

  def test_id_is_sticky_when_it_ought_to_be
    set.draw do |map|
      map.connect ':controller/:id/:action'
    end

    url = url_for({:action => "destroy"}, {:controller => "people", :action => "show", :id => "7"})
    assert_equal "/people/7/destroy", url
  end

  def test_use_static_path_when_possible
    set.draw do |map|
      map.connect 'about', :controller => "welcome", :action => "about"
      map.connect ':controller/:action/:id'
    end

    url = url_for({:controller => "welcome", :action => "about"},
      {:controller => "welcome", :action => "get", :id => "7"})
    assert_equal "/about", url
  end

  def test_generate
    set.draw { |map| map.connect ':controller/:action/:id' }

    args = { :controller => "foo", :action => "bar", :id => "7", :x => "y" }
    assert_equal "/foo/bar/7?x=y", url_for(args)
    assert_equal ["/foo/bar/7", [:x]], generate_extras(args)
    assert_equal [:x], set.extra_keys(args)
  end

  def test_generate_with_path_prefix
    set.draw { |map| map.connect ':controller/:action/:id', :path_prefix => 'my' }

    args = { :controller => "foo", :action => "bar", :id => "7", :x => "y" }
    assert_equal "/my/foo/bar/7?x=y", url_for(args)
  end

  def test_generate_with_blank_path_prefix
    set.draw { |map| map.connect ':controller/:action/:id', :path_prefix => '' }

    args = { :controller => "foo", :action => "bar", :id => "7", :x => "y" }
    assert_equal "/foo/bar/7?x=y", url_for(args)
  end

  def test_named_routes_are_never_relative_to_modules
    set.draw do |map|
      map.connect "/connection/manage/:action", :controller => 'connection/manage'
      map.connect "/connection/connection", :controller => "connection/connection"
      map.family_connection "/connection", :controller => "connection"
    end

    url = url_for({:controller => "connection"}, {:controller => 'connection/manage'})
    assert_equal "/connection/connection", url

    url = url_for({:use_route => :family_connection, :controller => "connection"}, {:controller => 'connection/manage'})
    assert_equal "/connection", url
  end

  def test_action_left_off_when_id_is_recalled
    set.draw do |map|
      map.connect ':controller/:action/:id'
    end
    assert_equal '/books', url_for(
      {:controller => 'books', :action => 'index'},
      {:controller => 'books', :action => 'show', :id => '10'}
    )
  end

  def test_query_params_will_be_shown_when_recalled
    set.draw do |map|
      map.connect 'show_weblog/:parameter', :controller => 'weblog', :action => 'show'
      map.connect ':controller/:action/:id'
    end
    assert_equal '/weblog/edit?parameter=1', url_for(
      {:action => 'edit', :parameter => 1},
      {:controller => 'weblog', :action => 'show', :parameter => 1}
    )
  end

  def test_format_is_not_inherit
    set.draw do |map|
      map.connect '/posts.:format', :controller => 'posts'
    end

    assert_equal '/posts', url_for(
      {:controller => 'posts'},
      {:controller => 'posts', :action => 'index', :format => 'xml'}
    )

    assert_equal '/posts.xml', url_for(
      {:controller => 'posts', :format => 'xml'},
      {:controller => 'posts', :action => 'index', :format => 'xml'}
    )
  end

  def test_expiry_determination_should_consider_values_with_to_param
    set.draw { |map| map.connect 'projects/:project_id/:controller/:action' }
    assert_equal '/projects/1/weblog/show', url_for(
      {:action => 'show', :project_id => 1},
      {:controller => 'weblog', :action => 'show', :project_id => '1'})
  end

  def test_named_route_in_nested_resource
    set.draw do |map|
      map.resources :projects do |project|
        project.milestones 'milestones', :controller => 'milestones', :action => 'index'
      end
    end

    params = recognize_path("/projects/1/milestones", :method => :get)
    assert_equal("milestones", params[:controller])
    assert_equal("index", params[:action])
  end

  def test_setting_root_in_namespace_using_symbol
    assert_nothing_raised do
      set.draw do |map|
        map.namespace :admin do |admin|
          admin.root :controller => 'home'
        end
      end
    end
  end

  def test_setting_root_in_namespace_using_string
    assert_nothing_raised do
      set.draw do |map|
        map.namespace 'admin' do |admin|
          admin.root :controller => 'home'
        end
      end
    end
  end

  def test_route_requirements_with_unsupported_regexp_options_must_error
    assert_raise ArgumentError do
      set.draw do |map|
        map.connect 'page/:name', :controller => 'pages',
          :action => 'show',
          :requirements => {:name => /(david|jamis)/m}
      end
    end
  end

  def test_route_requirements_with_supported_options_must_not_error
    assert_nothing_raised do
      set.draw do |map|
        map.connect 'page/:name', :controller => 'pages',
          :action => 'show',
          :requirements => {:name => /(david|jamis)/i}
      end
    end
    assert_nothing_raised do
      set.draw do |map|
        map.connect 'page/:name', :controller => 'pages',
          :action => 'show',
          :requirements => {:name => / # Desperately overcommented regexp
                                      ( #Either
                                       david #The Creator
                                      | #Or
                                        jamis #The Deployer
                                      )/x}
      end
    end
  end

  def test_route_requirement_recognize_with_ignore_case
    set.draw do |map|
      map.connect 'page/:name', :controller => 'pages',
        :action => 'show',
        :requirements => {:name => /(david|jamis)/i}
    end
    assert_equal({:controller => 'pages', :action => 'show', :name => 'jamis'}, recognize_path('/page/jamis'))
    assert_raise ActionController::RoutingError do
      recognize_path('/page/davidjamis')
    end
    assert_equal({:controller => 'pages', :action => 'show', :name => 'DAVID'}, recognize_path('/page/DAVID'))
  end

  def test_route_requirement_generate_with_ignore_case
    set.draw do |map|
      map.connect 'page/:name', :controller => 'pages',
        :action => 'show',
        :requirements => {:name => /(david|jamis)/i}
    end

    url = url_for({:controller => 'pages', :action => 'show', :name => 'david'})
    assert_equal "/page/david", url
    assert_raise ActionController::RoutingError do
      url = url_for({:controller => 'pages', :action => 'show', :name => 'davidjamis'})
    end
    url = url_for({:controller => 'pages', :action => 'show', :name => 'JAMIS'})
    assert_equal "/page/JAMIS", url
  end

  def test_route_requirement_recognize_with_extended_syntax
    set.draw do |map|
      map.connect 'page/:name', :controller => 'pages',
        :action => 'show',
        :requirements => {:name => / # Desperately overcommented regexp
                                    ( #Either
                                     david #The Creator
                                    | #Or
                                      jamis #The Deployer
                                    )/x}
    end
    assert_equal({:controller => 'pages', :action => 'show', :name => 'jamis'}, recognize_path('/page/jamis'))
    assert_equal({:controller => 'pages', :action => 'show', :name => 'david'}, recognize_path('/page/david'))
    assert_raise ActionController::RoutingError do
      recognize_path('/page/david #The Creator')
    end
    assert_raise ActionController::RoutingError do
      recognize_path('/page/David')
    end
  end

  def test_route_requirement_generate_with_extended_syntax
    set.draw do |map|
      map.connect 'page/:name', :controller => 'pages',
        :action => 'show',
        :requirements => {:name => / # Desperately overcommented regexp
                                    ( #Either
                                     david #The Creator
                                    | #Or
                                      jamis #The Deployer
                                    )/x}
    end

    url = url_for({:controller => 'pages', :action => 'show', :name => 'david'})
    assert_equal "/page/david", url
    assert_raise ActionController::RoutingError do
      url = url_for({:controller => 'pages', :action => 'show', :name => 'davidjamis'})
    end
    assert_raise ActionController::RoutingError do
      url = url_for({:controller => 'pages', :action => 'show', :name => 'JAMIS'})
    end
  end

  def test_route_requirement_generate_with_xi_modifiers
    set.draw do |map|
      map.connect 'page/:name', :controller => 'pages',
        :action => 'show',
        :requirements => {:name => / # Desperately overcommented regexp
                                    ( #Either
                                     david #The Creator
                                    | #Or
                                      jamis #The Deployer
                                    )/xi}
    end

    url = url_for({:controller => 'pages', :action => 'show', :name => 'JAMIS'})
    assert_equal "/page/JAMIS", url
  end

  def test_route_requirement_recognize_with_xi_modifiers
    set.draw do |map|
      map.connect 'page/:name', :controller => 'pages',
        :action => 'show',
        :requirements => {:name => / # Desperately overcommented regexp
                                    ( #Either
                                     david #The Creator
                                    | #Or
                                      jamis #The Deployer
                                    )/xi}
    end
    assert_equal({:controller => 'pages', :action => 'show', :name => 'JAMIS'}, recognize_path('/page/JAMIS'))
  end

  def test_routes_with_symbols
    set.draw do |map|
      map.connect 'unnamed', :controller => :pages, :action => :show, :name => :as_symbol
      map.named   'named',   :controller => :pages, :action => :show, :name => :as_symbol
    end
    assert_equal({:controller => 'pages', :action => 'show', :name => :as_symbol}, recognize_path('/unnamed'))
    assert_equal({:controller => 'pages', :action => 'show', :name => :as_symbol}, recognize_path('/named'))
  end

  def test_regexp_chunk_should_add_question_mark_for_optionals
    set.draw do |map|
      map.connect '/', :controller => 'foo'
      map.connect '/hello', :controller => 'bar'
    end

    assert_equal '/', url_for(:controller => 'foo')
    assert_equal '/hello', url_for(:controller => 'bar')

    assert_equal({:controller => "foo", :action => "index"}, recognize_path('/'))
    assert_equal({:controller => "bar", :action => "index"}, recognize_path('/hello'))
  end

  def test_assign_route_options_with_anchor_chars
    set.draw do |map|
      map.connect '/cars/:action/:person/:car/', :controller => 'cars'
    end

    assert_equal '/cars/buy/1/2', url_for(:controller => 'cars', :action => 'buy', :person => '1', :car => '2')

    assert_equal({:controller => "cars", :action => "buy", :person => "1", :car => "2"}, recognize_path('/cars/buy/1/2'))
  end

  def test_segmentation_of_dot_path
    set.draw do |map|
      map.connect '/books/:action.rss', :controller => 'books'
    end

    assert_equal '/books/list.rss', url_for(:controller => 'books', :action => 'list')

    assert_equal({:controller => "books", :action => "list"}, recognize_path('/books/list.rss'))
  end

  def test_segmentation_of_dynamic_dot_path
    set.draw do |map|
      map.connect '/books/:action.:format', :controller => 'books'
    end

    assert_equal '/books/list.rss', url_for(:controller => 'books', :action => 'list', :format => 'rss')
    assert_equal '/books/list.xml', url_for(:controller => 'books', :action => 'list', :format => 'xml')
    assert_equal '/books/list', url_for(:controller => 'books', :action => 'list')
    assert_equal '/books', url_for(:controller => 'books', :action => 'index')

    assert_equal({:controller => "books", :action => "list", :format => "rss"}, recognize_path('/books/list.rss'))
    assert_equal({:controller => "books", :action => "list", :format => "xml"}, recognize_path('/books/list.xml'))
    assert_equal({:controller => "books", :action => "list"}, recognize_path('/books/list'))
    assert_equal({:controller => "books", :action => "index"}, recognize_path('/books'))
  end

  def test_slashes_are_implied
    ['/:controller/:action/:id/', '/:controller/:action/:id',
      ':controller/:action/:id', '/:controller/:action/:id/'
    ].each do |path|
      @set = nil
      set.draw { |map| map.connect(path) }

      assert_equal '/content', url_for(:controller => 'content', :action => 'index')
      assert_equal '/content/list', url_for(:controller => 'content', :action => 'list')
      assert_equal '/content/show/1', url_for(:controller => 'content', :action => 'show', :id => '1')

      assert_equal({:controller => "content", :action => "index"}, recognize_path('/content'))
      assert_equal({:controller => "content", :action => "index"}, recognize_path('/content/index'))
      assert_equal({:controller => "content", :action => "list"}, recognize_path('/content/list'))
      assert_equal({:controller => "content", :action => "show", :id => "1"}, recognize_path('/content/show/1'))
    end
  end

  def test_default_route_recognition
    expected = {:controller => 'pages', :action => 'show', :id => '10'}
    assert_equal expected, default_recognize_path('/pages/show/10')
    assert_equal expected, default_recognize_path('/pages/show/10/')

    expected[:id] = 'jamis'
    assert_equal expected, default_recognize_path('/pages/show/jamis/')

    expected.delete :id
    assert_equal expected, default_recognize_path('/pages/show')
    assert_equal expected, default_recognize_path('/pages/show/')

    expected[:action] = 'index'
    assert_equal expected, default_recognize_path('/pages/')
    assert_equal expected, default_recognize_path('/pages')

    assert_raise(ActionController::RoutingError) { default_recognize_path('/') }
    assert_raise(ActionController::RoutingError) { default_recognize_path('/pages/how/goood/it/is/to/be/free') }
  end

  def test_default_route_should_omit_default_action
    assert_equal '/accounts', default_url_for({:controller => 'accounts', :action => 'index'})
  end

  def test_default_route_should_include_default_action_when_id_present
    assert_equal '/accounts/index/20', default_url_for({:controller => 'accounts', :action => 'index', :id => '20'})
  end

  def test_default_route_should_work_with_action_but_no_id
    assert_equal '/accounts/list_all', default_url_for({:controller => 'accounts', :action => 'list_all'})
  end

  def test_default_route_should_uri_escape_pluses
    expected = { :controller => 'pages', :action => 'show', :id => 'hello world' }
    assert_equal expected, default_recognize_path('/pages/show/hello%20world')
    assert_equal '/pages/show/hello%20world', default_url_for(expected, expected)

    expected[:id] = 'hello+world'
    assert_equal expected, default_recognize_path('/pages/show/hello+world')
    assert_equal expected, default_recognize_path('/pages/show/hello%2Bworld')
    assert_equal '/pages/show/hello+world', default_url_for(expected, expected)
  end

  def test_build_empty_query_string
    assert_uri_equal '/foo', default_url_for({:controller => 'foo'})
  end

  def test_build_query_string_with_nil_value
    assert_uri_equal '/foo', default_url_for({:controller => 'foo', :x => nil})
  end

  def test_simple_build_query_string
    assert_uri_equal '/foo?x=1&y=2', default_url_for({:controller => 'foo', :x => '1', :y => '2'})
  end

  def test_convert_ints_build_query_string
    assert_uri_equal '/foo?x=1&y=2', default_url_for({:controller => 'foo', :x => 1, :y => 2})
  end

  def test_escape_spaces_build_query_string
    assert_uri_equal '/foo?x=hello+world&y=goodbye+world', default_url_for({:controller => 'foo', :x => 'hello world', :y => 'goodbye world'})
  end

  def test_expand_array_build_query_string
    assert_uri_equal '/foo?x%5B%5D=1&x%5B%5D=2', default_url_for({:controller => 'foo', :x => [1, 2]})
  end

  def test_escape_spaces_build_query_string_selected_keys
    assert_uri_equal '/foo?x=hello+world', default_url_for({:controller => 'foo', :x => 'hello world'})
  end

  def test_generate_with_default_params
    set.draw do |map|
      map.connect 'dummy/page/:page', :controller => 'dummy'
      map.connect 'dummy/dots/page.:page', :controller => 'dummy', :action => 'dots'
      map.connect 'ibocorp/:page', :controller => 'ibocorp',
                                   :requirements => { :page => /\d+/ },
                                   :defaults => { :page => 1 }

      map.connect ':controller/:action/:id'
    end

    assert_equal '/ibocorp', url_for({:controller => 'ibocorp', :page => 1})
  end

  def test_generate_with_optional_params_recalls_last_request
    set.draw do |map|
      map.connect "blog/", :controller => "blog", :action => "index"

      map.connect "blog/:year/:month/:day",
                  :controller => "blog",
                  :action => "show_date",
                  :requirements => { :year => /(19|20)\d\d/, :month => /[01]?\d/, :day => /[0-3]?\d/ },
                  :day => nil, :month => nil

      map.connect "blog/show/:id", :controller => "blog", :action => "show", :id => /\d+/
      map.connect "blog/:controller/:action/:id"
      map.connect "*anything", :controller => "blog", :action => "unknown_request"
    end

    assert_equal({:controller => "blog", :action => "index"}, recognize_path("/blog"))
    assert_equal({:controller => "blog", :action => "show", :id => "123"}, recognize_path("/blog/show/123"))
    assert_equal({:controller => "blog", :action => "show_date", :year => "2004"}, recognize_path("/blog/2004"))
    assert_equal({:controller => "blog", :action => "show_date", :year => "2004", :month => "12"}, recognize_path("/blog/2004/12"))
    assert_equal({:controller => "blog", :action => "show_date", :year => "2004", :month => "12", :day => "25"}, recognize_path("/blog/2004/12/25"))
    assert_equal({:controller => "articles", :action => "edit", :id => "123"}, recognize_path("/blog/articles/edit/123"))
    assert_equal({:controller => "articles", :action => "show_stats"}, recognize_path("/blog/articles/show_stats"))
    assert_equal({:controller => "blog", :action => "unknown_request", :anything => ["blog", "wibble"]}, recognize_path("/blog/wibble"))
    assert_equal({:controller => "blog", :action => "unknown_request", :anything => ["junk"]}, recognize_path("/junk"))

    last_request = recognize_path("/blog/2006/07/28").freeze
    assert_equal({:controller => "blog",  :action => "show_date", :year => "2006", :month => "07", :day => "28"}, last_request)
    assert_equal("/blog/2006/07/25", url_for({:day => 25}, last_request))
    assert_equal("/blog/2005", url_for({:year => 2005}, last_request))
    assert_equal("/blog/show/123", url_for({:action => "show" , :id => 123}, last_request))
    assert_equal("/blog/2006", url_for({:year => 2006}, last_request))
    assert_equal("/blog/2006", url_for({:year => 2006, :month => nil}, last_request))
  end

  private
    def assert_uri_equal(expected, actual)
      assert_equal(sort_query_string_params(expected), sort_query_string_params(actual))
    end

    def sort_query_string_params(uri)
      path, qs = uri.split('?')
      qs = qs.split('&').sort.join('&') if qs
      qs ? "#{path}?#{qs}" : path
    end
end
