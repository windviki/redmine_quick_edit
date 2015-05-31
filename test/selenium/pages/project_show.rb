#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class ProjectShowPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-projects action-show']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/projects/#{project}"
          ProjectShowPage.new driver, base_url, project
        end
      end
    end
  end
end

