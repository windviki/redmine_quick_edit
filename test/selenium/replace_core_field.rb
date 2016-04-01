# coding: utf-8

require "json"
require "selenium-webdriver"
$: << File.expand_path('../../', __FILE__)
require 'spec_helper'
Dir[File.dirname(__FILE__) + '/pages/page.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/pages/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each {|file| require file }
require "uri"
require "net/http"
include RSpec::Expectations

describe "Replace core field" do

  before(:all) do
    profile = Selenium::WebDriver::Firefox::Profile.new
    @driver = Selenium::WebDriver.for :firefox, :profile => profile
    @driver.manage.window.maximize
    @base_url = "http://localhost:3000/"
    @driver.manage.timeouts.implicit_wait = 10
    @verification_errors = []
    @default_project = "test"
    @default_user = "admin"
    @default_password = "dummy"

    # open issues page
    start_page = QuickEdit::Test::Pages::StartPage.new(@driver, @base_url, @default_project)
    first_page = start_page.login @default_user, @default_password
    @issues_page = first_page.open_issues

    # create issue for test
    issue_new_page = @issues_page.open_new_page()
    issue_show_page = issue_new_page.create(:bug, 'initial text')
    @issue_id = issue_show_page.id

  end

  before(:each) do
    @issues_page = @issues_page.open_issues
  end
  
  after(:each) do
    expect(@verification_errors).to match_array []
  end
  
  after(:all) do
    @driver.quit
  end
  
  it "subject can replace" do
    new_value = 'NEW text'
    find = 'initial'
    replace = 'NEW'
    match_case = false
    expect( replace(@issue_id, :subject, find, replace, match_case) ).to eq new_value

    # match case test: to lower
    new_value = 'new text'
    find = 'new'
    replace = 'new'
    match_case = true
    expect( replace(@issue_id, :subject, find, replace, match_case) ).to eq new_value

    # special chars test
    new_value = "new<>\'\"&\\+ %text"
    find = ' '
    replace = "<>\'\"&\\+ %"
    match_case = false
    expect( replace(@issue_id, :subject, find, replace, match_case) ).to eq new_value

    # escape test for meta character of regexp pattern
    new_value = "new<>\'\"&\\++ %text"
    find = '\\'
    replace = "\\+"
    match_case = false
    expect( replace(@issue_id, :subject, find, replace, match_case) ).to eq new_value

    find = ''
    replace = ''
    match_case = false
    expect( replace_with_alert(@issue_id, :subject, find, replace, match_case) ).to eq new_value
  end

  it "subject can replace with private note" do
    # initialize
    new_value = 'dummy'
    edit(@issue_id, :subject, new_value)

    # find & replace
    new_value = {:value => 'summy',
                 :notes => {:text => "notes\ntime=" + (Time.now.to_s), :is_private => true}}
    param = {:find => 'd',
             :replace => 's',
             :match_case => false,
             :notes => new_value[:notes]}
    expect( replace(@issue_id, :subject, param) ).to eq new_value[:value]
    expect( latest_note(@issue_id, @issues_page.session_cookie) ).to eq new_value
  end

  def edit(issue_id, attribute_name, new_value)
    quick_edit = @issues_page.open_context(issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    @issues_page = quick_edit.update_field(issue_id, menu_selector, new_value)

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(issue_id, attribute_name)

    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def replace(issue_id, attribute_name, find, replace=nil, match_case=nil)
    quick_edit = @issues_page.open_context(issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    @issues_page = quick_edit.replace(issue_id, menu_selector, find, replace, match_case)

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(issue_id, attribute_name)

    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def replace_with_alert(issue_id, attribute_name, find, replace, match_case)
    quick_edit = @issues_page.open_context(issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    quick_edit.replace(issue_id, menu_selector, find, replace, match_case, true)
    quick_edit.alert.accept
    quick_edit.cancel_quick_edit

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(issue_id, attribute_name)

    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def get_core_field(issue_id, attribute_name)
    json = get_json("issues/#{issue_id}.json")

    json["issue"][attribute_name.to_s]
  end

  def get_json(path)
    uri = URI::parse "#{@base_url}#{path}"
    res = Net::HTTP::get_response(uri)
    JSON.parse(res.body)
  end
  
  
end
