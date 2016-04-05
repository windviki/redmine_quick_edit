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

describe "Edit core field" do
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
    helper.page = @issues_page
    helper.base_url = @base_url
    helper.issue_id = @issue_id
  end
  
  after(:each) do
    expect(@verification_errors).to match_array []
  end
  
  after(:all) do
    @driver.quit
  end
  
  it "subject can edit" do
    new_value = 'dummy'
    expect( helper.edit(:subject, new_value) ).to eq new_value

    new_value = 'subject: new_value'
    expect( helper.edit(:subject, new_value) ).to eq new_value

    expect( helper.edit_with_alert(:subject, "") ).to eq new_value
  end

  it "subject can edit with public notes" do
    new_value = {:value => 'subject: with_notes',
                 :notes => {:text => "notes\ntime=" + (Time.now.to_s), :is_private => false}}
    expect( helper.edit( :subject, new_value) ).to eq new_value[:value]
    expect( helper.latest_note ).to eq new_value
  end

  it "subject can edit with private notes" do
    new_value = {:value => 'subject: with_notes',
                 :notes => {:text => "notes\ntime=" + (Time.now.to_s), :is_private => true}}
    expect( helper.edit( :subject, new_value) ).to eq new_value[:value]
    expect( helper.latest_note ).to eq new_value
  end

  it "start_date can edit" do
    new_value = '1900-01-01'
    expect( helper.edit( :start_date, new_value) ).to eq new_value

    new_value = '1900-01-02'
    expect( helper.edit( :start_date, new_value) ).to eq new_value

    invalid_value = '1900-01-0a'
    expect( helper.edit_with_alert( :start_date, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( helper.edit_with_alert( :start_date, invalid_value) ).to eq new_value
  end

  it "due_date can edit" do
    new_value = '2000-01-01'
    expect( helper.edit( :due_date, new_value) ).to eq new_value

    new_value = '2000-01-02'
    expect( helper.edit( :due_date, new_value) ).to eq new_value

    invalid_value = '2000-01-0a'
    expect( helper.edit_with_alert( :due_date, invalid_value) ).to eq new_value

    invalid_value = ''
    expect( helper.edit_with_alert( :due_date, invalid_value) ).to eq new_value
  end

  it "description can edit" do
    new_value = 'dummy'
    expect( helper.edit( :description, new_value) ).to eq new_value

    new_value = 'description: new_value'
    expect( helper.edit( :description, new_value) ).to eq new_value

    expect( helper.edit_with_alert( :description, "") ).to eq new_value
  end

  # unsigned float field
  it "estimated_hours can edit" do
    new_value = '0'
    expect( helper.edit( :estimated_hours, new_value).to_f ).to eq new_value.to_f

    new_value = '0.1'
    expect( helper.edit( :estimated_hours, new_value).to_f ).to eq new_value.to_f

    new_value = '+0.1'
    expect( helper.edit( :estimated_hours, new_value).to_f ).to eq new_value.to_f

    new_value = '0.1e2'
    expect( helper.edit( :estimated_hours, new_value).to_f ).to eq new_value.to_f

    invalid_value = ''
    expect( helper.edit_with_alert( :estimated_hours, invalid_value) ).to eq new_value.to_f
  end

  it "parent_issue_id can edit" do
    issue_ids = @issues_page.issue_ids_on_page
    issue_new_page = @issues_page.open_new_page()
    issue_show_page = issue_new_page.create(:bug, 'first subject')
    helper.issue_id = issue_show_page.id
    helper.page = issue_show_page.open_issues

    new_value = @issue_id.to_s
    expect( helper.edit(:parent_issue_id, new_value) ).to eq new_value.to_i

    invalid_value = ''
    expect( helper.edit_with_alert(:parent_issue_id, invalid_value) ).to eq new_value.to_i

    new_value = @issue_id.to_s
    expect( helper.edit(:parent_issue_id, new_value) ).to eq new_value.to_i
  end

end
