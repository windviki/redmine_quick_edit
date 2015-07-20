# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do

  post 'quick_edit_relations', :controller => 'quick_edit_relations', :action => 'create'
  resources :issues do
    shallow do
      resources :quick_edit_relations, :controller => 'quick_edit_relations', :only => [:create, :destroy]
    end
  end

  get 'quick_edit_issues/edit', :controller => 'quick_edit_issues', :action => 'edit'
  get 'quick_edit_issues/replace_preview', :controller => 'quick_edit_issues', :action => 'replace_preview'
  post 'quick_edit_issues/replace', :controller => 'quick_edit_issues', :action => 'replace'
end

