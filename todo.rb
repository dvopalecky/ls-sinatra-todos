# Simple Todo App with lists of todos

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

helpers do
  def complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list).zero?
  end

  def list_class(list)
    'complete' if complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].count { |todo| !todo[:done] }
  end

  def todos_count(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    complete, incomplete = lists.partition { |list| complete?(list) }

    incomplete.each(&block)
    complete.each(&block)
  end

  def sort_todos(todos, &block)
    complete, incomplete = todos.partition { |todo| todo[:done] }

    incomplete.each(&block)
    complete.each(&block)
  end
end

# Return an error message if list name is invalid, otherwise return nil
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'List name must be 1 to 100 characters long!'
  elsif session[:lists].map { |v| v[:name] }.include?(name)
    'List name must be unique!'
  end
end

# Return an error message if todo is invalid, otherwise return nil
def error_for_todo(name)
  'Todo must be 1 to 100 characters long!' unless (1..100).cover?(name.size)
end

# Returns an error if list is not found and the list if it is
def load_list(id)
  loaded_list = session[:lists].find { |list| list[:id] == id }
  if loaded_list
    loaded_list
  else
    session[:error] = 'The specified list was not found.'
    redirect '/lists'
  end
end

def new_id(todos_or_lists)
  max = todos_or_lists.map { |item| item[:id] }.max || 0
  max + 1
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

not_found do
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

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    id = new_id(session[:lists])
    session[:lists] << { id: id, name: list_name, todos: [] }
    session[:success] = "List '#{list_name}' created successfully."
    redirect '/lists'
  end
end

# View all todos for given list
get '/lists/:id' do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  erb :list
end

# Edit existing list
get '/lists/:id/edit' do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  erb :edit_list
end

# Delete existing list
post '/lists/:id/delete' do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  session[:lists].delete(@list)
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    # ajax
    '/lists'
  else
    session[:success] = "List '#{@list[:name]}' deleted successfully."
    redirect '/lists'
  end
end

# Update existing list
post '/lists/:id' do
  list_id = params[:id].to_i
  @list = load_list(list_id)

  edited_list_name = params[:list_name].strip
  error = error_for_list_name(edited_list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = edited_list_name
    session[:success] = "List '#{edited_list_name}' renamed successfully."
    redirect "/lists/#{@list[:id]}"
  end
end

# Add new todo to a list
post '/lists/:list_id/todos' do
  list_id = params[:list_id].to_i
  @list = load_list(list_id)
  todo = params[:todo].strip
  error = error_for_todo(todo)
  if error
    session[:error] = error
    erb :list
  else
    id = new_id(@list[:todos])
    @list[:todos] << { id: id, name: todo, done: false }
    session[:success] = "Todo '#{todo}' was added."
    redirect "/lists/#{@list[:id]}"
  end
end

# Check all todos in a list
post '/lists/:list_id/complete_all' do
  list_id = params[:list_id].to_i
  list = load_list(list_id)
  list[:todos].each do |todo|
    todo[:done] = true
  end

  session[:success] = 'All todos marked as complete.'
  redirect "/lists/#{list_id}"
end

# Delete a todo from a list
post '/lists/:list_id/todos/:todo_id/delete' do
  list_id = params[:list_id].to_i
  list = load_list(list_id)
  todo_id = params[:todo_id].to_i
  list[:todos].reject! { |todo| todo[:id] == todo_id }
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    # ajax
    status 204
  else
    session[:success] = 'Todo deleted successfully.'
    redirect "/lists/#{list_id}"
  end
end

# Check/Uncheck a todo in a list
post '/lists/:list_id/todos/:todo_id' do
  list_id = params[:list_id].to_i
  list = load_list(list_id)
  todo_id = params[:todo_id].to_i
  todo = list[:todos].find { |td| td[:id] == todo_id }

  todo[:done] = (params[:completed] == 'true')
  status = todo[:done] ? 'complete' : 'incomplete'

  session[:success] = "Todo '#{todo[:name]}' marked as #{status}."
  redirect "/lists/#{list_id}"
end
