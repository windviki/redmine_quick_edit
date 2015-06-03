#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class ProjectSettingsMembersPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          #redmine-2.3: controller-projects action-settings
          #redmine-2.6: project-<projectname> controller-projects action-settings
          find_element :css, "body[class~='controller-projects'][class~='action-settings']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/projects/#{project}/settings/members"
          ProjectSettingsMembersPage.new driver, base_url, project
        end

        def find_role(user_id)
          begin
            pnodata = find_element(:css, "p.nodata")
            if pnodata.displayed?
              return nil
            end
          rescue Selenium::WebDriver::Error::NoSuchElementError
            # next
          end

          member_elements = find_elements(:css, "tr.member")
          target_tr = member_elements.select do | element |
            e = element.find_element(:css, "td.user > a.user")
            href = e.attribute("href")
            /\/users\/(\d+)/ =~ href
            id = Regexp.last_match(1)

            id.to_i == user_id.to_i
          end

          if target_tr.empty?
            nil
          else
            target_tr.first.find_element(:css, "td.roles > span").text
          end
        end

        def add(user_id, role_id, redmine_version)
          if redmine_version >= 300
            click :css, "a[href$='/memberships/new']"
          end

          membership_elements = find_elements(:css, 'input[name^=membership]')
          userid_elements = membership_elements.select do |membership_element|
            name = membership_element.attribute("name")
            /membership\[user_ids\]\[\]/ =~ name
          end

          userid_element = userid_elements.select do |userid_element|
            value = userid_element.attribute("value")
            value.to_i() == user_id.to_i()
          end

          userid_element.first.click

          roleid_elements = membership_elements.select do |membership_element|
            name = membership_element.attribute("name")
            /membership\[role_ids\]\[\]/ =~ name
          end

          roleid_element = roleid_elements.select do |roleid_element|
            value = roleid_element.attribute("value")
            value.to_i == role_id.to_i
          end

          roleid_element.first.click

          click :id, "member-add-submit"

          ProjectSettingsMembersPage.new @driver, @base_url, @project
        end
      end
    end
  end
end

