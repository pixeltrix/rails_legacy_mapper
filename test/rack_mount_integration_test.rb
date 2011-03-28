require 'test_helper'

class RackMountIntegrationTest < ActiveSupport::TestCase
  include RoutingTestHelpers

  Model = Struct.new(:to_param)

  Mapping = lambda { |map|
    map.namespace :admin do |admin|
      admin.resources :users
    end

    map.namespace 'api' do |api|
      api.root :controller => 'users'
    end

    map.connect 'blog/:year/:month/:day',
                :controller => 'posts',
                :action => 'show_date',
                :requirements => { :year => /(19|20)\d\d/, :month => /[01]?\d/, :day => /[0-3]?\d/},
                :day => nil,
                :month => nil

    map.blog('archive/:year', :controller => 'archive', :action => 'index',
      :defaults => { :year => nil },
      :requirements => { :year => /\d{4}/ }
    )

    map.resources :people
    map.connect 'legacy/people', :controller => 'people', :action => 'index', :legacy => 'true'

    map.connect 'symbols', :controller => :symbols, :action => :show, :name => :as_symbol
    map.connect 'id_default/:id', :controller => 'foo', :action => 'id_default', :id => 1
    map.connect 'get_or_post', :controller => 'foo', :action => 'get_or_post', :conditions => { :method => [:get, :post] }
    map.connect 'optional/:optional', :controller => 'posts', :action => 'index'
    map.project 'projects/:project_id', :controller => 'project'
    map.connect 'clients', :controller => 'projects', :action => 'index'

    map.connect 'ignorecase/geocode/:postalcode', :controller => 'geocode',
                  :action => 'show', :postalcode => /hx\d\d-\d[a-z]{2}/i
    map.geocode 'extended/geocode/:postalcode', :controller => 'geocode',
                  :action => 'show',:requirements => {
                  :postalcode => /# Postcode format
                                  \d{5} #Prefix
                                  (-\d{4})? #Suffix
                                  /x
                  }

    map.connect '', :controller => 'news', :format => nil
    map.connect 'news.:format', :controller => 'news'

    map.connect 'comment/:id/:action', :controller => 'comments', :action => 'show'
    map.connect 'ws/:controller/:action/:id', :ws => true
    map.connect 'account/:action', :controller => :account, :action => :subscription
    map.connect 'pages/:page_id/:controller/:action/:id'
    map.connect ':controller/ping', :action => 'ping'
    map.connect ':controller/:action/:id'
  }

  def setup
    set.draw(&Mapping)
  end

  def test_add_route
    set.clear!

    assert_raise(ActionController::RoutingError) do
      set.draw do |map|
        map.path 'file/*path', :controller => 'content', :action => 'show_file', :path => %w(fake default)
        map.connect ':controller/:action/:id'
      end
    end
  end

  def test_recognize_path
    assert_equal({:controller => 'admin/users', :action => 'index'}, recognize_path('/admin/users', :method => :get))
    assert_equal({:controller => 'admin/users', :action => 'create'}, recognize_path('/admin/users', :method => :post))
    assert_equal({:controller => 'admin/users', :action => 'new'}, recognize_path('/admin/users/new', :method => :get))
    assert_equal({:controller => 'admin/users', :action => 'show', :id => '1'}, recognize_path('/admin/users/1', :method => :get))
    assert_equal({:controller => 'admin/users', :action => 'update', :id => '1'}, recognize_path('/admin/users/1', :method => :put))
    assert_equal({:controller => 'admin/users', :action => 'destroy', :id => '1'}, recognize_path('/admin/users/1', :method => :delete))
    assert_equal({:controller => 'admin/users', :action => 'edit', :id => '1'}, recognize_path('/admin/users/1/edit', :method => :get))

    assert_equal({:controller => 'admin/posts', :action => 'index'}, recognize_path('/admin/posts', :method => :get))
    assert_equal({:controller => 'admin/posts', :action => 'new'}, recognize_path('/admin/posts/new', :method => :get))

    assert_equal({:controller => 'api/users', :action => 'index'}, recognize_path('/api', :method => :get))
    assert_equal({:controller => 'api/users', :action => 'index'}, recognize_path('/api/', :method => :get))

    assert_equal({:controller => 'posts', :action => 'show_date', :year => '2009'}, recognize_path('/blog/2009', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show_date', :year => '2009', :month => '01'}, recognize_path('/blog/2009/01', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show_date', :year => '2009', :month => '01', :day => '01'}, recognize_path('/blog/2009/01/01', :method => :get))

    assert_equal({:controller => 'archive', :action => 'index', :year => '2010'}, recognize_path('/archive/2010'))
    assert_equal({:controller => 'archive', :action => 'index'}, recognize_path('/archive'))

    assert_equal({:controller => 'people', :action => 'index'}, recognize_path('/people', :method => :get))
    assert_equal({:controller => 'people', :action => 'index', :format => 'xml'}, recognize_path('/people.xml', :method => :get))
    assert_equal({:controller => 'people', :action => 'create'}, recognize_path('/people', :method => :post))
    assert_equal({:controller => 'people', :action => 'new'}, recognize_path('/people/new', :method => :get))
    assert_equal({:controller => 'people', :action => 'show', :id => '1'}, recognize_path('/people/1', :method => :get))
    assert_equal({:controller => 'people', :action => 'show', :id => '1', :format => 'xml'}, recognize_path('/people/1.xml', :method => :get))
    assert_equal({:controller => 'people', :action => 'update', :id => '1'}, recognize_path('/people/1', :method => :put))
    assert_equal({:controller => 'people', :action => 'destroy', :id => '1'}, recognize_path('/people/1', :method => :delete))
    assert_equal({:controller => 'people', :action => 'edit', :id => '1'}, recognize_path('/people/1/edit', :method => :get))
    assert_equal({:controller => 'people', :action => 'edit', :id => '1', :format => 'xml'}, recognize_path('/people/1/edit.xml', :method => :get))

    assert_equal({:controller => 'symbols', :action => 'show', :name => :as_symbol}, recognize_path('/symbols'))
    assert_equal({:controller => 'foo', :action => 'id_default', :id => '1'}, recognize_path('/id_default/1'))
    assert_equal({:controller => 'foo', :action => 'id_default', :id => '2'}, recognize_path('/id_default/2'))
    assert_equal({:controller => 'foo', :action => 'id_default', :id => '1'}, recognize_path('/id_default'))
    assert_equal({:controller => 'foo', :action => 'get_or_post'}, recognize_path('/get_or_post', :method => :get))
    assert_equal({:controller => 'foo', :action => 'get_or_post'}, recognize_path('/get_or_post', :method => :post))
    assert_raise(ActionController::ActionControllerError) { recognize_path('/get_or_post', :method => :put) }
    assert_raise(ActionController::ActionControllerError) { recognize_path('/get_or_post', :method => :delete) }

    assert_equal({:controller => 'posts', :action => 'index', :optional => 'bar'}, recognize_path('/optional/bar'))
    assert_raise(ActionController::ActionControllerError) { recognize_path('/optional') }

    assert_equal({:controller => 'posts', :action => 'show', :id => '1', :ws => true}, recognize_path('/ws/posts/show/1', :method => :get))
    assert_equal({:controller => 'posts', :action => 'list', :ws => true}, recognize_path('/ws/posts/list', :method => :get))
    assert_equal({:controller => 'posts', :action => 'index', :ws => true}, recognize_path('/ws/posts', :method => :get))

    assert_equal({:controller => 'account', :action => 'subscription'}, recognize_path('/account', :method => :get))
    assert_equal({:controller => 'account', :action => 'subscription'}, recognize_path('/account/subscription', :method => :get))
    assert_equal({:controller => 'account', :action => 'billing'}, recognize_path('/account/billing', :method => :get))

    assert_equal({:page_id => '1', :controller => 'notes', :action => 'index'}, recognize_path('/pages/1/notes', :method => :get))
    assert_equal({:page_id => '1', :controller => 'notes', :action => 'list'}, recognize_path('/pages/1/notes/list', :method => :get))
    assert_equal({:page_id => '1', :controller => 'notes', :action => 'show', :id => '2'}, recognize_path('/pages/1/notes/show/2', :method => :get))

    assert_equal({:controller => 'posts', :action => 'ping'}, recognize_path('/posts/ping', :method => :get))
    assert_equal({:controller => 'posts', :action => 'index'}, recognize_path('/posts', :method => :get))
    assert_equal({:controller => 'posts', :action => 'index'}, recognize_path('/posts/index', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show'}, recognize_path('/posts/show', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show', :id => '1'}, recognize_path('/posts/show/1', :method => :get))
    assert_equal({:controller => 'posts', :action => 'create'}, recognize_path('/posts/create', :method => :post))

    assert_equal({:controller => 'geocode', :action => 'show', :postalcode => 'hx12-1az'}, recognize_path('/ignorecase/geocode/hx12-1az'))
    assert_equal({:controller => 'geocode', :action => 'show', :postalcode => 'hx12-1AZ'}, recognize_path('/ignorecase/geocode/hx12-1AZ'))
    assert_equal({:controller => 'geocode', :action => 'show', :postalcode => '12345-1234'}, recognize_path('/extended/geocode/12345-1234'))
    assert_equal({:controller => 'geocode', :action => 'show', :postalcode => '12345'}, recognize_path('/extended/geocode/12345'))

    assert_equal({:controller => 'news', :action => 'index', :format => nil}, recognize_path('/', :method => :get))
    assert_equal({:controller => 'news', :action => 'index', :format => 'rss'}, recognize_path('/news.rss', :method => :get))

    assert_raise(ActionController::RoutingError) { recognize_path('/none', :method => :get) }
  end

  def test_generate
    assert_equal '/admin/users', url_for(:use_route => 'admin_users')
    assert_equal '/admin/users', url_for(:controller => 'admin/users')
    assert_equal '/admin/users', url_for(:controller => 'admin/users', :action => 'index')
    assert_equal '/admin/users', url_for({:action => 'index'}, {:controller => 'admin/users'})
    assert_equal '/admin/users', url_for({:controller => 'users', :action => 'index'}, {:controller => 'admin/accounts'})
    assert_equal '/people', url_for({:controller => '/people', :action => 'index'}, {:controller => 'admin/accounts'})

    assert_equal '/admin/posts', url_for({:controller => 'admin/posts'})
    assert_equal '/admin/posts/new', url_for({:controller => 'admin/posts', :action => 'new'})

    assert_equal '/blog/2009', url_for(:controller => 'posts', :action => 'show_date', :year => 2009)
    assert_equal '/blog/2009/1', url_for(:controller => 'posts', :action => 'show_date', :year => 2009, :month => 1)
    assert_equal '/blog/2009/1/1', url_for(:controller => 'posts', :action => 'show_date', :year => 2009, :month => 1, :day => 1)

    assert_equal '/archive/2010', url_for(:controller => 'archive', :action => 'index', :year => '2010')
    assert_equal '/archive', url_for(:controller => 'archive', :action => 'index')
    assert_equal '/archive?year=january', url_for(:controller => 'archive', :action => 'index', :year => 'january')

    assert_equal '/people', url_for(:use_route => 'people')
    assert_equal '/people', url_for(:use_route => 'people', :controller => 'people', :action => 'index')
    assert_equal '/people.xml', url_for(:use_route => 'people', :controller => 'people', :action => 'index', :format => 'xml')
    assert_equal '/people', url_for({:use_route => 'people', :controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'index'})
    assert_equal '/people', url_for(:controller => 'people')
    assert_equal '/people', url_for(:controller => 'people', :action => 'index')
    assert_equal '/people', url_for({:action => 'index'}, {:controller => 'people'})
    assert_equal '/people', url_for({:action => 'index'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people', url_for({:controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people', url_for({}, {:controller => 'people', :action => 'index'})
    assert_equal '/people/1', url_for({:controller => 'people', :action => 'show'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people/new', url_for(:use_route => 'new_person')
    assert_equal '/people/new', url_for(:controller => 'people', :action => 'new')
    assert_equal '/people/1', url_for(:use_route => 'person', :id => '1')
    assert_equal '/people/1', url_for(:controller => 'people', :action => 'show', :id => '1')
    assert_equal '/people/1.xml', url_for(:controller => 'people', :action => 'show', :id => '1', :format => 'xml')
    assert_equal '/people/1', url_for(:controller => 'people', :action => 'show', :id => 1)
    assert_equal '/people/1', url_for(:controller => 'people', :action => 'show', :id => Model.new('1'))
    assert_equal '/people/1', url_for({:action => 'show', :id => '1'}, {:controller => 'people', :action => 'index'})
    assert_equal '/people/1', url_for({:action => 'show', :id => 1}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people', url_for({:controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people/1', url_for({}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people/1', url_for({:controller => 'people', :action => 'show'}, {:controller => 'people', :action => 'index', :id => '1'})
    assert_equal '/people/1/edit', url_for(:controller => 'people', :action => 'edit', :id => '1')
    assert_equal '/people/1/edit.xml', url_for(:controller => 'people', :action => 'edit', :id => '1', :format => 'xml')
    assert_equal '/people/1/edit', url_for(:use_route => 'edit_person', :id => '1')
    assert_equal '/people/1?legacy=true', url_for(:controller => 'people', :action => 'show', :id => '1', :legacy => 'true')
    assert_equal '/people?legacy=true', url_for(:controller => 'people', :action => 'index', :legacy => 'true')

    assert_equal '/id_default/2', url_for(:controller => 'foo', :action => 'id_default', :id => '2')
    assert_equal '/id_default', url_for(:controller => 'foo', :action => 'id_default', :id => '1')
    assert_equal '/id_default', url_for(:controller => 'foo', :action => 'id_default', :id => 1)
    assert_equal '/id_default', url_for(:controller => 'foo', :action => 'id_default')
    assert_equal '/optional/bar', url_for(:controller => 'posts', :action => 'index', :optional => 'bar')
    assert_equal '/posts', url_for(:controller => 'posts', :action => 'index')

    assert_equal '/project', url_for({:controller => 'project', :action => 'index'})
    assert_equal '/projects/1', url_for({:controller => 'project', :action => 'index', :project_id => '1'})
    assert_equal '/projects/1', url_for({:controller => 'project', :action => 'index'}, {:project_id => '1'})
    assert_raise(ActionController::RoutingError) { url_for({:use_route => 'project', :controller => 'project', :action => 'index'}) }
    assert_equal '/projects/1', url_for({:use_route => 'project', :controller => 'project', :action => 'index', :project_id => '1'})
    assert_equal '/projects/1', url_for({:use_route => 'project', :controller => 'project', :action => 'index'}, {:project_id => '1'})

    assert_equal '/clients', url_for(:controller => 'projects', :action => 'index')
    assert_equal '/clients?project_id=1', url_for(:controller => 'projects', :action => 'index', :project_id => '1')
    assert_equal '/clients', url_for({:controller => 'projects', :action => 'index'}, {:project_id => '1'})
    assert_equal '/clients', url_for({:action => 'index'}, {:controller => 'projects', :action => 'index', :project_id => '1'})

    assert_equal '/comment/20', url_for({:id => 20}, {:controller => 'comments', :action => 'show'})
    assert_equal '/comment/20', url_for(:controller => 'comments', :id => 20, :action => 'show')
    assert_equal '/comments/boo', url_for(:controller => 'comments', :action => 'boo')

    assert_equal '/ws/posts/show/1', url_for(:controller => 'posts', :action => 'show', :id => '1', :ws => true)
    assert_equal '/ws/posts', url_for(:controller => 'posts', :action => 'index', :ws => true)

    assert_equal '/account', url_for(:controller => 'account', :action => 'subscription')
    assert_equal '/account/billing', url_for(:controller => 'account', :action => 'billing')

    assert_equal '/pages/1/notes/show/1', url_for(:page_id => '1', :controller => 'notes', :action => 'show', :id => '1')
    assert_equal '/pages/1/notes/list', url_for(:page_id => '1', :controller => 'notes', :action => 'list')
    assert_equal '/pages/1/notes', url_for(:page_id => '1', :controller => 'notes', :action => 'index')
    assert_equal '/pages/1/notes', url_for(:page_id => '1', :controller => 'notes')
    assert_equal '/notes', url_for(:page_id => nil, :controller => 'notes')
    assert_equal '/notes', url_for(:controller => 'notes')
    assert_equal '/notes/print', url_for(:controller => 'notes', :action => 'print')
    assert_equal '/notes/print', url_for({}, {:controller => 'notes', :action => 'print'})

    assert_equal '/notes/index/1', url_for({:controller => 'notes'}, {:controller => 'notes', :id => '1'})
    assert_equal '/notes/index/1', url_for({:controller => 'notes'}, {:controller => 'notes', :id => '1', :foo => 'bar'})
    assert_equal '/notes/index/1', url_for({:controller => 'notes'}, {:controller => 'notes', :id => '1'})
    assert_equal '/notes/index/1', url_for({:action => 'index'}, {:controller => 'notes', :id => '1'})
    assert_equal '/notes/index/1', url_for({}, {:controller => 'notes', :id => '1'})
    assert_equal '/notes/show/1', url_for({}, {:controller => 'notes', :action => 'show', :id => '1'})
    assert_equal '/notes/index/1', url_for({:controller => 'notes', :id => '1'}, {:foo => 'bar'})
    assert_equal '/posts', url_for({:controller => 'posts'}, {:controller => 'notes', :action => 'show', :id => '1'})
    assert_equal '/notes/list', url_for({:action => 'list'}, {:controller => 'notes', :action => 'show', :id => '1'})

    assert_equal '/posts/ping', url_for(:controller => 'posts', :action => 'ping')
    assert_equal '/posts/show/1', url_for(:controller => 'posts', :action => 'show', :id => '1')
    assert_equal '/posts', url_for(:controller => 'posts')
    assert_equal '/posts', url_for(:controller => 'posts', :action => 'index')
    assert_equal '/posts', url_for({:controller => 'posts'}, {:controller => 'posts', :action => 'index'})
    assert_equal '/posts/create', url_for({:action => 'create'}, {:controller => 'posts'})
    assert_equal '/posts?foo=bar', url_for(:controller => 'posts', :foo => 'bar')
    assert_equal '/posts?foo%5B%5D=bar&foo%5B%5D=baz', url_for(:controller => 'posts', :foo => ['bar', 'baz'])
    assert_equal '/posts?page=2', url_for(:controller => 'posts', :page => 2)
    assert_equal '/posts?q%5Bfoo%5D%5Ba%5D=b', url_for(:controller => 'posts', :q => { :foo => { :a => 'b'}})

    assert_equal '/', url_for(:controller => 'news', :action => 'index')
    assert_equal '/', url_for(:controller => 'news', :action => 'index', :format => nil)
    assert_equal '/news.rss', url_for(:controller => 'news', :action => 'index', :format => 'rss')

    assert_raise(ActionController::RoutingError) { url_for({:action => 'index'}) }
  end

  def test_generate_extras
    assert_equal ['/people', []], generate_extras(:controller => 'people')
    assert_equal ['/people', [:foo]], generate_extras(:controller => 'people', :foo => 'bar')
    assert_equal ['/people', []], generate_extras(:controller => 'people', :action => 'index')
    assert_equal ['/people', [:foo]], generate_extras(:controller => 'people', :action => 'index', :foo => 'bar')
    assert_equal ['/people/new', []], generate_extras(:controller => 'people', :action => 'new')
    assert_equal ['/people/new', [:foo]], generate_extras(:controller => 'people', :action => 'new', :foo => 'bar')
    assert_equal ['/people/1', []], generate_extras(:controller => 'people', :action => 'show', :id => '1')
    assert_equal ['/people/1', [:bar, :foo]], sort_extras!(generate_extras(:controller => 'people', :action => 'show', :id => '1', :foo => '2', :bar => '3'))
    assert_equal ['/people', [:person]], generate_extras(:controller => 'people', :action => 'create', :person => { :first_name => 'Josh', :last_name => 'Peek' })
    assert_equal ['/people', [:people]], generate_extras(:controller => 'people', :action => 'create', :people => ['Josh', 'Dave'])

    assert_equal ['/posts/show/1', []], generate_extras(:controller => 'posts', :action => 'show', :id => '1')
    assert_equal ['/posts/show/1', [:bar, :foo]], sort_extras!(generate_extras(:controller => 'posts', :action => 'show', :id => '1', :foo => '2', :bar => '3'))
    assert_equal ['/posts', []], generate_extras(:controller => 'posts', :action => 'index')
    assert_equal ['/posts', [:foo]], generate_extras(:controller => 'posts', :action => 'index', :foo => 'bar')
  end

  def test_extras
    params = {:controller => 'people'}
    assert_equal [], extra_keys(params)
    assert_equal({:controller => 'people'}, params)

    params = {:controller => 'people', :foo => 'bar'}
    assert_equal [:foo], extra_keys(params)
    assert_equal({:controller => 'people', :foo => 'bar'}, params)

    params = {:controller => 'people', :action => 'create', :person => { :name => 'Josh'}}
    assert_equal [:person], extra_keys(params)
    assert_equal({:controller => 'people', :action => 'create', :person => { :name => 'Josh'}}, params)
  end

  private
    def sort_extras!(extras)
      if extras.length == 2
        extras[1].sort! { |a, b| a.to_s <=> b.to_s }
      end
      extras
    end

    def assert_raise(e)
      result = yield
      flunk "Did not raise #{e}, but returned #{result.inspect}"
    rescue e
      assert true
    end
end
