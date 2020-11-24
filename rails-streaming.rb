#!/usr/bin/env ruby

begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  gem 'rails', "~> #{ARGV.first || "6.0"}"
end

require 'rack/test'
require 'action_controller/railtie'

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  config.hosts.clear if config.respond_to? :hosts # needed to allow request in Rails 6
  config.session_store :cookie_store, key: 'cookie_store_key'
  secrets.secret_token    = 'secret_token'
  secrets.secret_key_base = 'secret_key_base'

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    get '/' => 'test#index'
    get '/set_flash' => 'test#set_flash'
  end
end

class TestController < ActionController::Base
  include Rails.application.routes.url_helpers
  prepend_view_path Rails.root

  def index
    render template: 'template', stream: params[:stream]
  end

  def set_flash
    flash.notice = 'notice'
    render plain: 'ok'
  end
end

require 'minitest/autorun'

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class BugTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    IO.write('template.html.erb', '<%= csrf_meta_tag %><%= flash.notice %>')
  end

  def teardown
    File.unlink('template.html.erb')
  end

  def test_works_without_stream
    get '/set_flash'
    assert last_response.ok?
    get '/'
    assert last_response.ok?
    assert_match /notice/, last_response.body
    get '/'
    assert last_response.ok?
    refute_match /notice/, last_response.body
  end

  def test_works_with_stream
    get '/set_flash'
    assert last_response.ok?
    get '/', stream: true
    assert last_response.ok?
    assert_match /notice/, last_response.body
    get '/', stream: true
    assert last_response.ok?
    refute_match /notice/, last_response.body
  end

  private

  def app
    Rails.application
  end
end
