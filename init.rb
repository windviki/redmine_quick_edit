#coding: utf-8

require_dependency File.expand_path('../app/helpers/application_helper.rb', __FILE__)
require_dependency File.expand_path('../hooks', __FILE__)

Redmine::Plugin.register :quick_edit do
  name 'Quick Edit plugin'
  author 'Akira Saito'
  description 'This plugin provides ability to edit a fields of the issue at the issues page.'
  version '0.0.4'

  permission :manage_quick_edit_relations, {:quick_edit_relations => [:create]}, :public => true
end
