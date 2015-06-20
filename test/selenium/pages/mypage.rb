#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class MyPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-my action-page']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/my/page"
          MyPage.new driver, base_url, project
        end

        def issue_ids_on_page
          issues = find_elements(:css, 'tr.issue')
          ids = issues.map do |issue_element|
            element_id = issue_element.attribute("id")
            /issue-(\d+)/ =~ element_id
            Regexp.last_match(1)
          end

          ids
        end

        def open_context(issue_id)
          wait

          element = find_element(:css, "#issue-#{issue_id} > td.subject")
          action.move_to(element).context_click(element).perform

          QuickEditPage.new @driver, @base_url, @project, self
        end
      end
    end
  end
end

