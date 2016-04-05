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

describe "Edit custom field" do
  let(:helper) { TestHelper.new }

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
    admin_info_page = first_page.open_admin_info
    apikey_page = admin_info_page.open_my_apikey(admin_info_page.redmine_version)
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
    helper.base_url = @base_url
    helper.page = @issues_page
    helper.issue_id = @issue_id
    helper.api_key = @api_key
  end
  
  after(:each) do
    expect(@verification_errors).to match_array []
  end
  
  after(:all) do
    @driver.quit
  end
  
  it "custom_text can edit" do
    new_value = 'dummy'
    expect( helper.edit_custom_field(:custom_text, new_value) ).to eq new_value

    new_value = 'custom_text: new_value'
    expect( helper.edit_custom_field(:custom_text, new_value) ).to eq new_value

    invalid_value = ''
    expect( helper.edit_custom_field_with_alert(:custom_text, invalid_value) ).to eq new_value
  end

  it "custom_int can edit" do
    new_value = '0'
    expect( helper.edit_custom_field(:custom_int, new_value) ).to eq new_value

    new_value = '2147483647'
    expect( helper.edit_custom_field(:custom_int, new_value) ).to eq new_value

    new_value = '+10'
    expect( helper.edit_custom_field(:custom_int, new_value).to_i ).to eq new_value.to_i

    new_value = '-10'
    expect( helper.edit_custom_field(:custom_int, new_value).to_i ).to eq new_value.to_i

    invalid_value = 'a'
    expect( helper.edit_custom_field_with_alert(:custom_int, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( helper.edit_custom_field_with_alert(:custom_int, "") ).to eq new_value
  end

  it "custom_date can edit" do
    new_value = '1900-01-01'
    expect( helper.edit_custom_field(:custom_date, new_value) ).to eq new_value

    new_value = '2015-01-01'
    expect( helper.edit_custom_field(:custom_date, new_value) ).to eq new_value

    invalid_value = '2015-01-0a'
    expect( helper.edit_custom_field_with_alert(:custom_date, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( helper.edit_custom_field_with_alert(:custom_date, invalid_value) ).to eq new_value
  end

  it "custom_long can edit" do
    new_value = 'dummy'
    expect( helper.edit_custom_field(:custom_long, new_value) ).to eq new_value

    new_value = 'custom_long: new_value '
    expect( helper.edit_custom_field(:custom_long, new_value) ).to eq new_value

    invalid_value = ''
    expect( helper.edit_custom_field_with_alert(:custom_long, invalid_value) ).to eq new_value
  end

  it "custom_float can edit" do
    new_value = '0'
    expect( helper.edit_custom_field(:custom_float, new_value) ).to eq new_value

    new_value = '0.1'
    expect( helper.edit_custom_field(:custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '+0.1'
    expect( helper.edit_custom_field(:custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '-0.1'
    expect( helper.edit_custom_field(:custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '0.1e2'
    expect( helper.edit_custom_field(:custom_float, new_value).to_f ).to eq new_value.to_f

    new_value = '0.1e-2'
    expect( helper.edit_custom_field(:custom_float, new_value).to_f ).to eq new_value.to_f

    invalid_value = ''
    expect( helper.edit_custom_field_with_alert(:custom_float, invalid_value) ).to eq new_value
  end

  it "custom_link can edit" do
    admin_info_page = helper.page.open_admin_info
    redmine_version = admin_info_page.redmine_version


    if redmine_version >= 205

      helper.page = admin_info_page.open_issues
  
      new_value = 'dummy'
      expect( helper.edit_custom_field(:custom_link, new_value) ).to eq new_value
  
      new_value = 'custom_link'
      expect( helper.edit_custom_field(:custom_link, new_value) ).to eq new_value
  
      invalid_value = ''
      expect( helper.edit_custom_field_with_alert(:custom_link, invalid_value) ).to eq new_value

    end
  end

  it "readonly field can not edit" do
    welcome_page = helper.page.logout
    start_page = welcome_page.open_login
    first_page = start_page.login("dev1", "dummy")
    @issues_page = helper.page = first_page.open_issues

    field_id = helper.select_field(helper.get_custom_field_defs(), :readonly_in_progress)["id"]
    menu_item = helper.page.find_quick_edit_menu_for_custom_field(helper.issue_id, field_id)

    expect( menu_item.attribute("class") ).to eq "quick_edit icon-edit disabled"
  end
  
end
