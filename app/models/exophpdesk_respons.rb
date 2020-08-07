class ExophpdeskRespons < ActiveRecord::Base
  unless Rails.env.test?
    self.table_name = 'exophpdesk_responses'
    establish_connection :exophpdesk
  end
  
  def self.count_respons(start,stop)
    ExophpdeskRespons.connection.select_all("select j.id as user_id,
                                            sum( if(t.posted>='#{start}' and t.posted<='#{stop}', 1, 0) ) as respons
                                            from 
                                              #{ExophpdeskRespons.table_name} t, #{ExophpdeskStaff.table_name} j
                                            where 
                                              t.sname=j.username
                                            group by j.id")
  end

  def self.count_respons_each_hour(start,stop)
    ExophpdeskRespons.connection.select_all("select date_format(FROM_UNIXTIME(t.posted),'%Y-%m-%d') as date,
                                              hour(FROM_UNIXTIME(t.posted)) as hour,
                                              count(*) as count
                                            from
                                              #{ExophpdeskRespons.table_name} t
                                            where
                                              t.posted>='#{start}' and t.posted<='#{stop}'
                                            group by
                                              date(FROM_UNIXTIME(t.posted)),hour(FROM_UNIXTIME(t.posted))")
  end
end
