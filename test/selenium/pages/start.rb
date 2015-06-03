#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class StartPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          get "#{base_url}/login"
          find_element :id, "username"
        end

        def self.open(driver, base_url, project)
          StartPage.new driver, base_url, project
        end

        def login(login_id, password)
          input_text :id, "username", login_id
          input_text :id, "password", password
          click :name, "login"

          MyPage.new @driver, @base_url, @project
        end
      end
    end
  end
end

