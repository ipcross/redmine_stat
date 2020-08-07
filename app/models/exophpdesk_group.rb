class ExophpdeskGroup < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'exophpdesk_groups'
    establish_connection :exophpdesk
  end
end
