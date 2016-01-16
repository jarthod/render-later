class HomeController < ApplicationController
  def index
    render stream: true
  end

  def order_test
    render stream: true
  end
end
