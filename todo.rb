#  Completed project reference: https://ls-170-sinatra-todos.herokuapp.com/

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
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

# View all todos for given list
get '/lists/:id' do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  if @list
    erb :list
  else
    session[:error] = "The specified list was not found."
    redirect '/lists'
  end
end

# Edit existing list
get '/lists/:id/edit' do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :edit_list
end

# Delete existing list
post '/lists/:id/delete' do
  id = params[:id].to_i
  @list = session[:lists].delete_at(id)
  session[:success] = "List #{@list[:name]} deleted successfully."
  redirect "/lists"
end

# Update existing list
post '/lists/:id' do
  @id = params[:id].to_i
  @list = session[:lists][@id]

  edited_list_name = params[:list_name].strip
  error = error_for_list_name(edited_list_name)
  if error
    session[:error] = error

    erb :edit_list
  else
    @list[:name] = edited_list_name
    session[:success] = "List #{edited_list_name} renamed successfully."
    redirect "/lists/#{@id}"
  end
end
