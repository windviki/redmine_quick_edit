#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class IssueShowPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-issues action-show']"
        end

        def self.open(driver, base_url, project, issue_id)
          driver.get "#{base_url}/projects/#{project}/issues/#{issue_id}"
          IssueShowPage.new driver, base_url, project, issue_id
        end

        def id
          url = @driver.current_url
          /\/(\d+)$/ =~ url
          Regexp.last_match(1)
        end

        def subject
          find_element :css, "div.subject h3"
        end

        def start_date
          find_element :css, "td.start-date"
        end

        def due_date
          find_element :css, "td.due-date"
        end
 
        def description
          find_element :css, "div.description > div.wiki > p"
        end
      end
    end
  end
end

