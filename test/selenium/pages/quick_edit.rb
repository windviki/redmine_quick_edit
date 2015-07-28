#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class QuickEditPage < Page
        def initialize(driver, base_url, project, before_page)
          super(driver, base_url, project)

          @before_page = before_page

          find_element :id, "quick_edit_context"
        end

        def view_menu_item(issue_id, menu_selector)
          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).perform

          find_element(:css, menu_selector)
        end

        def update_field(issue_id, menu_selector, new_value, desire_alerting = false)
          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).click(menu_item_element).perform

          input_text :id, "new_value", new_value

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click

          @before_page.class.open @driver, @base_url, @project unless desire_alerting
        end

        def clear_field(issue_id, menu_selector)
          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).click(menu_item_element).perform

          find_element(:css, '#quick_edit_input_dialog #clear').click

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click

          @before_page.class.open @driver, @base_url, @project
        end

        def preview_replace(issue_id, menu_selector, find_value, replace_value, match_case, desire_alerting = false)
          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).click(menu_item_element).perform

          click :id, :replace_switcher

          input_text :id, :find, find_value
          input_text :id, :replace, replace_value
          click :id, :match_case if match_case

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Preview/}
          submit_button.first.click

          @before_page.class.open @driver, @base_url, @project unless desire_alerting
        end

        def get_replace_preview()
          rows = find_elements(:css, "preview_area tbody tr")

          previews = rows.map do |row|
            id = row.find_element(:class, ".id").text
            old = row.find_element(:class, ".old").text
            new = row.find_element(:class, ".new").text
            { :id => id, :old => old, :new => new }
          end
        end

        def replace(issue_id, menu_selector, find_value, replace_value, match_case, desire_alerting = false)
          menu_element = find_element(:id, "quick_edit_context")
          menu_item_element = find_element(:css, menu_selector)
          action.move_to(menu_element).click(menu_item_element).perform

          click :id, :replace_switcher

          input_text :id, :find, find_value
          input_text :css, "#quick_edit_input_dialog #replace", replace_value
          click :id, :match_case if match_case

          buttons = find_elements(:css, "button > span")
          submit_button = buttons.select {|button| button.text =~ /Submit/}
          submit_button.first.click

          alert.accept unless desire_alerting

          @before_page.class.open @driver, @base_url, @project unless desire_alerting
        end

        def cancel_quick_edit
          button_elements = find_elements(:css, 'span.ui-button-text')
          cancel_buttons = button_elements.select do |button_element|
            button_element.text == 'Cancel'
          end
          cancel_button = cancel_buttons.first
          cancel_button.click

#          new Selenium::WebDriver::Wait.new().until {
#            !cancel_button.displayed?
#          }
        end

        def menu_selector(attribute_name, custom_field_id=nil)
          if :custom_field == attribute_name.to_sym
            "#quick_edit_context_custom_field_values_#{custom_field_id} > a"
          else
            "#quick_edit_context_#{attribute_name} > a"
          end
        end
      end
    end
  end
end

