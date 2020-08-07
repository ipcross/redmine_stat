class ExophpdeskTicket < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'exophpdesk_tickets'
    establish_connection :exophpdesk
  end
  
  class << self
    def instance_method_already_implemented?(method_name)
      return true if method_name == 'update'
      super
    end
  end

  def self.count_for_forum(start,stop)
    ExophpdeskTicket.connection.select_all("select j.id as user_id,
                                            sum( if(t.opened>='#{start}' and t.opened<='#{stop}' and t.admin_user=j.username, 1, 0) ) as created,
                                            sum( if(t.status='Open' and t.owner=j.username, 1, 0) ) as total_assigned_open,
                                            sum( if(t.assigned>='#{start}' and t.assigned<='#{stop}' and t.owner=j.username, 1, 0) ) as assigned,
                                            sum( if(t.status='Closed' and t.update>='#{start}' and t.update<='#{stop}' and t.update_user=j.username, 1, 0) ) as closed
                                            from
                                              #{ExophpdeskTicket.table_name} t, #{ExophpdeskStaff.table_name} j
                                            where
                                              j.is_actual = 1
                                            group by j.id")
  end

  def self.count_opened_tickets_each_hour(start,stop)
    ExophpdeskTicket.connection.select_all("select date_format(FROM_UNIXTIME(t.opened),'%Y-%m-%d') as date,
                                              hour(FROM_UNIXTIME(t.opened)) as hour,
                                              count(*) as count
                                            from
                                              #{ExophpdeskTicket.table_name} t
                                            where
                                              t.opened>='#{start}' and t.opened<='#{stop}'
                                            group by
                                              date(FROM_UNIXTIME(t.opened)),hour(FROM_UNIXTIME(t.opened))")
  end

  def self.count_assigned_tickets_each_hour(start,stop)
    ExophpdeskTicket.connection.select_all("select date_format(FROM_UNIXTIME(t.assigned),'%Y-%m-%d') as date,
                                              hour(FROM_UNIXTIME(t.assigned)) as hour,
                                              count(*) as count
                                            from
                                              #{ExophpdeskTicket.table_name} t
                                            where
                                              t.assigned>='#{start}' and t.assigned<='#{stop}'
                                            group by
                                              date(FROM_UNIXTIME(t.assigned)),hour(FROM_UNIXTIME(t.assigned))")
  end

  def self.count_closed_tickets_each_hour(start,stop)
    ExophpdeskTicket.connection.select_all("select date_format(FROM_UNIXTIME(t.update),'%Y-%m-%d') as date,
                                              hour(FROM_UNIXTIME(t.update)) as hour,
                                              count(*) as count
                                            from
                                              #{ExophpdeskTicket.table_name} t
                                            where
                                              t.update>='#{start}' and t.update<='#{stop}' and t.status='Closed'
                                            group by
                                              date(FROM_UNIXTIME(t.update)),hour(FROM_UNIXTIME(t.update))")
  end


#waiting for fast api
  def self.get_tickets_by_api(date_start,date_stop)
    HTTParty.get("http://vs.vgg.ru/api/v2r/helpdesk/tickets/all?filter[]=
      [%22between%22,%opened%22,#{@date_range.date_start.beginning_of_day.to_i},#{@date_range.date_stop.end_of_day.to_i}]").count
  end

  def self.stat_count(date_start,date_stop)
    ExophpdeskTicket.connection.select_all("SELECT opened,closed_at,assigned
                                            FROM #{ExophpdeskTicket.table_name}
                                            WHERE closed_at != 0
                                            AND assigned != 0
                                            AND opened
                                            BETWEEN #{date_start} AND #{date_stop}")
  end

  def self.stat_for_longrunning_tickets(date_start,date_stop)
    ExophpdeskTicket.connection.select_all("SELECT id,owner,title,opened,#{ExophpdeskTicket.table_name}.group
                                            FROM #{ExophpdeskTicket.table_name}
                                            WHERE status != \"Closed\"
                                            AND owner != \"\"
                                            AND closed_at = 0
                                            AND opened
                                            BETWEEN #{date_start} AND #{date_stop}")
  end
end
