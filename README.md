# render-later

Render-later allows you to defer the rendering of slow parts of your views to the end of the page, allowing you to drastically improve the time to first paint and percieved performance.

It stores the blocks to render later and put an invisible span with a unique ID instead. Then at the end of the page (usually before `</body>`) it'll render this block and insert inline javascript tag to replace the invisible span with the real content. Of course it requires HTTP streaming so the browser can render all the page quickly and add the deferred parts as they are received.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem 'render-later'
```

## Usage

TODO: Write usage instructions here

## Performance
very good, latency, delay etc..

## Gotcha
- Not all servers
- Flash message
- No haml
- CSRF token
- Fragment cache inside, not outside
- domready will wait
- https://github.com/rails/rails/issues/11476

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/render-later.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

