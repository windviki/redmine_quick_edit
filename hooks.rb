#coding: utf-8

class QuickEditHooks < Redmine::Hook::ViewListener
	render_on :view_layouts_base_html_head, :partial=> 'hooks/quick_edit_base_head'
	render_on :view_layouts_base_body_bottom, :partial=> 'hooks/quick_edit_base_bottom'
	render_on :view_issues_context_menu_end, :partial=> 'hooks/quick_edit_context'
end
