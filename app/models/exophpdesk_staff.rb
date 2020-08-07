class ExophpdeskStaff < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'exophpdesk_staff'
    establish_connection :exophpdesk
  end
end
