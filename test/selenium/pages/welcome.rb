#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class WelcomePage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-welcome action-index']"
        end
      end
    end
  end
end

