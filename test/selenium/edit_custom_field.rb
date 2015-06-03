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

describe "Edit" do

  before(:each) do
    profile = Selenium::WebDriver::Firefox::Profile.new
    @driver = Selenium::WebDriver.for :firefox, :profile => profile
    @driver.manage.window.maximize
    @base_url = "http://localhost:3000/"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 10
    @verification_errors = []
    @default_project = "test"
    @default_user = "admin"
    @default_password = "dummy"
    @issue_id = 1
    start_page = QuickEdit::Test::Pages::StartPage.new(@driver, @base_url, @default_project)
    first_page = start_page.login @default_user, @default_password
    @issues_page = first_page.open_issues
    @issue_id = @issues_page.issue_ids_on_page().first().to_i
  end
  
  after(:each) do
    @driver.quit
    expect(@verification_errors).to match_array []
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

    field_id = get_custom_field(@issue_id, :readonly_in_progress)["id"]
    menu_item = @issues_page.find_quick_edit_menu_for_custom_field(@issue_id, field_id)

    expect( menu_item.attribute("class") ).to eq "quick_edit icon-edit disabled"
  end

  def edit(issue_id, attribute_name, new_value)
    @issues_page.quick_edit issue_id, attribute_name, new_value

    field_value = get_core_field(issue_id, attribute_name)
    field_value
  end

  def edit_custom_field(issue_id, custom_field_name, new_value)
    cf = get_custom_field(issue_id, custom_field_name)
    cf_id = cf["id"]

    @issues_page.quick_edit_for_custom_field issue_id, cf_id, new_value

    cf = get_custom_field(issue_id, custom_field_name)
    cf["value"]
  end

  def edit_custom_field_with_alert(issue_id, custom_field_name, new_value="")
    cf = get_custom_field(issue_id, custom_field_name)
    cf_id = cf["id"]

    @issues_page.quick_edit_for_custom_field issue_id, cf_id, new_value, true
    @issues_page.alert.accept
    @issues_page.cancel_quick_edit

    cf = get_custom_field(issue_id, custom_field_name)
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

  def get_json(path)
    uri = URI::parse "#{@base_url}#{path}"
    res = Net::HTTP::get_response(uri)
    JSON.parse(res.body)
  end
  
  
end
