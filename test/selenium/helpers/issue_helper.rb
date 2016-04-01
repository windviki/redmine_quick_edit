
# coding: utf-8

require "nokogiri"
require "uri"
require "net/http"

  def latest_note(issue_id, session_cookie)
    result = {:value => nil, :notes => {:text => nil, :is_private => nil}}

    feed = get_feed("issues/#{issue_id}.atom", session_cookie).css("entry")
    feed_limitted = get_feed("issues/#{issue_id}.atom").css("entry")

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
