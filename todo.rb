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

# Render the new list form
get '/lists/new' do
  erb :new_list
end

get '/lists/:number' do
  @list = session[:lists][params[:number].to_i]
  if @list
    erb :list
  else
    redirect '/lists'
  end
end

# Return an error message if list name invalid, otherwise return nil
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'List name must be 1 to 100 characters long!'
  elsif session[:lists].map { |v| v[:name] }.include?(name)
    'List name must be unique!'
  end
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "List #{list_name} created successfully."
    redirect '/lists'
  end
end
