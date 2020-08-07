class ExophpdeskEmergencyCategories < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'exophpdesk_emergency_categories'
    establish_connection :exophpdesk
  end
end