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

describe "Clear custom field" do
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
    helper.page = @issues_page
    helper.base_url = @base_url
    helper.issue_id = @issue_id
    helper.api_key = @api_key
  end
  
  after(:each) do
    expect(@verification_errors).to match_array []
  end
  
  after(:all) do
    @driver.quit
  end
  
  it "custom_text can clear" do
    new_value = 'dummy'
    expect( helper.edit_custom_field(:custom_text, new_value) ).to eq new_value

    expect( helper.clear_custom_field(:custom_text) ).to eq ''
  end

  it "custom_int can clear" do
    new_value = '0'
    expect( helper.edit_custom_field(:custom_int, new_value) ).to eq new_value

    expect( helper.clear_custom_field(:custom_int) ).to eq ''
  end

  it "custom_date can clear" do
    new_value = '1900-01-01'
    expect( helper.edit_custom_field(:custom_date, new_value) ).to eq new_value

    expect( helper.clear_custom_field(:custom_date) ).to eq ''
  end

  it "custom_long can clear" do
    new_value = 'dummy'
    expect( helper.edit_custom_field(:custom_long, new_value) ).to eq new_value

    expect( helper.clear_custom_field(:custom_long) ).to eq ''
  end

  it "custom_float can clear" do
    new_value = '0'
    expect( helper.edit_custom_field(:custom_float, new_value) ).to eq new_value

    expect( helper.clear_custom_field(:custom_float) ).to eq ''
  end

  it "custom_link can clear" do
    admin_info_page = @issues_page.open_admin_info
    redmine_version = admin_info_page.redmine_version

    if redmine_version >= 205

      @issues_page = admin_info_page.open_issues
  
      new_value = 'dummy'
      expect( helper.edit_custom_field(:custom_link, new_value) ).to eq new_value
  
      expect( helper.clear_custom_field(:custom_link) ).to eq ''
    end
  end
  
end
