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
  
  it "subject can edit" do
    new_value = 'dummy'
    expect( edit(@issue_id, :subject, new_value) ).to eq new_value

    new_value = 'subject: new_value'
    expect( edit(@issue_id, :subject, new_value) ).to eq new_value

    expect( edit_with_alert(@issue_id, :subject, "") ).to eq new_value
  end

  it "start_date can edit" do
    new_value = '1900-01-01'
    expect( edit(@issue_id, :start_date, new_value) ).to eq new_value

    new_value = '1900-01-02'
    expect( edit(@issue_id, :start_date, new_value) ).to eq new_value

    invalid_value = '1900-01-0a'
    expect( edit_with_alert(@issue_id, :start_date, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( edit_with_alert(@issue_id, :start_date, invalid_value) ).to eq new_value
  end

  it "due_date can edit" do
    new_value = '2000-01-01'
    expect( edit(@issue_id, :due_date, new_value) ).to eq new_value

    new_value = '2000-01-02'
    expect( edit(@issue_id, :due_date, new_value) ).to eq new_value

    invalid_value = '2000-01-0a'
    expect( edit_with_alert(@issue_id, :due_date, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( edit_with_alert(@issue_id, :due_date, invalid_value) ).to eq new_value
  end

  it "description can edit" do
    new_value = 'dummy'
    expect( edit(@issue_id, :description, new_value) ).to eq new_value

    new_value = 'description: new_value'
    expect( edit(@issue_id, :description, new_value) ).to eq new_value

    expect( edit_with_alert(@issue_id, :description, "") ).to eq new_value
  end

  it "parent_issue_id can edit" do
    issue_ids = @issues_page.issue_ids_on_page
    issue_new_page = @issues_page.open_new_page()
    issue_show_page = issue_new_page.create(:bug, 'first subject')
    new_issue_id = issue_show_page.id
    @issues_page = issue_show_page.open_issues

    new_value = @issue_id.to_s
    expect( edit(new_issue_id, :parent_issue_id, new_value) ).to eq new_value.to_i

    invalid_value = ''
    expect( edit_with_alert(new_issue_id, :parent_issue_id, invalid_value) ).to eq new_value.to_i
  end

  def edit(issue_id, attribute_name, new_value)
    @issues_page.quick_edit_for_core_field issue_id, attribute_name, new_value

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(issue_id, attribute_name)

    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def edit_with_alert(issue_id, attribute_name, new_value)
    @issues_page.quick_edit_for_core_field issue_id, attribute_name, new_value, true
    @issues_page.alert.accept
    @issues_page.cancel_quick_edit

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(issue_id, attribute_name)

    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def edit_custom_field(issue_id, custom_field_name, new_value)
    cf = get_custom_field(issue_id, custom_field_name)
    cf_id = cf["id"]

    @issues_page.quick_edit_for_custom_field issue_id, cf_id, new_value

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