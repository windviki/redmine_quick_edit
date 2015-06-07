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

describe "Clear custom field" do

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
    @issues_page = first_page.open_issues

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

    expect( clear_custom_field(@issue_id, :custom_text) ).to eq ''
  end

  it "custom_int can edit" do
    new_value = '0'
    expect( edit_custom_field(@issue_id, :custom_int, new_value) ).to eq new_value

    expect( clear_custom_field(@issue_id, :custom_int) ).to eq ''
  end

  it "custom_date can edit" do
    new_value = '1900-01-01'
    expect( edit_custom_field(@issue_id, :custom_date, new_value) ).to eq new_value

    expect( clear_custom_field(@issue_id, :custom_date) ).to eq ''
  end

  it "custom_long can edit" do
    new_value = 'dummy'
    expect( edit_custom_field(@issue_id, :custom_long, new_value) ).to eq new_value

    expect( clear_custom_field(@issue_id, :custom_long) ).to eq ''
  end

  it "custom_float can edit" do
    new_value = '0'
    expect( edit_custom_field(@issue_id, :custom_float, new_value) ).to eq new_value

    expect( clear_custom_field(@issue_id, :custom_float) ).to eq ''
  end

  it "custom_link can edit" do
    admin_info_page = @issues_page.open_admin_info
    redmine_version = admin_info_page.redmine_version

    if redmine_version >= 205

      @issues_page = admin_info_page.open_issues
  
      new_value = 'dummy'
      expect( edit_custom_field(@issue_id, :custom_link, new_value) ).to eq new_value
  
      expect( clear_custom_field(@issue_id, :custom_link) ).to eq ''
    end
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

  def clear_custom_field(issue_id, custom_field_name)
    cf = get_custom_field(issue_id, custom_field_name)
    cf_id = cf["id"]

    @issues_page.quick_edit_clear_for_custom_field issue_id, cf_id

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
