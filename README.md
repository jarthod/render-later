# render-later

render-later is a Rails helper allowing you to **defer** the rendering of slow parts of your views to the end of the page, drastically improving the time to first paint and thus the perceived performance.

![render-later-demo-gif](https://cloud.githubusercontent.com/assets/201687/12373435/779addfc-bc79-11e5-8863-64e985387d48.gif)

It works pretty simply by storing the blocks to render later and putting an invisible span with a unique ID instead. Then at the end of the page (right before `</body>`) it'll execute these blocks and insert inline javascript tags to replace the invisible spans with the real content. The trick is to enable HTTP streaming so the browser can render all the page quickly and add the deferred parts as they are received.

I've been using this since May 2015 on [updown.io](https://updown.io) without any trouble and decided it is time to extract it as a gem so everyone can use it. It is easy to use and pretty low-tech as it only requires HTTP/1.1 and DOM level 2 (IE6+). See the [compatibility section](#compatibility) for more details.

## Usage

Add the gem to your application's Gemfile:

```ruby
gem 'render-later'
```

In your views, simply wrap a slow piece of code into a `render_later` block, and gives it a unique key as argument, like you would do with `cache`. Example:
```erb
<div class="server">
  <%= server.name %>
  <%= render_later "srv-uptime-#{server.id}" do %>
    <%= server.uptime %>
  <% end %>
</div>
```
It's important to use the `<%=` erb tag here, as the helper will render a hidden `span` tag. If a `span` tag doesn't work well for you (ex: in a table), you can customize the placeholder element with the `tag` keyword argument, ex:
```erb
<table>
  <%= render_later "srv-uptime-#{server.id}", tag: :tr do %>
    <tr><td><%= server.uptime %></td></tr>
  <% end %>
</table>
```

In your layout, before the end of the body tag, add a call to `render_now`:
```erb
<body>
  <%= yield %>
  <%= render_now %>
</body>
```
This is where the deferred blocks will be rendered and injected into the page using inline javascript.

And finally in your controller, you need to render with the `stream` option:

```ruby
  def index
    # You may also need (see Gotcha section):
    # form_authenticity_token; flash
    # headers['Last-Modified'] = Time.now.httpdate
    # headers['X-Accel-Buffering'] = 'no'
    render stream: true
  end
```

## Performance

Performance-wise, this approach is quite interesting, let me explain why:
We know that bandwidth is always increasing, web performance is getting more and more constrained by latency.

For cases like this, there is usually two ways:

1. Render everything inline and slow down the page load.
2. Load the slow data with Ajax, after the initial page is loaded.

The first solution is, IMO, decent **if using streaming**, because the browser can start loading css and js while the rest of the page is being streamed. But let's be honest, nobody does streaming, especially in the rails world, often leading to 1s+ page generation time (= 2s+ white screen for the user).

The second solution gets the first page rendered quickly but is much more complex to setup (needs another endpoint to expose the data, an Ajax call to fetch them, and some js to put the data back where it belongs, handle loading spinner, errors, etc.). It is also much **slower to load**, because the browser needs to load & parse all the javascript, wait to the entire page to be ready (domready), and only then it will start the ajax call, adding the whole round-trip time once again to the page loading.

Whereas with render-later, you leverage the existing open socket currently downloading the document to stream the deferred data:
- You don't have to handle errors, because it's the same request. So if it fails at this point, the browser will simply show it's native error page.
- You don't have to show any kind of spinner because the browser is still showing it's native loading indicator.
- You don't increase latency because the additional data start streaming right away after the page is sent. And even better, the deferred data **starts rendering even if the browser didn't receive a single byte yet**, so if you're on a slow network (ex: 3G, 500ms rtt), instead of delaying even more (Ajax call), you'll actually receive the document **already complete**, because while the network lagged, the server was working :)

So in the end, this solutions is the best of both world: you get the first paint time of the Ajax version, but with the simplicity and time-to-full-document of the simple inline version.

