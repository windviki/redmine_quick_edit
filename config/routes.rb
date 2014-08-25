# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  resources :issues do
    shallow do
      #resources :relations, :controller => 'issue_relations', :only => [:index, :show, :create, :destroy]
      resources :quick_edit_relations, :controller => 'quick_edit_relations', :only => [:create, :destroy]
    end
  end

#  resources :project do
#  end
end

