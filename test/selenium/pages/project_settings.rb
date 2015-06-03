#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class ProjectSettingsPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          #redmine-2.3: controller-projects action-settings
          #redmine-2.6: project-<projectname> controller-projects action-settings
          find_element :css, "body[class~='controller-projects'][class~='action-settings']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/projects/#{project}/settings"
          ProjectSettingsPage.new driver, base_url, project
        end

        def open_members
          ProjectSettingsMembersPage.open @driver, @base_url, @project
        end
      end
    end
  end
end

