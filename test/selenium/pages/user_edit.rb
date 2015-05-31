#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class UserEditPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-users action-edit']"
        end

        def self.open(driver, base_url, project, user_id)
          driver.get "#{base_url}/users/#{user_id}/edit"
          UserEditPage.new driver, base_url, project
        end

        def id
          url = @driver.getCurrentUrl()
          /users\/(\d+)\/edit/ =~ url
          Regexp.last_match(1)
        end
      end
    end
  end
end

