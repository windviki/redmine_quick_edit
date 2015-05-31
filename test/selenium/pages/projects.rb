#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class ProjectsPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-projects action-index']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/projects"
          ProjectsPage.new driver, base_url, project
        end

        def open_new_page
          ProjectNewPage.open @driver, @base_url, @project
        end

        def open_settings_page(project)
          ProjectSettingsPage.open @driver, @base_url, project
        end
      end
    end
  end
end

