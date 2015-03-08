#coding: utf-8

require_dependency File.expand_path('../app/helpers/application_helper.rb', __FILE__)
require_dependency File.expand_path('../hooks', __FILE__)


# plugin name depends to plugin directory
plugin_name = File.dirname(File.expand_path(__FILE__))
plugin_name = File.basename(plugin_name)

Redmine::Plugin.register plugin_name do
  name 'Quick Edit plugin'
  author 'Akira Saito'
  description 'This plugin provides ability to edit a fields of the issue at the issues page.'
  version '0.0.7.1'

  permission :manage_quick_edit_relations, {:quick_edit_relations => [:create, :destroy]}, :public => true
end
