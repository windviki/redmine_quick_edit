#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class UsersPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-users action-index']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/users"
          UsersPage.new driver, base_url, project
        end

        def open_new_page
          UserNewPage.open @driver, @base_url, @project
        end

        def open_user_page(user_id)
          UserShowPage.open @driver, @base_url, @project, user_id
        end


        def find_user(username)
          elements = find_elements(:css, "tr.user>td>a")
          users = elements.select do |u|
            u.text == username.to_s
          end

          if users.empty?
            return nil
          else
            url = users.first.attribute("href")
            /users\/(\d+)\/edit/ =~ url
            return Regexp.last_match(1)
          end
        end
      end
    end
  end
end

