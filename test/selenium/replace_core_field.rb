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
    issue_show_page = issue_new_page.create(:bug, 'initial text')
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
  
  it "subject can replace" do
    new_value = 'NEW text'
    params = {
      :find => 'initial',
      :replace => 'NEW',
      :match_case => false
    }
    expect( helper.replace(:subject, params) ).to eq new_value

    # match case test: to lower
    new_value = 'new text'
    params = {
      :find => 'new',
      :replace => 'new',
      :match_case => true
    }
    expect( helper.replace(:subject, params) ).to eq new_value

    # special chars test
    new_value = "new<>\'\"&\\+ %text"
    params = {
      :find => ' ',
      :replace => "<>\'\"&\\+ %",
      :match_case => false
    }
    expect( helper.replace(:subject, params) ).to eq new_value

    # escape test for meta character of regexp pattern
    new_value = "new<>\'\"&\\++ %text"
    params = {
      :find => '\\',
      :replace => "\\+",
      :match_case => false
    }
    expect( helper.replace(:subject, params) ).to eq new_value

    params = {
      :find => '',
      :replace => '',
      :match_case => false
    }
    expect( helper.replace_with_alert(:subject, params) ).to eq new_value
  end

  it "subject can replace with private note" do
    # initialize
    new_value = 'dummy'
    helper.edit(:subject, new_value)

    # find & replace
    new_value = {:value => 'summy',
                 :notes => {:text => "notes\ntime=" + (Time.now.to_s), :is_private => true}}
    params = {:find => 'd',
             :replace => 's',
             :match_case => false,
             :notes => new_value[:notes]}
    expect( helper.replace(:subject, params) ).to eq new_value[:value]
    expect( helper.latest_note ).to eq new_value
  end
  
end
