require 'test_helper'
require 'cgi'

class LegacyRouteSetTest < ActiveSupport::TestCase
  include RoutingTestHelpers

  def test_default_setup
    set.draw {|map| map.connect ':controller/:action/:id' }

    assert_equal({:controller => "content", :action => 'index'}, recognize_path("/content"))
    assert_equal({:controller => "content", :action => 'list'}, recognize_path("/content/list"))
    assert_equal({:controller => "content", :action => 'show', :id => '10'}, recognize_path("/content/show/10"))
    assert_equal({:controller => "admin/user", :action => 'show', :id => '10'}, recognize_path("/admin/user/show/10"))

    assert_equal '/admin/user/show/10', url_for(:controller => 'admin/user', :action => 'show', :id => 10)
    assert_equal '/admin/user/show', url_for({:action => 'show'}, {:controller => 'admin/user', :action => 'list', :id => '10'})
    assert_equal '/admin/user/list/10', url_for({}, {:controller => 'admin/user', :action => 'list', :id => '10'})
    assert_equal '/admin/stuff', url_for({:controller => 'stuff'}, {:controller => 'admin/user', :action => 'list', :id => '10'})
    assert_equal '/stuff', url_for({:controller => '/stuff'}, {:controller => 'admin/user', :action => 'list', :id => '10'})
  end

  def test_ignores_leading_slash
    set.draw {|map| map.connect '/:controller/:action/:id'}

    assert_equal({:controller => "content", :action => 'index'}, recognize_path("/content"))
    assert_equal({:controller => "content", :action => 'list'}, recognize_path("/content/list"))
    assert_equal({:controller => "content", :action => 'show', :id => '10'}, recognize_path("/content/show/10"))
    assert_equal({:controller => "admin/user", :action => 'show', :id => '10'}, recognize_path("/admin/user/show/10"))

    assert_equal '/admin/user/show/10', url_for(:controller => 'admin/user', :action => 'show', :id => 10)
    assert_equal '/admin/user/show', url_for({:action => 'show'}, {:controller => 'admin/user', :action => 'list', :id => '10'})
    assert_equal '/admin/user/list/10', url_for({}, {:controller => 'admin/user', :action => 'list', :id => '10'})
    assert_equal '/admin/stuff', url_for({:controller => 'stuff'}, {:controller => 'admin/user', :action => 'list', :id => '10'})
    assert_equal '/stuff', url_for({:controller => '/stuff'}, {:controller => 'admin/user', :action => 'list', :id => '10'})
  end

  def test_time_recognition
    # We create many routes to make situation more realistic
    set.draw { |map|
      map.frontpage '', :controller => 'search', :action => 'new'
      map.resources :videos do |video|
        video.resources :comments
        video.resource  :file,      :controller => 'video_file'
        video.resource  :share,     :controller => 'video_shares'
        video.resource  :abuse,     :controller => 'video_abuses'
      end
      map.resources :abuses, :controller => 'video_abuses'
      map.resources :video_uploads
      map.resources :video_visits

      map.resources :users do |user|
        user.resource  :settings
        user.resources :videos
      end
      map.resources :channels do |channel|
        channel.resources :videos, :controller => 'channel_videos'
      end
      map.resource  :session
      map.resource  :lost_password
      map.search    'search', :controller => 'search'
      map.resources :pages
      map.connect ':controller/:action/:id'
    }
  end

  def test_route_with_colon_first
    set.draw do |map|
      map.connect '/:controller/:action/:id', :action => 'index', :id => nil
      map.connect ':url', :controller => 'tiny_url', :action => 'translate'
    end
  end

  def test_route_with_regexp_for_controller
    set.draw do |map|
      map.connect ':controller/:admintoken/:action/:id', :controller => /admin\/.+/
      map.connect ':controller/:action/:id'
    end
    assert_equal({:controller => "admin/user", :admintoken => "foo", :action => "index"},
        recognize_path("/admin/user/foo"))
    assert_equal({:controller => "content", :action => "foo"}, recognize_path("/content/foo"))
    assert_equal '/admin/user/foo', url_for(:controller => "admin/user", :admintoken => "foo", :action => "index")
    assert_equal '/content/foo', url_for(:controller => "content", :action => "foo")
  end

  def test_route_with_regexp_and_captures_for_controller
    set.draw do |map|
      map.connect ':controller/:action/:id', :controller => /admin\/(accounts|users)/
    end
    assert_equal({:controller => "admin/accounts", :action => "index"}, recognize_path("/admin/accounts"))
    assert_equal({:controller => "admin/users", :action => "index"}, recognize_path("/admin/users"))
    assert_raise(ActionController::RoutingError) { recognize_path("/admin/products") }
  end

  def test_route_with_regexp_and_dot
    set.draw do |map|
      map.connect ':controller/:action/:file',
                        :controller => /admin|user/,
                        :action => /upload|download/,
                        :defaults => {:file => nil},
                        :requirements => {:file => %r{[^/]+(\.[^/]+)?}}
    end
    # Without a file extension
    assert_equal '/user/download/file',
      url_for(:controller => "user", :action => "download", :file => "file")
    assert_equal(
      {:controller => "user", :action => "download", :file => "file"},
      recognize_path("/user/download/file"))

    # Now, let's try a file with an extension, really a dot (.)
    assert_equal '/user/download/file.jpg',
      url_for(
        :controller => "user", :action => "download", :file => "file.jpg")
    assert_equal(
      {:controller => "user", :action => "download", :file => "file.jpg"},
      recognize_path("/user/download/file.jpg"))
  end

  def test_basic_named_route
    set.draw do |map|
      map.home '', :controller => 'content', :action => 'list'
    end
    x = setup_for_named_route
    assert_equal("http://test.host/",
                 x.send(:home_url))
  end

  def test_named_route_with_option
    set.draw do |map|
      map.page 'page/:title', :controller => 'content', :action => 'show_page'
    end
    x = setup_for_named_route
    assert_equal("http://test.host/page/new%20stuff",
                 x.send(:page_url, :title => 'new stuff'))
  end

  def test_named_route_with_default
    set.draw do |map|
      map.page 'page/:title', :controller => 'content', :action => 'show_page', :title => 'AboutPage'
    end
    x = setup_for_named_route
    assert_equal("http://test.host/page/AboutRails",
                 x.send(:page_url, :title => "AboutRails"))

  end

  def test_named_route_with_name_prefix
    set.draw do |map|
      map.page 'page', :controller => 'content', :action => 'show_page', :name_prefix => 'my_'
    end
    x = setup_for_named_route
    assert_equal("http://test.host/page",
                 x.send(:my_page_url))
  end

  def test_named_route_with_path_prefix
    set.draw do |map|
      map.page 'page', :controller => 'content', :action => 'show_page', :path_prefix => 'my'
    end
    x = setup_for_named_route
    assert_equal("http://test.host/my/page",
                 x.send(:page_url))
  end

  def test_named_route_with_blank_path_prefix
    set.draw do |map|
      map.page 'page', :controller => 'content', :action => 'show_page', :path_prefix => ''
    end
    x = setup_for_named_route
    assert_equal("http://test.host/page",
                 x.send(:page_url))
  end

  def test_named_route_with_nested_controller
    set.draw do |map|
      map.users 'admin/user', :controller => 'admin/user', :action => 'index'
    end
    x = setup_for_named_route
    assert_equal("http://test.host/admin/user",
                 x.send(:users_url))
  end

  def test_optimised_named_route_with_host
    set.draw do |map|
      map.pages 'pages', :controller => 'content', :action => 'show_page', :host => 'foo.com'
    end
    x = setup_for_named_route
    x.expects(:url_for).with(:host => 'foo.com', :only_path => false, :controller => 'content', :action => 'show_page', :use_route => :pages).once
    x.send(:pages_url)
  end

  def setup_for_named_route
    MockController.build(set.url_helpers).new
  end

  def test_named_route_without_hash
    set.draw do |map|
      map.normal ':controller/:action/:id'
    end
  end

  def test_named_route_root
    set.draw do |map|
      map.root :controller => "hello"
    end
    x = setup_for_named_route
    assert_equal("http://test.host/", x.send(:root_url))
    assert_equal("/", x.send(:root_path))
  end

  def test_named_route_with_regexps
    set.draw do |map|
      map.article 'page/:year/:month/:day/:title', :controller => 'page', :action => 'show',
        :year => /\d+/, :month => /\d+/, :day => /\d+/
      map.connect ':controller/:action/:id'
    end
    x = setup_for_named_route
    # assert_equal(
    #   {:controller => 'page', :action => 'show', :title => 'hi', :use_route => :article, :only_path => false},
    #   x.send(:article_url, :title => 'hi')
    # )
    assert_equal(
      "http://test.host/page/2005/6/10/hi",
      x.send(:article_url, :title => 'hi', :day => 10, :year => 2005, :month => 6)
    )
  end

  def test_changing_controller
    set.draw {|map| map.connect ':controller/:action/:id' }

    assert_equal '/admin/stuff/show/10', url_for(
      {:controller => 'stuff', :action => 'show', :id => 10},
      {:controller => 'admin/user', :action => 'index'}
    )
  end

  def test_paths_escaped
    set.draw do |map|
      map.path 'file/*path', :controller => 'content', :action => 'show_file'
      map.connect ':controller/:action/:id'
    end

    # No + to space in URI escaping, only for query params.
    results = recognize_path "/file/hello+world/how+are+you%3F"
    assert results, "Recognition should have succeeded"
    assert_equal ['hello+world', 'how+are+you?'], results[:path]

    # Use %20 for space instead.
    results = recognize_path "/file/hello%20world/how%20are%20you%3F"
    assert results, "Recognition should have succeeded"
    assert_equal ['hello world', 'how are you?'], results[:path]
  end

  def test_paths_slashes_unescaped_with_ordered_parameters
    set.draw do |map|
      map.path '/file/*path', :controller => 'content'
    end

    # No / to %2F in URI, only for query params.
    x = setup_for_named_route
    assert_equal("/file/hello/world", x.send(:path_path, ['hello', 'world']))
  end

  def test_non_controllers_cannot_be_matched
    set.draw do |map|
      map.connect ':controller/:action/:id'
    end
    assert_raise(ActionController::RoutingError) { recognize_path("/not_a/show/10") }
  end

  def test_paths_do_not_accept_defaults
    assert_raise(ActionController::RoutingError) do
      set.draw do |map|
        map.path 'file/*path', :controller => 'content', :action => 'show_file', :path => %w(fake default)
        map.connect ':controller/:action/:id'
      end
    end

    set.draw do |map|
      map.path 'file/*path', :controller => 'content', :action => 'show_file', :path => []
      map.connect ':controller/:action/:id'
    end
  end

  def test_should_list_options_diff_when_routing_requirements_dont_match
    set.draw do |map|
      map.post 'post/:id', :controller=> 'post', :action=> 'show', :requirements => {:id => /\d+/}
    end
    assert_raise(ActionController::RoutingError) { url_for(:controller => 'post', :action => 'show', :bad_param => "foo", :use_route => "post") }
  end

  def test_dynamic_path_allowed
    set.draw do |map|
      map.connect '*path', :controller => 'content', :action => 'show_file'
    end

    assert_equal '/pages/boo', url_for(:controller => 'content', :action => 'show_file', :path => %w(pages boo))
  end

  def test_dynamic_recall_paths_allowed
    set.draw do |map|
      map.connect '*path', :controller => 'content', :action => 'show_file'
    end

    assert_equal '/pages/boo', url_for({}, :controller => 'content', :action => 'show_file', :path => %w(pages boo))
  end

  def test_backwards
    set.draw do |map|
      map.connect 'page/:id/:action', :controller => 'pages', :action => 'show'
      map.connect ':controller/:action/:id'
    end

    assert_equal '/page/20', url_for({:id => 20}, {:controller => 'pages', :action => 'show'})
    assert_equal '/page/20', url_for(:controller => 'pages', :id => 20, :action => 'show')
    assert_equal '/pages/boo', url_for(:controller => 'pages', :action => 'boo')
  end

  def test_route_with_fixnum_default
    set.draw do |map|
      map.connect 'page/:id', :controller => 'content', :action => 'show_page', :id => 1
      map.connect ':controller/:action/:id'
    end

    assert_equal '/page', url_for(:controller => 'content', :action => 'show_page')
    assert_equal '/page', url_for(:controller => 'content', :action => 'show_page', :id => 1)
    assert_equal '/page', url_for(:controller => 'content', :action => 'show_page', :id => '1')
    assert_equal '/page/10', url_for(:controller => 'content', :action => 'show_page', :id => 10)

    assert_equal({:controller => "content", :action => 'show_page', :id => '1'}, recognize_path("/page"))
    assert_equal({:controller => "content", :action => 'show_page', :id => '1'}, recognize_path("/page/1"))
    assert_equal({:controller => "content", :action => 'show_page', :id => '10'}, recognize_path("/page/10"))
  end

  # For newer revision
  def test_route_with_text_default
    set.draw do |map|
      map.connect 'page/:id', :controller => 'content', :action => 'show_page', :id => 1
      map.connect ':controller/:action/:id'
    end

    assert_equal '/page/foo', url_for(:controller => 'content', :action => 'show_page', :id => 'foo')
    assert_equal({:controller => "content", :action => 'show_page', :id => 'foo'}, recognize_path("/page/foo"))

    token = "\321\202\320\265\320\272\321\201\321\202" # 'text' in russian
    token.force_encoding(Encoding::BINARY) if token.respond_to?(:force_encoding)
    escaped_token = CGI::escape(token)

    assert_equal '/page/' + escaped_token, url_for(:controller => 'content', :action => 'show_page', :id => token)
    assert_equal({:controller => "content", :action => 'show_page', :id => token}, recognize_path("/page/#{escaped_token}"))
  end

  def test_action_expiry
    set.draw {|map| map.connect ':controller/:action/:id' }
    assert_equal '/content', url_for({:controller => 'content'}, {:controller => 'content', :action => 'show'})
  end

  def test_requirement_should_prevent_optional_id
    set.draw do |map|
      map.post 'post/:id', :controller=> 'post', :action=> 'show', :requirements => {:id => /\d+/}
    end

    assert_equal '/post/10', url_for(:controller => 'post', :action => 'show', :id => 10)

    assert_raise ActionController::RoutingError do
      url_for(:controller => 'post', :action => 'show')
    end
  end

  def test_both_requirement_and_optional
    set.draw do |map|
      map.blog('test/:year', :controller => 'post', :action => 'show',
        :defaults => { :year => nil },
        :requirements => { :year => /\d{4}/ }
      )
      map.connect ':controller/:action/:id'
    end

    assert_equal '/test', url_for(:controller => 'post', :action => 'show')
    assert_equal '/test', url_for(:controller => 'post', :action => 'show', :year => nil)

    x = setup_for_named_route
    assert_equal("http://test.host/test",
                 x.send(:blog_url))
  end

  def test_set_to_nil_forgets
    set.draw do |map|
      map.connect 'pages/:year/:month/:day', :controller => 'content', :action => 'list_pages', :month => nil, :day => nil
      map.connect ':controller/:action/:id'
    end

    assert_equal '/pages/2005',
      url_for(:controller => 'content', :action => 'list_pages', :year => 2005)
    assert_equal '/pages/2005/6',
      url_for(:controller => 'content', :action => 'list_pages', :year => 2005, :month => 6)
    assert_equal '/pages/2005/6/12',
      url_for(:controller => 'content', :action => 'list_pages', :year => 2005, :month => 6, :day => 12)

    assert_equal '/pages/2005/6/4',
      url_for({:day => 4}, {:controller => 'content', :action => 'list_pages', :year => '2005', :month => '6', :day => '12'})

    assert_equal '/pages/2005/6',
      url_for({:day => nil}, {:controller => 'content', :action => 'list_pages', :year => '2005', :month => '6', :day => '12'})

    assert_equal '/pages/2005',
      url_for({:day => nil, :month => nil}, {:controller => 'content', :action => 'list_pages', :year => '2005', :month => '6', :day => '12'})
  end

  def test_url_with_no_action_specified
    set.draw do |map|
      map.connect '', :controller => 'content'
      map.connect ':controller/:action/:id'
    end

    assert_equal '/', url_for(:controller => 'content', :action => 'index')
    assert_equal '/', url_for(:controller => 'content')
  end

  def test_named_url_with_no_action_specified
    set.draw do |map|
      map.home '', :controller => 'content'
      map.connect ':controller/:action/:id'
    end

    assert_equal '/', url_for(:controller => 'content', :action => 'index')
    assert_equal '/', url_for(:controller => 'content')

    x = setup_for_named_route
    assert_equal("http://test.host/",
                 x.send(:home_url))
  end

  def test_url_generated_when_forgetting_action
    [{:controller => 'content', :action => 'index'}, {:controller => 'content'}].each do |hash|
      set.draw do |map|
        map.home '', hash
        map.connect ':controller/:action/:id'
      end
      assert_equal '/', url_for({:action => nil}, {:controller => 'content', :action => 'hello'})
      assert_equal '/', url_for({:controller => 'content'})
      assert_equal '/content/hi', url_for({:controller => 'content', :action => 'hi'})
    end
  end

  def test_named_route_method
    set.draw do |map|
      map.categories 'categories', :controller => 'content', :action => 'categories'
      map.connect ':controller/:action/:id'
    end

    assert_equal '/categories', url_for(:controller => 'content', :action => 'categories')
    assert_equal '/content/hi', url_for({:controller => 'content', :action => 'hi'})
  end

  def test_named_routes_array
    test_named_route_method
    assert_equal [:categories], set.named_routes.names
  end

  def test_nil_defaults
    set.draw do |map|
      map.connect 'journal',
        :controller => 'content',
        :action => 'list_journal',
        :date => nil, :user_id => nil
      map.connect ':controller/:action/:id'
    end

    assert_equal '/journal', url_for(:controller => 'content', :action => 'list_journal', :date => nil, :user_id => nil)
  end

  def setup_request_method_routes_for(method)
    set.draw do |map|
      map.connect '/match', :controller => 'books', :action => 'get', :conditions => { :method => :get }
      map.connect '/match', :controller => 'books', :action => 'post', :conditions => { :method => :post }
      map.connect '/match', :controller => 'books', :action => 'put', :conditions => { :method => :put }
      map.connect '/match', :controller => 'books', :action => 'delete', :conditions => { :method => :delete }
    end
  end

  %w(GET POST PUT DELETE).each do |request_method|
    define_method("test_request_method_recognized_with_#{request_method}") do
      setup_request_method_routes_for(request_method)
      params = recognize_path("/match", :method => request_method)
      assert_equal request_method.downcase, params[:action]
    end
  end

  def test_recognize_array_of_methods
    set.draw do |map|
      map.connect '/match', :controller => 'books', :action => 'get_or_post', :conditions => { :method => [:get, :post] }
      map.connect '/match', :controller => 'books', :action => 'not_get_or_post'
    end

    params = recognize_path("/match", :method => :post)
    assert_equal 'get_or_post', params[:action]

    params = recognize_path("/match", :method => :put)
    assert_equal 'not_get_or_post', params[:action]
  end

  def test_subpath_recognized
    set.draw do |map|
      map.connect '/books/:id/edit', :controller => 'subpath_books', :action => 'edit'
      map.connect '/items/:id/:action', :controller => 'subpath_books'
      map.connect '/posts/new/:action', :controller => 'subpath_books'
      map.connect '/posts/:id', :controller => 'subpath_books', :action => "show"
    end

    hash = recognize_path "/books/17/edit"
    assert_not_nil hash
    assert_equal %w(subpath_books 17 edit), [hash[:controller], hash[:id], hash[:action]]

    hash = recognize_path "/items/3/complete"
    assert_not_nil hash
    assert_equal %w(subpath_books 3 complete), [hash[:controller], hash[:id], hash[:action]]

    hash = recognize_path "/posts/new/preview"
    assert_not_nil hash
    assert_equal %w(subpath_books preview), [hash[:controller], hash[:action]]

    hash = recognize_path "/posts/7"
    assert_not_nil hash
    assert_equal %w(subpath_books show 7), [hash[:controller], hash[:action], hash[:id]]
  end

  def test_subpath_generated
    set.draw do |map|
      map.connect '/books/:id/edit', :controller => 'subpath_books', :action => 'edit'
      map.connect '/items/:id/:action', :controller => 'subpath_books'
      map.connect '/posts/new/:action', :controller => 'subpath_books'
    end

    assert_equal "/books/7/edit", url_for(:controller => "subpath_books", :id => 7, :action => "edit")
    assert_equal "/items/15/complete", url_for(:controller => "subpath_books", :id => 15, :action => "complete")
    assert_equal "/posts/new/preview", url_for(:controller => "subpath_books", :action => "preview")
  end

  def test_failed_requirements_raises_exception_with_violated_requirements
    set.draw do |map|
      map.foo_with_requirement 'foos/:id', :controller=>'foos', :requirements=>{:id=>/\d+/}
    end

    x = setup_for_named_route
    assert_raise(ActionController::RoutingError) do
      x.send(:foo_with_requirement_url, "I am Against the requirements")
    end
  end

  def test_routes_changed_correctly_after_clear
    rs = ::ActionController::Routing::RouteSet.new
    set.draw do |map|
      map.connect 'ca', :controller => 'ca', :action => "aa"
      map.connect 'cb', :controller => 'cb', :action => "ab"
      map.connect 'cc', :controller => 'cc', :action => "ac"
      map.connect ':controller/:action/:id'
      map.connect ':controller/:action/:id.:format'
    end

    hash = recognize_path "/cc"

    assert_not_nil hash
    assert_equal %w(cc ac), [hash[:controller], hash[:action]]

    set.draw do |map|
      map.connect 'cb', :controller => 'cb', :action => "ab"
      map.connect 'cc', :controller => 'cc', :action => "ac"
      map.connect ':controller/:action/:id'
      map.connect ':controller/:action/:id.:format'
    end

    hash = recognize_path "/cc"

    assert_not_nil hash
    assert_equal %w(cc ac), [hash[:controller], hash[:action]]

  end
end
