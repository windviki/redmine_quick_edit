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

describe "Clear core field" do

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
    issue_show_page = issue_new_page.create(:bug, 'first subject')
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
  
  it "start_date can clear" do
    new_value = '1900-01-01'
    expect( edit(@issue_id, :start_date, new_value) ).to eq new_value

    expect( clear(@issue_id, :start_date) ).to eq nil
  end

  it "start_date can clear with private notes" do
    # before edit
    new_value = '1900-01-01'
    expect( edit(@issue_id, :start_date, new_value) ).to eq new_value

    # clear
    new_value = {:value => :none,
                 :notes => {:text => "notes\ntime=" + (Time.now.to_s), :is_private => true}}
    expect( edit(@issue_id, :start_date, new_value) ).to eq new_value[:value]
    expect( latest_note(@issue_id, @issues_page.session_cookie) ).to eq new_value
  end

  it "due_date can clear" do
    new_value = '2000-01-01'
    expect( edit(@issue_id, :due_date, new_value) ).to eq new_value

    expect( clear(@issue_id, :due_date) ).to eq nil
  end

  it "estimated_hours can clear" do
    new_value = '0'
    expect( edit(@issue_id, :estimated_hours, new_value).to_f ).to eq new_value.to_f

    expect( clear(@issue_id, :estimated_hours) ).to eq nil
  end

  it "parent_issue_id can clear" do
    issue_ids = @issues_page.issue_ids_on_page
    issue_new_page = @issues_page.open_new_page()
    issue_show_page = issue_new_page.create(:bug, 'first subject')
    new_issue_id = issue_show_page.id
    @issues_page = issue_show_page.open_issues

    new_value = @issue_id.to_s
    expect( edit(new_issue_id, :parent_issue_id, new_value) ).to eq new_value.to_i

    expect( clear(new_issue_id, :parent_issue_id) ).to eq nil
  end

  def edit(issue_id, attribute_name, new_value)
    @issues_page.quick_edit_for_core_field issue_id, attribute_name, new_value

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(issue_id, attribute_name)
    field_value = :none if field_value.nil?

    if attribute_name == :parent
      field_value["id"]
    else
      field_value
    end
  end

  def clear(issue_id, attribute_name)
    quick_edit = @issues_page.open_context(issue_id)
    menu_selector = quick_edit.menu_selector(attribute_name)
    @issues_page = quick_edit.clear_field(issue_id, menu_selector)

    attribute_name = :parent if attribute_name.to_sym == :parent_issue_id
    field_value = get_core_field(issue_id, attribute_name)
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
