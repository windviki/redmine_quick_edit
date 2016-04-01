#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class IssuesPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          #redmine-2.3: controller-issues action-index
          #redmine-2.6: project-projectname controller-issues action-index
          find_element :css, "body[class~='controller-issues'][class~='action-index']"
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

          QuickEditPage.new @driver, @base_url, @project, self
        end

        def find_quick_edit_menu_for_core_field(issue_id, attribute_name)
          menu_selector = build_menu_selector_for_core_field(attribute_name)

          open_context issue_id

          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          menu_item_element
        end

        def find_quick_edit_menu_for_custom_field(issue_id, custom_field_id)
          menu_selector = build_menu_selector_for_custom_field(custom_field_id)

          open_context issue_id

          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          menu_item_element
        end

        def quick_edit(issue_id, menu_selector, new_value)
          open_context issue_id

          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).click(menu_item_element).perform

          if new_value.is_a?(Hash)
            if new_value[:value] == :none
              click :css, '#quick_edit_input_dialog #clear'
            else
              input_text :id, "new_value", new_value[:value]
            end
            input_text :id, "notes_for_edit", new_value[:notes][:text] unless new_value[:notes].nil?
            click :id, "issue_private_notes_for_edit" if new_value[:notes][:is_private]
          else
            input_text :id, "new_value", new_value
          end

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click
        end

        def quick_edit_clear(issue_id, menu_selector)
          open_context issue_id

          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).click(menu_item_element).perform

          find_element(:css, '#quick_edit_input_dialog #clear').click

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click
        end

        def quick_edit_for_core_field(issue_id, attribute_name, new_value, desire_alerting = false)
          menu_selector = "#quick_edit_context_#{attribute_name} > a"

          quick_edit(issue_id, menu_selector, new_value)

          self.class.open @driver, @base_url, @project unless desire_alerting
        end

        def quick_edit_clear_for_core_field(issue_id, attribute_name)
          menu_selector = build_menu_selector_for_core_field(attribute_name)

          quick_edit_clear(issue_id, menu_selector)

          self.class.open @driver, @base_url, @project
        end

        def quick_edit_clear_for_custom_field(issue_id, custom_field_id)
          menu_selector = build_menu_selector_for_custom_field(custom_field_id)

          quick_edit_clear(issue_id, menu_selector)

          self.class.open @driver, @base_url, @project
        end

        def build_menu_selector_for_core_field(attribute_name)
          "#quick_edit_context_#{attribute_name} > a"
        end

        def build_menu_selector_for_custom_field(custom_field_id)
          "#quick_edit_context_custom_field_values_#{custom_field_id} > a"
        end

        def quick_edit_for_custom_field(issue_id, custom_field_id, new_value, desire_alerting = false)
          menu_selector = build_menu_selector_for_custom_field(custom_field_id)

          open_context issue_id

          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)

          action.move_to(menu_element).click(menu_item_element).perform

          input_text :id, "new_value", new_value

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click

          self.class.open @driver, @base_url, @project unless desire_alerting
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