The only downsides of this approach IMO are:
1. The `domready` event will only be executed at the end of the end of the streaming, once the body is complete.
2. Rails/rack support for streaming is bad and you may need to workaround some bugs.
See the [Gotcha section](#gotcha) for more details.

## Compatibility

On the server side, the gem is tested against `ruby 2.3+` and `rails 4.1+`.
The dependency is not strictly enforced though and it may work with others versions but we don't guaranty anything.

The generated javascript is a simple inline function using nothing else than DOM Core level 2 properties, so it should work flawlessly on IE6+, Firefox 2+, Chrome 1+, Edge, Safari, etc.

## Gotcha

#### domready
The domeady event will only be executed at the end of the request, once the body is complete. So if you have a lot of javascript on domready, which for example bind clicks to popups and ajax actions, there will be a timeframe during which the user will be able to click and the js isn't executed yet.

This is actually an issue with streaming or async javascript loading and has nothing to do with render-later, but as render-later pushes you to use streaming it feels right to warn you about this.

To circumvent this you can use event delegation and bind outside the domready event for example, and/or make sure your links won't lead to an error page if clicked without javascript.

#### Web server
Not all ruby web servers supports HTTP streaming unfortunately. So you obviously need to use one which does. Here is a non-exhaustive list of servers along with their support:

Server            | Supported  | Comment
------------------|------------| -------
Phusion Passenger | ✔️         |
Unicorn           | ✔️         | _with `tcp_nopush: false`_
puma              | ✔️*        | _default for `rails s`_
WEBrick           | ❌         |
Thin              | ❌         |

\*puma `6.0.0` is not compatible due to https://github.com/puma/puma/issues/3000

To try it in development, I recommend using `puma` (the default Rails server) with `rails s`. We need the multiple threads in development to avoid blocking CSS/JS requests during the page streaming. It's totally fine to develop with a single thread/process or a server which doesn't support streaming, you just won't see the effects of the gem.

#### Reverse proxy

If you are using an HTTP reverse proxy such as nginx, you may encounter some buffering issues as the reverse proxy batch together several chunks (or even the whole response) and send them at once, effectively defeating the reader-later feature. If you notice this issue the best way I found to avoid it in nginx is to disable `proxy_buffering` but only for the streamed responses, using the `X-Accel-Buffering: no` header. In the controller it looks like this:

```ruby
  def index
    form_authenticity_token; flash
    headers['X-Accel-Buffering'] = 'no' # disable nginx buffering
    render stream: allow_streaming
  end
```

It's possible to disable `proxy_buffering` globally and many post on the internet will recommend this but it's a bad idea IMO because it makes your responses slower, more vulnerable to some attacks (slow client), and also breaks/disable other features like nginx caching. So better do it only for the endpoints which really need that, and usually don't need caching. If your endpoint is publicly cacheable by the reverse proxy, there's not much point in using render-later anyway, better optimize the cache rate so almost everybody experiences fast response times.

Also I tried playing with `proxy_buffers`, `proxy_buffer_size`, `proxy_busy_buffers_size` and `gzip_buffers` to see if could reduce the buffering sufficiently to keep it enabled while still benefiting from render-later. Without compression it was OK but with gzip compression enabled I couldn't. No matter how small buffers I declared I was still receiving at least the first 16kB together which was not granular enough for my needs. If you are using render-later for very large pages, you might be able to keep the buffering+compression enabled and still see enough benefits. 

#### Template Engine
Like for web servers, some template engine in Rails doesn't support streaming and requires to generate the entire page before sending it on the wire. You will need to avoid them at least for the layout page which will contain the `render_now` statement.

Template engine | Supported  | Comment
----------------|------------| -------
ERB             | ✔️         | _rails default_
Slim            | ✔️         |
Haml            | ❌         |

#### Flash message & CSRF token

There is currently an [issue with Rails i'm trying to revive](https://github.com/rails/rails/issues/11476) about streaming causing trouble with flash messages and CSRF tokens. This is because rails waits the end of the request to check if you have used the flash message, if so it is removed from the store, otherwise it stays for the next request. But with streaming on, rails considers the requests as ended very early, before the flash message ever gets a change to be rendered. So this logic fails and keeps the flash message forever. The problem is exactly the same with the CSRF token.

The best **workaround** we currently have is to fool rails by accessing the flash message and CSRF token before the render call:

```ruby
  # in the controller, before every streaming render.
  def index
    form_authenticity_token; flash
    render stream: true
  end
```

#### Rack 2.2.x & ETag Middleware

There's a recent change in `rack 2.2.x` which broke streaming in Rails as can [be seen in this issue](https://github.com/rack/rack/issues/1619). The problem is that the ETag middleware used to ignore streaming response because of the `Cache-Control: no-cache` header (which is set by Rails for streaming response) and now it doesn't any more (because this behavior wasn't really valid). But the ETag middleware now has to process the whole body to generate the ETag header and thus blocks the response until everything is ready.

The best **workaround** we currently have until this problem is fixed is to monkey patch Rack::ETag with:
```ruby
# Monkey patch for Rack::ETag (ver 2.2+) to prevent breaking streaming responses (chunked)
# See https://github.com/rack/rack/issues/1619 for more details on the problem

module Rack
  class ETag
    def skip_caching?(headers)
      headers.key?(ETAG_STRING) || headers[TRANSFER_ENCODING] == "chunked" || headers.key?('Last-Modified')
    end
  end
end
```

Another option you may use if you only need it once or twice is to fool the ETag middleware by setting the `Last-Modified` header from the controller (if set, the ETag middleware is skipped):

```ruby
  # in the controller, before every streaming render.
  def index
    headers['Last-Modified'] = Time.now.httpdate
    render stream: true
  end
```

#### Caching

Finally, before your scratch your head, be careful not to put fragment caching **outside** a `render_later` block, because that would actually cache the empty span but not the inline script (which is generated by `render_now`), so it would be a waste and the real content will never be injected. It's totally **fine/recommended** to use fragment caching **inside** the `render_later` block.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jarthod/render-later.

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake` to run the tests.

Start the demo server:
```bash
cd test/dummy && rails s
```

Verify the streaming behavior in browser (http://localhost:3000) or curl:
```bash
curl http://localhost:3000
```

Test with a specific Rails version:
```bash
cd test/dummy
bundle install --gemfile=../gemfiles/rails-5.0.gemfile
bundle exec --gemfile=../gemfiles/rails-5.0.gemfile rails s
```

## Ideas for improvement

- Wider test coverage across browsers using [Sauce Labs](https://saucelabs.com/opensauce/)
- Parallel rendering (I tried quickly but the `capture` helper isn't thread-safe)
- Add options to do caching at the same time (with the same key)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

