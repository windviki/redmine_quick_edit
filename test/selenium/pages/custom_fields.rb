#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class CustomFieldsPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-custom_fields action-index']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/custom_fields/"
          CustomFieldsPage.new driver, base_url, project
        end

        def open_new_page
          CustomFieldNewPage.open @driver, @base_url, @project
        end

        def find_field(name)
          elements = find_elements(:css, 'td > a')
          elements = elements.select do |e|
            e.text == name.to_s
          end

          if elements.empty?
            return nil
          else
            /custom_fields\/(\d+)\// =~ elements[0].attribute('href')
            Regexp.last_match(1)
          end
        end
      end
    end
  end
end

