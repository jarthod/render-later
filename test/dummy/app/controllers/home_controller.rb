class HomeController < ApplicationController
  def index
    # Rack 2.2.x breaks streaming because of ETag:
    # https://github.com/rack/rack/issues/1619
    # current workaround is:
    headers['Last-Modified'] = Time.now.httpdate
    render stream: true
  end

  def order_test
    headers['Last-Modified'] = Time.now.httpdate
    render stream: true
  end
end
