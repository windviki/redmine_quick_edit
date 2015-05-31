#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class ProjectNewPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-projects action-new']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/projects/new"
          ProjectNewPage.new driver, base_url, project
        end

        def create(id, name)
          input_text :id, 'project_name', name
          input_text :id, 'project_identifier', id
          click :name, 'commit'

          ProjectSettingsPage.new @driver, @base_url, @project
        end

      end
    end
  end
end

