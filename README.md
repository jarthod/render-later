# render-later

Render-later allows you to defer the rendering of slow parts of your views to the end of the page, allowing you to drastically improve the time to first paint and perceived performance.

It stores the blocks to render later and put an invisible span with a unique ID instead. Then at the end of the page (usually before `</body>`) it'll render this block and insert inline javascript tag to replace the invisible span with the real content. Of course it requires HTTP streaming so the browser can render all the page quickly and add the deferred parts as they are received.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem 'render-later'
```

## Usage

In your views, simply wrap a slow piece of code into a {{render_later}} block, and gives it a unique key as argument, like you would do with {{cache}}:
```erb
<div class="server">
  <%= server.name %>
  <%= render_later "srv-uptime-#{server.id}" do %>
    <%= server.uptime %>
  <% end %>
</uptime>
```
It's important to use the `<%=` erb tag here, as the helper will render a hidden span tag.

In your layout, before the end of the body tag, add a call to {{render_now}}:
```erb
  <body>
    <%= yield %>
    <%= render_now %>
  </body>
```
This is where the defered blocks will be rendered and injected into the page using inline javascript.

## Performance
very good, latency, delay etc..

## Compatibility

On the server side, the gem is tested against `ruby 2.1+` and `rails 4.1+`.
The dependency is not strictly enforced and it may work with others version but we don't guaranty anything.

The generated javascript is a simple inline function using nothing else than DOM Core level 2 properties, so it should work flawlessly on IE6+, Firefox 2+, Chrome 1+, Edge, Safari, etc.

## Gotcha
- Not all servers
- Flash message
- No haml
- CSRF token
- Fragment cache inside, not outside
- domready will wait
- https://github.com/rails/rails/issues/11476

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jarthod/render-later.

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake` to run the tests.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

