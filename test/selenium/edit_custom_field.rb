# coding: utf-8

require "json"
require "selenium-webdriver"
$: << File.expand_path('../../', __FILE__)
require 'spec_helper'
Dir[File.dirname(__FILE__) + '/pages/page.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/pages/*.rb'].each {|file| require file }
require "uri"
require "net/http"
include RSpec::Expectations

describe "Edit custom field" do

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

    # open issues
    start_page = QuickEdit::Test::Pages::StartPage.new(@driver, @base_url, @default_project)
    first_page = start_page.login @default_user, @default_password
    apikey_page = first_page.open_my_apikey
    @api_key = apikey_page.key
    @issues_page = apikey_page.open_issues

    # get issue id for test
    @issue_id = @issues_page.issue_ids_on_page().first().to_i
  end

  before(:each) do
    if @issues_page.current_user != @default_user
      welcome_page = @issues_page.logout
      start_page = welcome_page.open_login
      first_page = start_page.login(@default_user, @default_password)
      @issues_page = first_page.open_issues
    else
      @issues_page = @issues_page.open_issues
    end
  end
  
  after(:each) do
    expect(@verification_errors).to match_array []
  end
  
  after(:all) do
    @driver.quit
  end
  
  it "custom_text can edit" do
    new_value = 'dummy'
    expect( edit_custom_field(@issue_id, :custom_text, new_value) ).to eq new_value

    new_value = 'custom_text: new_value'
    expect( edit_custom_field(@issue_id, :custom_text, new_value) ).to eq new_value

    invalid_value = ''
    expect( edit_custom_field_with_alert(@issue_id, :custom_text, invalid_value) ).to eq new_value
  end

  it "custom_int can edit" do
    new_value = '0'
    expect( edit_custom_field(@issue_id, :custom_int, new_value) ).to eq new_value

    new_value = '2147483647'
    expect( edit_custom_field(@issue_id, :custom_int, new_value) ).to eq new_value

    new_value = '+10'
    expect( edit_custom_field(@issue_id, :custom_int, new_value).to_i ).to eq new_value.to_i

    new_value = '-10'
    expect( edit_custom_field(@issue_id, :custom_int, new_value).to_i ).to eq new_value.to_i

    invalid_value = 'a'
    expect( edit_custom_field_with_alert(@issue_id, :custom_int, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( edit_custom_field_with_alert(@issue_id, :custom_int, "") ).to eq new_value
  end

  it "custom_date can edit" do
    new_value = '1900-01-01'
    expect( edit_custom_field(@issue_id, :custom_date, new_value) ).to eq new_value

    new_value = '2015-01-01'
    expect( edit_custom_field(@issue_id, :custom_date, new_value) ).to eq new_value

    invalid_value = '2015-01-0a'
    expect( edit_custom_field_with_alert(@issue_id, :custom_date, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( edit_custom_field_with_alert(@issue_id, :custom_date, invalid_value) ).to eq new_value
  end

  it "custom_long can edit" do
    new_value = 'dummy'
    expect( edit_custom_field(@issue_id, :custom_long, new_value) ).to eq new_value

    new_value = 'custom_long: new_value '
    expect( edit_custom_field(@issue_id, :custom_long, new_value) ).to eq new_value

    invalid_value = ''
    expect( edit_custom_field_with_alert(@issue_id, :custom_long, invalid_value) ).to eq new_value
  end

  it "custom_float can edit" do
    new_value = '0'
    expect( edit_custom_field(@issue_id, :custom_float, new_value) ).to eq new_value

    new_value = '0.1'
    expect( edit_custom_field(@issue_id, :custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '+0.1'
    expect( edit_custom_field(@issue_id, :custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '-0.1'
    expect( edit_custom_field(@issue_id, :custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '0.1e2'
    expect( edit_custom_field(@issue_id, :custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '0.1e-2'
    expect( edit_custom_field(@issue_id, :custom_float, new_value).to_f ).to eq new_value.to_f

    invalid_value = ''
    expect( edit_custom_field_with_alert(@issue_id, :custom_float, invalid_value) ).to eq new_value
  end

  it "custom_link can edit" do
    admin_info_page = @issues_page.open_admin_info
    redmine_version = admin_info_page.redmine_version


    if redmine_version >= 205

      @issues_page = admin_info_page.open_issues
  
      new_value = 'dummy'
      expect( edit_custom_field(@issue_id, :custom_link, new_value) ).to eq new_value
  
      new_value = 'custom_link'
      expect( edit_custom_field(@issue_id, :custom_link, new_value) ).to eq new_value
  
      invalid_value = ''
      expect( edit_custom_field_with_alert(@issue_id, :custom_link, invalid_value) ).to eq new_value

    end
  end

  it "readonly field can not edit" do
    welcome_page = @issues_page.logout
    start_page = welcome_page.open_login
    first_page = start_page.login("dev1", "dummy")
    @issues_page = first_page.open_issues

    field_id = select_field(get_custom_field_defs(), :readonly_in_progress)["id"]
    menu_item = @issues_page.find_quick_edit_menu_for_custom_field(@issue_id, field_id)

    expect( menu_item.attribute("class") ).to eq "quick_edit icon-edit disabled"
  end

  def edit_custom_field(issue_id, custom_field_name, new_value)
    cf = select_field(get_custom_field_defs(), custom_field_name)
    cf_id = cf["id"]

    quick_edit = @issues_page.open_context(issue_id)
    menu_selector = quick_edit.menu_selector(:custom_field, cf_id)
    @issues_page = quick_edit.update_field(issue_id, menu_selector, new_value)

    cf = select_field(get_custom_fields(issue_id), custom_field_name)
    cf["value"]
  end

  def edit_custom_field_with_alert(issue_id, custom_field_name, new_value="")
    cf = select_field(get_custom_field_defs(), custom_field_name)
    cf_id = cf["id"]

    quick_edit = @issues_page.open_context(issue_id)
    menu_selector = quick_edit.menu_selector(:custom_field, cf_id)
    quick_edit.update_field(issue_id, menu_selector, new_value, true)
    quick_edit.alert.accept
    quick_edit.cancel_quick_edit

    cf = select_field(get_custom_fields(issue_id), custom_field_name)
    cf["value"]
  end

  def select_field(fields, custom_field_name)
    fields.find do |cf_hash|
      cf_hash["name"] == custom_field_name.to_s
    end
  end

  def get_custom_field_defs
    json = get_json("/custom_fields.json?key=#{@api_key}")

    json["custom_fields"]
  end

  def get_custom_fields(issue_id)
    json = get_json("issues/#{issue_id}.json")

    json["issue"]["custom_fields"]
  end

  def get_json(path)
    uri = URI::parse "#{@base_url}#{path}"
    res = Net::HTTP::get_response(uri)
    JSON.parse(res.body)
  end
  
  
end
