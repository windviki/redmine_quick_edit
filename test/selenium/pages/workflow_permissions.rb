#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class WorkflowPermissionsPage < Page
        def initialize(driver, base_url, project, redmine_version)
          super(driver, base_url, project)
          @redmine_version = redmine_version

          find_element :css, "body[class='controller-workflows action-permissions']"
        end

        def self.open(driver, base_url, project, redmine_version)
          driver.get "#{base_url}/workflows/permissions"
          WorkflowPermissionsPage.new driver, base_url, project, redmine_version
        end

        def get_permissions(role_id, tracker, target_state, target_field_ids)
          select :id, :role_id, role_id
          click :css, "input[type='submit']"

          permission_elements = find_elements(:css, 'select[name^=permissions]')

          permissions = {}
          permission_elements.each do |permission_element|
            name = permission_element.attribute("name")
            parsed_name = parse_html_name(name)
            id = parsed_name[0]
            state = parsed_name[1]

            if state == target_state && target_field_ids.include?(id)
              permissions[id] = { state => selected(permission_element).first.attribute("value") }
            end
          end

          target_field_ids.each do |id|
            unless permissions.has_key? id
              permissions[id] = {}
            end
          end

          permissions
        end

        def update(role_id, tracker, permissions)
          select :id, :role_id, role_id
          click :css, "input[type='submit']"

          find_elements :class, :fields_permissions

          permissions.each do |k,v| 
            v.each do |state, permission|
              select :name, build_html_name(k,state), permission
            end
          end
          click :name, :commit

          WorkflowPermissionsPage.new @driver, @base_url, @project, @redmine_version
        end

        def parse_html_name(name)
          /permissions\[(.+?)\]\[(\d+)\]/ =~ name
          if @redmine_version < 205
            id = Regexp.last_match(1)
            state = Regexp.last_match(2)
          else
            id = Regexp.last_match(2)
            state = Regexp.last_match(1)
          end

          [id, state]
        end

        def build_html_name(id, state)
          if @redmine_version < 205
            "permissions[#{id}][#{state}]"
          else
            "permissions[#{state}][#{id}]"
          end
        end
      end
    end
  end
end

