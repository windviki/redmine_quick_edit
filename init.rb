#coding: utf-8

require_dependency File.expand_path('../app/helpers/application_helper.rb', __FILE__)
require_dependency File.expand_path('../hooks', __FILE__)


# plugin name depends to plugin directory
plugin_name = File.dirname(File.expand_path(__FILE__))
plugin_name = File.basename(plugin_name).to_sym

Redmine::Plugin.register plugin_name do
  name 'Quick Edit plugin'
  author 'Akira Saito'
  description 'This plugin provides ability to edit a fields of the issue at the issues page.'
  version '0.0.8'

  permission :manage_quick_edit_relations, {:quick_edit_relations => [:create, :destroy]}, :public => true

  settings :default => {'custom_field_exclude_names'=>'',
                        'textarea_size'=>'80,10',
                        'input_dialog_base_size'=>'480,280'},
           :partial => 'quick_edit_issues/settings'
end
