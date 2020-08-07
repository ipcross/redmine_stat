class ExophpdeskEmergencyStat < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'exophpdesk_emergency_stat'
    establish_connection :exophpdesk
  end

  class << self
    def instance_method_already_implemented?(method_name)
      return true if method_name == 'update'
      super
    end
  end

  def self.count_for_forum(start, stop, group)
    query = "select r.reason as reason, count(*) as count, sum( s.drive_mnt ) as drive
         from #{ExophpdeskEmergencyStat.table_name} as s
         join #{ExophpdeskTicket.table_name} as t ON s.task_id = t.id
         join #{ExophpdeskEmergency.table_name} as r ON s.reason_id = r.id
         where t.group = '#{group}' and s.date between '#{start}' and '#{stop}'
         group by r.reason order by r.reason
        "
    ExophpdeskEmergencyStat.connection.select_all query
  end

  def self.count_for_forum_by_categories(start, stop, category)
    query = "select r.reason as reason, count(*) as count, sum( s.drive_mnt ) as drive
         from #{ExophpdeskEmergencyStat.table_name} as s
         join #{ExophpdeskTicket.table_name} as t ON s.task_id = t.id
         join #{ExophpdeskEmergency.table_name} as r ON s.reason_id = r.id
         join #{ExophpdeskEmergencyCategories.table_name} as q ON r.category_id = q.id
         where q.category = '#{category}' and s.date between '#{start}' and '#{stop}'
         group by r.reason order by r.reason
        "
    ExophpdeskEmergencyStat.connection.select_all query
  end
end
