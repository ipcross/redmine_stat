class VolgaSpotStat < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'VolgaSpotStat'
    establish_connection :phonebase
  end
end
