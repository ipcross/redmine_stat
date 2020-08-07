class CallDataRecord < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'cdr'
    establish_connection :phonebase
  end
end
