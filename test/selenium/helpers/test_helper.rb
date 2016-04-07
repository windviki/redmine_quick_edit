# coding: utf-8

require "nokogiri"
require "uri"
require "net/http"

class TestHelper
  attr_accessor :base_url
  attr_accessor :page
  attr_accessor :issue_id
  attr_accessor :api_key
  
  def edit(attribute_name, new_value)
    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    @page = quick_edit.update_field(@issue_id, menu_selector, new_value)
  
    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(@issue_id, attribute_name)
  
    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end
  
  def edit_with_alert(attribute_name, new_value)
    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    quick_edit.update_field(@issue_id, menu_selector, new_value, true)
    quick_edit.alert.accept
    quick_edit.cancel_quick_edit
  
    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(@issue_id, attribute_name)
  
    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def clear(attribute_name, notes = nil)
    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    @page = quick_edit.clear_field(@issue_id, menu_selector, notes)

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(@issue_id, attribute_name)
  end

  def replace(attribute_name, params)
    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    @page = quick_edit.replace(@issue_id, menu_selector, params)
  
    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(@issue_id, attribute_name)
  
    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end
  
  def replace_with_alert(attribute_name, params)
    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    quick_edit.replace(@issue_id, menu_selector, params, true)
    quick_edit.alert.accept
    quick_edit.cancel_quick_edit
  
    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(@issue_id, attribute_name)
  
    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def edit_custom_field(custom_field_name, new_value)
    cf = select_field(get_custom_field_defs(), custom_field_name)
    cf_id = cf["id"]

    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(:custom_field, cf_id)
    @page = quick_edit.update_field(@issue_id, menu_selector, new_value)

    cf = select_field(get_custom_fields(@issue_id), custom_field_name)
    cf["value"]
  end

  def edit_custom_field_with_alert(custom_field_name, new_value="")
    cf = select_field(get_custom_field_defs(), custom_field_name)
    cf_id = cf["id"]

    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(:custom_field, cf_id)
    quick_edit.update_field(@issue_id, menu_selector, new_value, true)
    quick_edit.alert.accept
    quick_edit.cancel_quick_edit

    cf = select_field(get_custom_fields(@issue_id), custom_field_name)
    cf["value"]
  end

  def clear_custom_field(custom_field_name, notes = nil)
    cf = get_custom_field(@issue_id, custom_field_name)
    cf_id = cf["id"]

    quick_edit = @page.open_context(@issue_id)
    menu_selector = quick_edit.menu_selector(:custom_field, cf_id)
    @page = quick_edit.clear_field(@issue_id, menu_selector, notes)

    cf = get_custom_field(@issue_id, custom_field_name)
    cf["value"]
  end

  def get_core_field(issue_id, attribute_name)
    json = get_json("issues/#{issue_id}.json")

    json["issue"][attribute_name.to_s]
  end

  def get_custom_field(issue_id, custom_field_name)
    cf_hash_list = get_custom_fields(issue_id)

    cf_hash = cf_hash_list.select do |cf_hash|
      cf_hash["name"] == custom_field_name.to_s
    end

    cf_hash.first
  end

  def get_custom_fields(issue_id)
    json = get_json("issues/#{issue_id}.json")

    json["issue"]["custom_fields"]
  end

  def get_custom_field_defs
    begin 
      json = get_json("custom_fields.json?key=#{@api_key}")
      json["custom_fields"] 
    rescue Net::HTTPServerException
      get_custom_fields(1) # for redmine-~3.1
    end
  end

  def select_field(fields, custom_field_name)
    fields.find do |cf_hash|
      cf_hash["name"] == custom_field_name.to_s
    end
  end

  def get_json(path)
    # p "#{@base_url}#{path}"
    uri = URI::parse "#{@base_url}#{path}"
    res = Net::HTTP::get_response(uri)

    res.value
    JSON.parse(res.body)
  end

  def latest_note()
    result = {:value => nil, :notes => {:text => nil, :is_private => nil}}

    feed = get_feed("issues/#{@issue_id}.atom", @page.session_cookie).css("entry")
    feed_limitted = get_feed("issues/#{@issue_id}.atom").css("entry")

    entry = feed.pop
    entry_limitted = feed_limitted.pop

    parsed_entry = parse_feed_entry(entry)
    parsed_entry_limitted = parse_feed_entry(entry_limitted)
    #p "parsed_entry---"
    #p parsed_entry.inspect
    #p "parsed_entry_for_guest---"
    #p parsed_entry_limitted.inspect

    # private notes?
    if parsed_entry[:notes][:journal_id].to_s != parsed_entry_limitted[:notes][:journal_id].to_s
      result[:notes][:is_private] = true
    else
      result[:notes][:is_private] = false
    end

    # The <entry> was splitted if notes is private.
    if result[:notes][:is_private]
      result[:value] = parsed_entry_limitted[:value]
      result[:notes][:text] = parsed_entry[:notes][:text]
    else
      result[:value] = parsed_entry[:value]
      result[:notes][:text] = parsed_entry[:notes][:text]
    end

    result
  end

  def parse_feed_entry(entry)
    result = {:value => nil, :notes => {:journal_id => nil, :text => nil, :is_private => nil}}

    # parse <id>
    result[:notes][:journal_id] = entry.css("id").text

    # parse <content>
    src = entry.css("content").text
    #p "content=" + src
    html = Nokogiri::HTML(src)

    # get change field from <content>
    # - attension - one field only.
    unless html.css("li").empty?
      change_desc = html.css("li").first
      #p "li=" + change_desc.inner_html

      field_name = change_desc.css("strong").first.text
      if change_desc.css("i").length == 2
        result[:value] = change_desc.css("i").last.text
      else
        result[:value] = :none
      end
    end

    # get notes from <content>
    # - attension - not support wiki format
    #p "inner html=" + html.inner_html
    notes = Nokogiri::HTML(html.inner_html).css("p").inner_html.gsub(/<br>/, "\n")
    #p "text=" + notes
    result[:notes][:text] = notes

    result
  end
  
  def get_feed(path, session_cookie=nil)
    uri = URI::parse "#{@base_url}#{path}"
    if session_cookie.nil?
      headers = {}
    else
      headers = {'Cookie' => cookie_hash_to_header_string(session_cookie)}
    end
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.path, headers)
    end
    src = res.body.gsub(/<content type="html">/, "<content>") # To avoid erroneous decisions made by Nokogiri
    Nokogiri::Slop(src)
  end

  def cookie_hash_to_header_string(cookie)
    "#{cookie[:name]}=#{cookie[:value]};path=#{cookie[:path]}"
  end
end
