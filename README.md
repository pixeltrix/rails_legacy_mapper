Rails Legacy Mapper
===================

[![Build Status][build]][travis] [![Dependency Status][depends]][gemnasium]

This gem provides an extraction of the DeprecatedMapper from Rails 3.0.
If you have a legacy application with an old style routes.rb file this
allows you to get your application running quickly in Rails 3.1.

Example
-------

The trigger for using the legacy mapper is the arity (number of args)
of the block passed to draw, e.g:

``` ruby
LegacyApp::Application.routes.draw do |map|

  map.root :controller => 'pages', :action => 'index'

  map.namespace :admin do |admin|
    admin.resources :pages
  end

  map.page '/pages/:id', :controller => 'pages', :action => 'show'

  map.connect '/:controller/:action/:id/'

end
```

License
-------

Copyright (c) 2011 Andrew White, released under the MIT license

[build]: https://secure.travis-ci.org/pixeltrix/rails_legacy_mapper.png
[travis]: http://travis-ci.org/pixeltrix/rails_legacy_mapper
[depends]: https://gemnasium.com/pixeltrix/rails_legacy_mapper.png?travis
[gemnasium]: https://gemnasium.com/pixeltrix/rails_legacy_mapper
