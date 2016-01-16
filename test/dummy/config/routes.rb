Rails.application.routes.draw do
  root 'home#index'
  get '/order_test' => 'home#order_test'
end
