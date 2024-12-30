require "./hackr.tv.rb"

set :bind, "0.0.0.0"
set :port, 4567
run Sinatra::Application
