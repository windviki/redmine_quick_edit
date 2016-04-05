#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class MyApiKeyPage < Page
        def initialize(driver, base_url, project, redmine_version)
          super(driver, base_url, project)
          @redmine_version = redmine_version

          if @redmine_version >= 301
            find_element :css, "body[class='controller-my action-show_api_key']"
          else
            find_element :css, "body[class='controller-my action-account']"
          end
        end

        def self.open(driver, base_url, project, redmine_version)
          if redmine_version >= 301
            driver.get "#{base_url}/my/api_key"
            MyApiKeyPage.new driver, base_url, project, redmine_version
          else
            driver.get "#{base_url}/my/account"
            MyApiKeyPage.new driver, base_url, project, redmine_version
          end
        end

        def key
          if @redmine_version >= 301
            find_element(:css, "div.box > pre").text
          else
            find_elements(:css, 'a[href="#"]').select do |e|
              e.text == "Show"
            end.first.click
            find_element(:css, "pre#api-access-key").text
          end
        end
      end
    end
  end
end

