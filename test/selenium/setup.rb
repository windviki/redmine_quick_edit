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
    start_page = QuickEdit::Test::Pages::StartPage.new(@driver, @base_url, @default_project)
    @first_page = start_page.login @default_user, @default_password
  end
  
  after(:each) do
    @driver.quit
    expect(@verification_errors).to match_array []
  end

  it "setup project" do
    json = get_json("projects.json")
    test_project = json["projects"].select do |project|
       project["name"] == "test"
    end
    if test_project.empty?
      projects_page = @first_page.open_projects
      project_new_page = projects_page.open_new_page
      project_settings_page = project_new_page.create @default_project, @default_project
    end
  end

  it "setup issues" do
    issues_page = @first_page.open_issues
    issue_ids = issues_page.issue_ids_on_page
    if issue_ids.empty?
      issue_new_page = issues_page.open_new_page()
      issue_show_page = issue_new_page.create(:bug, 'first subject')
      @issue_id = issue_show_page.id
    else
      @issue_id = issue_ids.first
    end
  end

  it "setup custom fields" do
    admin_info_page = @first_page.open_admin_info
    redmine_version = admin_info_page.redmine_version

    custom_fields_page = admin_info_page.open_custom_fields
    id = custom_fields_page.find_field(:custom_text)
    if id.nil?
      new_page = custom_fields_page.open_new_page
      custom_fields_page = new_page.create :custom_text, :string
    end

    id = custom_fields_page.find_field(:custom_long)
    if id.nil?
      new_page = custom_fields_page.open_new_page
      custom_fields_page = new_page.create :custom_long, :text
    end

    id = custom_fields_page.find_field(:custom_int)
    if id.nil?
      new_page = custom_fields_page.open_new_page
      custom_fields_page = new_page.create :custom_int, :int
    end

    id = custom_fields_page.find_field(:custom_float)
    if id.nil?
      new_page = custom_fields_page.open_new_page
      custom_fields_page = new_page.create :custom_float, :float
    end

    id = custom_fields_page.find_field(:custom_date)
    if id.nil?
      new_page = custom_fields_page.open_new_page
      custom_fields_page = new_page.create :custom_date, :date
    end

    id = custom_fields_page.find_field(:readonly_in_progress)
    if id.nil?
      new_page = custom_fields_page.open_new_page
      custom_fields_page = new_page.create :readonly_in_progress, :string
    end

    if redmine_version >= 205
      id = custom_fields_page.find_field(:custom_link)
      if id.nil?
        new_page = custom_fields_page.open_new_page
        custom_fields_page = new_page.create :custom_link, :link
      end
    end
  end

  it "setup users" do
    users_page = @first_page.open_users
    rep_user_id = users_page.find_user("rep1")
    if rep_user_id.nil?
      user_new_page = users_page.open_new_page
      user_edit_page = user_new_page.create("rep1", "1", "rep", "rep1@localhost.com", "dummy")
    end
  end

  it "setup roles" do
    users_page = @first_page.open_users
    rep_user_id = users_page.find_user("rep1")

    projects_page = users_page.open_projects
    project_page = projects_page.open_settings_page(@default_project)
    members_page = project_page.open_members
    role_name = members_page.find_role(rep_user_id)
    #p role_name
    if role_name.nil?
      reporter_role_id = 5 #reporter_role_id
      members_page = members_page.add rep_user_id, reporter_role_id
      members_page.find_role(rep_user_id)
    end
  end

  it "setup permissions" do
    role_reporter = "5" #reporter
    tracker_bug = "1" #bug
    state_new = "1" #new
    custom_field_readonly = get_custom_field(sampling_issue_id(), :readonly_in_progress)["id"].to_s
    #p "readonly in progress's id = #{custom_field_readonly}"

    admin_info_page = @first_page.open_admin_info
    redmine_version = admin_info_page.redmine_version

    workflow_edit_page = admin_info_page.open_workflow_edit
    permission_page = workflow_edit_page.open_field_permission_page redmine_version
    permissions = permission_page.get_permissions(role_reporter, tracker_bug, state_new, [custom_field_readonly])
    #p permissions.inspect

    permission = permissions[custom_field_readonly][state_new]
    if permission.nil? || permission != "readonly"
      permissions = { custom_field_readonly => {state_new => "readonly"} }
      permission_page.update role_reporter, tracker_bug, permissions
    end
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

  def sampling_issue_id()
    get_issues().first()["id"]
  end

  def get_issues()
    json = get_json("issues.json")

    json["issues"]
  end

  def get_json(path)
    uri = URI::parse "#{@base_url}#{path}"
    res = Net::HTTP::get_response(uri)
    JSON.parse(res.body)
  end
  
end
