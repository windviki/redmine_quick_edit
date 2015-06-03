#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class Page
        def initialize(driver, base_url, project)
          @driver = driver
          @base_url = base_url
          @project = project
          @default_wait = 0.2
          @retry = 0
          @retry_limit = 2
        end

        def get(url)
          @driver.get url

          wait
        end

        def wait(sec=nil)
          sec = @default_wait if sec.nil?
          sleep sec
        end

        def find_element(by, target)
          @driver.find_element(by, target)
        end

        def find_elements(by, target)
          @driver.find_elements(by, target)
        end

        def input_text(by, target, value)
          wait

          element = find_element(by, target)
          element.clear
          element.send_keys value.to_s unless value.nil? || value.empty?
        end

        def click(by, target)
          wait

          begin
            element = find_element(by, target)
            element.click
            @retry = 0
          rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
            if @retry < @retry_limit
              @retry += 1
              p "+++ retry for click(#{by},#{target})"
              retry
            else
              raise e
            end
          end
        end

        def select(by, target, value)
          wait

          element = find_element(by, target)
          select = Selenium::WebDriver::Support::Select.new(element)
          select.select_by :value, value.to_s
        end

        def selected(by_or_element, target=nil)
          if target.nil?
            element = by_or_element
          else
            element = find_element(by, target)
          end
          select = Selenium::WebDriver::Support::Select.new(element)
          select.selected_options
        end

        def action
          @driver.action
        end

        def alert
          wait 3

          @driver.switch_to.alert
        end

        def open_admin_info
          AdminInfoPage.open @driver, @base_url, @project
        end

        def open_projects
          ProjectsPage.open @driver, @base_url, @project
        end

        def open_users
          UsersPage.open @driver, @base_url, @project
        end

        def open_custom_fields
          CustomFieldsPage.open @driver, @base_url, @project
        end

        def open_workflow_edit
          WorkflowEditPage.open @driver, @base_url, @project
        end

        def open_issues
          IssuesPage.open @driver, @base_url, @project
        end

        def open_login
          StartPage.open @driver, @base_url, @project
        end

        def logout()
          click :css, 'a.logout'

          WelcomePage.new @driver, @base_url, @project
        end
      end
    end
  end
end

