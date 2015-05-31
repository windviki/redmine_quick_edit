#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class UserNewPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-users action-new']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/users/new"
          UserNewPage.new driver, base_url, project
        end

        def create(username, firstname, lastname, mail, password)
          input_text :id, :user_login, username
          input_text :id, :user_firstname, firstname
          input_text :id, :user_lastname, lastname
          input_text :id, :user_mail, mail
          input_text :id, :user_password, password
          input_text :id, :user_password_confirmation, password
          click :name, :commit
          UserEditPage.new @driver, @base_url, @project
        end
      end
    end
  end
end

