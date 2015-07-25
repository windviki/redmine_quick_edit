class QuickEditIssuesController < ApplicationController
  include ApplicationHelper
  before_filter :find_issues
  before_filter :check_first_issue
  before_filter :check_target_specifier
  before_filter :check_replace_args, :only => [:replace, :replace_preview]

  def edit
    @dialog_params = nil
    @issue.available_custom_fields.each do |f|
      custom_field_name = 'issue[custom_field_values][%d]' % f.id
      if custom_field_name == @target_specifier
        @dialog_params = get_input_dialog_params_for_custom_fields(@issue, @target_specifier, f)
        @dialog_params[:description] = f.description.presence if f.attributes().has_key?('description')
      end
    end
    if @dialog_params.nil?
      @dialog_params = get_input_dialog_params_for_core_fields(@issue, @target_specifier)
      @dialog_params[:description] = nil
    end
    @dialog_params[:description] = nil if (@dialog_params[:description] == "")
    @dialog_params[:issue_ids] = params[:ids]
    @dialog_params[:back_url] = params[:back_url]
    @dialog_params[:default_value] = params[:default_value] unless (params[:default_value].nil?)
  end

  def replace_preview
    @replaced_issues = @issues.map do |issue|
      { :id  => issue.id,
        :old => issue[@attribute_name],
        :new => issue[@attribute_name].gsub(@find, @replace) }
    end
  end

  def replace
    Issue.transaction do
      @issues.each do |issue|
        logger.info "#{issue.id}"
        issue.safe_attributes = {@attribute_name => issue[@attribute_name].gsub(@find, @replace)}
        issue.save!
      end
    end

    redirect_to params[:back_url]
  end

private
  # rails filter
  def check_first_issue
    if @issues.empty?
      logger.warn "### quick edit ### issues not found."
      render_404
    end

    @issue = @issues[0]
  end

  # rails filter
  def check_target_specifier
    @target_specifier = params[:target_specifier]
    if @target_specifier.nil?
      logger.warn "### quick edit ### missing target specifier."
      render_404
      return
    end

    parsed = parse_target_specifier(@target_specifier)
    if parsed.nil? || parsed.empty?
      logger.warn "### quick edit ### invalid target specifier. target_specifier=" + @target_specifier
      render_404
      return
    end

    @attribute_name = parsed[0]
    if parsed.size == 2
      @custom_field_id = parsed[1]
    else
      @custom_field_id = ""
    end
    unless @issue.safe_attribute_names.include?(@attribute_name)
      logger.warn "### quick edit ### no safe attribute. target_specifier=" + @target_specifier
      render_404
    end
  end

  def check_replace_args
    unless @attribute_name.include?('subject')
      logger.warn "### quick edit ### no support. target_specifier=" + @target_specifier
      render_error :status => 400
      return
    end

    @find = params[:find_value]
    if @find.nil? || @find == ""
      logger.warn "### quick edit ### missing params[find_value]."
      render_error :status => 400
      return
    end

    if @find.length > 127
      logger.warn "### quick edit ### length over params[find_value]."
      render_error :status => 400
      return
    end

    @replace = params[:replace_value]
    if @replace.length > 127
      logger.warn "### quick edit ### length over params[replace_value]."
      render_error :status => 400
      return
    end
  end

  def get_input_dialog_params_for_core_fields(issue, target_specifier)
    attribute_name = parse_target_specifier(target_specifier)[0]

    caption = get_attribute_caption(attribute_name)
    field_type = get_attribute_type(attribute_name)
    default_value = issue[attribute_name]
    default_value = "" if default_value.nil?
    validation_pattern = get_field_validation_pattern(field_type)
    help_message = get_field_help_message(field_type)
    clear_pseudo_value = nil
    clear_pseudo_value = 'none' if %w(parent_issue_id start_date due_date estimated_hours).include?(attribute_name)

    ret =
      { :attribute_name => attribute_name.to_sym,
        :caption => caption,
        :target_specifier => target_specifier,
        :field_type => field_type,
        :default_value => default_value,
        :validation_pattern => validation_pattern,
        :help_message => help_message,
        :clear_pseudo_value => clear_pseudo_value
      }
  end

  def get_input_dialog_params_for_custom_fields(issue, target_specifier, custom_field)
    attribute_name = parse_target_specifier(target_specifier)[0]

    caption = custom_field.name
    field_type = custom_field.field_format.to_sym
    default_value = issue.editable_custom_field_values.detect {|v| v.custom_field_id == custom_field.id}
    default_value = "" if default_value.nil?
    validation_pattern = get_field_validation_pattern(field_type)
    help_message = get_field_help_message(field_type)

    ret =
      { :attribute_name => attribute_name.to_sym,
        :caption => caption,
        :target_specifier => target_specifier,
        :field_type => field_type,
        :default_value => default_value,
        :validation_pattern => validation_pattern,
        :help_message => help_message,
        :clear_pseudo_value => '__none__'
      }
  end

  def get_field_validation_pattern(field_type)
     case field_type.to_sym
     when :string
        pattern = ''
     when :text
        pattern = ''
     when :int
        pattern = '\d+'
     when :float
        pattern = '^[+-]?(\d+|\d*\.\d+|\d+\.\d+)($|[eE][+-]?\d+$)'
     when :date
        pattern = '\d{4}-\d{2}-\d{2}'
     end
  end

  def get_field_help_message(field_type)
    help_message= l(:text_edit_confirm)
    help_message += " (yyyy-mm-dd)" if field_type == :date
    help_message
  end

end
