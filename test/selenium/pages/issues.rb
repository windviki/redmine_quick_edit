#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class IssuesPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-issues action-index']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/projects/#{project}/issues/"
          IssuesPage.new driver, base_url, project
        end

        def issue_ids_on_page
          issue_elements = find_elements(:css, "tr.issue")
          issue_ids = issue_elements.map do |e|
            #p "find:" + e.attribute("id")
            /issue-(\d+)/ =~ e.attribute("id")
            Regexp.last_match(1)
          end
          issue_ids
        end

        def open_new_page()
          IssueNewPage.open @driver, @base_url, @project
        end

        def open_context(issue_id)
          wait

          element = find_element(:css, "#issue-#{issue_id} > td.subject")
          action.move_to(element).context_click(element).perform
        end

        def quick_edit(issue_id, menu_selector, new_value)
          open_context issue_id

          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).click(menu_item_element).perform

          input_text :id, "new_value", new_value

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click
        end

        def quick_edit_for_core_field(issue_id, attribute_name, new_value, desire_alerting = false)
          menu_selector = "#quick_edit_context_#{attribute_name} > a"

          quick_edit(issue_id, menu_selector, new_value)

          IssuesPage.new @driver, @base_url, @project unless desire_alerting
        end

        def quick_edit_for_custom_field(issue_id, custom_field_id, new_value, desire_alerting = false)
          open_context issue_id

          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, "#quick_edit_context_custom_field_values_#{custom_field_id} > a")

          action.move_to(menu_element).click(menu_item_element).perform

          input_text :id, "new_value", new_value

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click

          IssuesPage.new @driver, @base_url, @project unless desire_alerting
        end

        def cancel_quick_edit
          button_elements = find_elements(:css, 'span.ui-button-text')
          cancel_button = button_elements.select do |button_element|
            button_element.text == 'Cancel'
          end
          cancel_button.first.click
        end
      end
    end
  end
end

