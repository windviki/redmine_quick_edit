#coding: utf-8

module ApplicationHelper
  def redmine_version()
    Redmine::VERSION::MAJOR * 10 + Redmine::VERSION::MINOR
  end

  def editable(attribute_name, can, readonly_fields)
    if readonly_fields.include?(attribute_name.to_s)
      return false
    end

    if redmine_version() >= 30
      return can[:edit]
    else
      return can[:update]
    end
  end

  def editable_custom_field(custom_field, can, readonly_fields)
    if readonly_fields.include?(custom_field.id.to_s)
      return false
    end

    if redmine_version() >= 30
      return can[:edit]
    else
      return can[:update]
    end
  end

  def quick_edit_link_to(issue_ids, caption, attribute_name, additional_index, back_url, disabled, icon=%s{icon-edit})
     target_specifier = build_target_specifier(attribute_name, additional_index)

     ajax_url = quick_edit_issues_edit_path(:ids => issue_ids, :target_specifier => target_specifier, :back_url => back_url)

     html_id = "quick_edit_context_#{attribute_name}"
     html_id += "_#{additional_index}" unless additional_index.nil?

     sprintf("<li id='#{html_id}'>%s</li>",
        context_menu_link(
           h(caption),
           ajax_url,
           :class => "quick_edit #{icon}",
           :disabled => disabled,
           :remote => true
        )
     ).html_safe()
  end   

  def build_target_specifier(attribute_name, additional_index)
    if  attribute_name == :notes
       return "notes"
    end

    target = "issue[#{attribute_name}]"
    target += "[#{additional_index}]" unless additional_index.nil?
    target
  end

  def parse_target_specifier(target_specifier)
    if target_specifier == "notes"
      return [:notes]
    end

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
     when :estimated_hours
        l(:field_estimated_hours)
     when :notes
        l(:field_notes)
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
     when :estimated_hours
        :float
     when :notes
        :text
     end
  end

  def parse_size(size, width_range, width_default, height_range, height_default)
     size = size.split(",")
     size[0] = width_default if size.length != 2 || !size[0].match(/\d{1,9}/)
     size[1] = height_default if size.length != 2 || !size[1].match(/\d{1,9}/)
     size[0] = size[0].to_i
     size[1] = size[1].to_i
     size[0] = width_default unless width_range.include?(size[0])
     size[1] = height_default unless height_range.include?(size[1])

     size
  end
end

