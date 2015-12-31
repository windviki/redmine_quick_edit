#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class MyApiKeyPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-my action-show_api_key']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/my/api_key"
          MyApiKeyPage.new driver, base_url, project
        end

        def key
          find_element(:css, "div.box > pre").text
        end
      end
    end
  end
end

