#  Completed project reference: https://ls-170-sinatra-todos.herokuapp.com/

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  if !(1..100).cover?(list_name.size)
    session[:error] = "List name must be 1 to 100 characters long!"
    erb :new_list
  elsif session[:lists].map{ |v| v[:name] }.include?(list_name)
    session[:error] = "List name must be unique!"
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "List #{list_name} created successfully."
    redirect '/lists'
  end
end

# Render the new list form
get '/lists/new' do
  erb :new_list
end
