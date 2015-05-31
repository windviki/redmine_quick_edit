#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class CustomFieldNewPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-custom_fields action-new']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/custom_fields/new?type=IssueCustomField"
          CustomFieldNewPage.new driver, base_url, project
        end

        def create(name, format)
          input_text :id, :custom_field_name, name
          select :id, :custom_field_field_format, format

          # check bug tracker
          click :id, 'custom_field_tracker_ids_1'

          # check for all projects
          click :id, 'custom_field_is_for_all'

          # submit
          click :name, 'commit'

          CustomFieldsPage.new @driver, @base_url, @project
        end

      end
    end
  end
end

