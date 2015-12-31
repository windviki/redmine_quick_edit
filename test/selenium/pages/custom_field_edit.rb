#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class CustomFieldEditPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-custom_fields action-edit']"
          /custom_fields\/(\d+)\/edit/ =~ driver.current_url
          @issue_id = $1
        end

        def self.open(driver, base_url, project, issue_id)
          driver.get "#{base_url}/custom_fields/#{issue_id}/edit"
          CustomFieldEditPage.new driver, base_url, project, issue_id
        end
      end
    end
  end
end

