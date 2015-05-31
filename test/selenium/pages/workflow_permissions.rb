#coding: utf-8

module QuickEdit
  module Test
    module Pages
      class WorkflowPermissionsPage < Page
        def initialize(driver, base_url, project)
          super(driver, base_url, project)

          find_element :css, "body[class='controller-workflows action-permissions']"
        end

        def self.open(driver, base_url, project)
          driver.get "#{base_url}/workflows/permissions"
          WorkflowPermissionsPage.new driver, base_url, project
        end

        def get_permissions(role_id, tracker, target_state, target_field_ids)
          select :id, :role_id, role_id
          click :css, "input[type='submit']"

          permission_elements = find_elements(:css, 'select[name^=permissions]')

          permissions = {}
          permission_elements.each do |permission_element|
            name = permission_element.attribute("name")
            /permissions\[(.+?)\]\[(\d+)\]/ =~ name
            id = Regexp.last_match(1)
            state = Regexp.last_match(2)

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
              select :name, "permissions[#{k}][#{state}]", permission
            end
          end
          click :name, :commit

          WorkflowPermissionsPage.new @driver, @base_url, @project
        end

      end
    end
  end
end

