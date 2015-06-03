#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class WorkflowEditPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-workflows action-edit']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/workflows/edit"
          WorkflowEditPage.new driver, base_url, project
        end

        def open_field_permission_page redmine_version
          WorkflowPermissionsPage.open @driver, @base_url, @project, redmine_version
        end

      end
    end
  end
end

