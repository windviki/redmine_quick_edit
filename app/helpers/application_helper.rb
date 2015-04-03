#coding: utf-8

module ApplicationHelper
  def redmine_version()
    Redmine::VERSION::MAJOR * 10 + Redmine::VERSION::MINOR
  end

  def editable(attribute_name, can)
    if redmine_version() >= 30
      return can[:edit]
    else
      return can[:update]
    end
  end

  def quick_edit_link_to(issue_ids, caption, attribute_name, additional_index, back_url, disabled)
     target_specifier = build_target_specifier(attribute_name, additional_index)

     ajax_url = quick_edit_issues_edit_path(:ids => issue_ids, :target_specifier => target_specifier, :back_url => back_url)

     sprintf('<li>%s</li>',
        context_menu_link(
           h(caption),
           ajax_url,
           :class => 'icon-edit',
           :disabled => disabled,
           :remote => true
        )
     ).html_safe()
  end   

  def build_target_specifier(attribute_name, additional_index)
    target = "issue[#{attribute_name}]"
    target += "[#{additional_index}]" unless additional_index.nil?
    target
  end

  def parse_target_specifier(target_specifier)
    /^issue\[(.+?)\].*/ =~ target_specifier
    if Regexp.last_match.nil?
      return nil
    end

    attribute_name = Regexp.last_match(1)

    /^issue\[.+?\]\[(\d+)\]$/ =~ target_specifier
    if Regexp.last_match.nil?
      additional_index = nil
      result = [attribute_name]
    else
      additional_index = Regexp.last_match(1)
      result = [attribute_name, additional_index]
    end

    result
  end

  def get_attribute_caption(attribute_name)
     case attribute_name.to_sym
     when :subject
        l(:field_subject)
     when :description
        l(:field_description)
     when :parent_issue_id
        l(:field_parent_issue)
     when :start_date
        l(:field_start_date)
     when :due_date
        l(:field_due_date)
     end
  end


  def get_attribute_type(attribute_name)
     case attribute_name.to_sym
     when :subject
        :string
     when :description
        :text
     when :parent_issue_id
        :int
     when :start_date
        :date
     when :due_date
        :date
     end
  end
end

