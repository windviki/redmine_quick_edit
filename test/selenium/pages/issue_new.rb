#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class IssueNewPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          #redmine-2.3: controller-issues action-new
          #redmine-2.6: project-projectname controller-issues action-new
          find_element :css, "body[class~='controller-issues'][class~='action-new']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/projects/#{project}/issues/new"
          IssueNewPage.new driver, base_url, project
        end

        def create(tracker, subject)
          select_tracker tracker
          input_text :id, :issue_subject, subject
          click :name, :commit

          IssueShowPage.new @driver, @base_url, @project
        end

        def select_tracker(tracker)
          select :id, :issue_tracker_id, {:bug=>1, :feature=>2, :support=>3}[tracker.to_sym]
        end
      end
    end
  end
end

