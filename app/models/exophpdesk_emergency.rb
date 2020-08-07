class ExophpdeskEmergency < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'exophpdesk_emergencies'
    establish_connection :exophpdesk
  end
end