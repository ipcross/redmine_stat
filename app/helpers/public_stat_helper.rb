module PublicStatHelper
  include ReportsHelper

  def current_group_name
      if session[:statistics_group]
        Group.find(session[:statistics_group]).name
      else
        Group.find(19).name
      end
  end

  def aggregate_path_stat_report(field, row, options={})
    parameters = {:set_filter => 1, field => row.id}.merge(options)
    issues_path(parameters)
  end

  def cached_calls_incoming(cal, user)
    if user.phone.present?
      a = user.phone.split(",").first
      calls = cal.where(destination: a)
      duration = calls.sum("duration").to_f/60
      if calls.count > 0
        average = duration.round(2) / calls.count
      else
        average = 0
      end
      [duration.round(2), calls.count, average]
    else
      [0, 0, 0]
    end
  end

  def cached_calls_outcoming(cal, user)
    if user.phone.present?
      calls = cal.where(source: user.phone.split(",").first)
      duration = calls.sum("duration").to_f/60
      if calls.count > 0
        average = duration.round(2) / calls.count
      else
        average = 0
      end
      [duration.round(2), calls.count, average]
    else
      [0, 0, 0]
    end
  end

    def aggregate_calls_incoming(cal, user)
    if user.phone.present?
      a = user.phone.split(",").first
      user_calls = cal.where("dstchannel REGEXP ?", "SIP\/#{a}-[0-9a-z]{8}$").where(disposition: 'ANSWERED')
      user_calls_from_internal = cal.where("dstchannel REGEXP ?", "Local\/FMPR\-#{a}\@from\-internal*").where(disposition: 'ANSWERED')
      count_calls = user_calls.count + user_calls_from_internal.count
      duration = user_calls.sum("duration").to_f/60 + user_calls_from_internal.sum("duration").to_f/60
      if count_calls > 0
        average = duration.round(2) / count_calls
      else
        average = 0
      end
      [duration.round(2), count_calls, average]
    else
      [0, 0, 0]
    end
  end

  def aggregate_calls_outcoming(cal, user)
    if user.phone.present?
      a = user.phone.split(",").first
      #src = call.channel.match(/SIP\/([^>]*)-/).to_a.try(:second).try(:size) == 3 ? call.channel.match(/SIP\/([^>]*)-/)[1] : call.src
      count_calls_outcoming = cal.where("channel REGEXP ?", "SIP\/#{a}-[0-9a-z]{8}$").where(disposition: 'ANSWERED').count
      #count_calls_outcoming = cal.where(src: user.phone.split(",").first).where(disposition: 'ANSWERED').count
      duration_outcoming = cal.where("channel REGEXP ?", "SIP\/#{a}-[0-9a-z]{8}$").where(disposition: 'ANSWERED').sum("duration").to_f/60
      if count_calls_outcoming > 0
        average_outcoming = duration_outcoming.round(2) / count_calls_outcoming
      else
        average_outcoming = 0
      end
      [duration_outcoming.round(2), count_calls_outcoming, average_outcoming]
    else
      [0, 0, 0]
    end
  end

  def total_calls_incoming(cal, group)
    count = 0
    group.each do |user|
      count = count + cached_calls_incoming(cal, user)[1]
    end
    count
  end

  def total_calls_outcoming(cal, group)
        count = 0
    group.each do |user|
      count = count + cached_calls_outcoming(cal, user)[1]
    end
    count
  end

  def dot_to_comma(floatnum)
    floatnum.to_s.gsub!(/\./,",")
  end

  def total_calls(cal, user)
    incoming = cached_calls_incoming(cal, user)
    outcoming = cached_calls_outcoming(cal, user)
    [ incoming[0]+outcoming[0] > 0 ? (incoming[0]+outcoming[0]).round(2) : '-', incoming[1]+outcoming[1] > 0 ? incoming[1]+outcoming[1] : '-', incoming[2]+outcoming[2] > 0 ? (incoming[2]+outcoming[2]).round(2) : '-' ]
  end

  def aggregate_calls_each_hour(start, stop)
    res = []
    tmp = start
    (start..stop).step(1.hour) do |d|
      res << CallDataRecord.where({ calldate: (Time.at(tmp)-2.hours)..(Time.at(d)-2.hours) }).where(disposition: 'ANSWERED').where("dstchannel REGEXP ?", "SIP\/[0-9]{3}-[0-9a-z]{8}$").count
      tmp = d
    end
    res
  end

  def link_with_tooltip(name, href, title)
    content_tag(:a, name, href: href, rel: 'tooltip', title: title, class: 'tool-tip')
  end

  def check_forum_id(user)
    user.facebook.present? ? '' : '*'
  end

  def forum_id_to_login(forum_id)
    HTTParty.get("http://vs.vgg.ru/api/v2r/helpdesk/staff/#{forum_id}").parsed_response["login"]
  end

  def aggregate_data_each_hour(data,start,stop)
    res=[]
    (start..stop).step(1.hour) do |d|
      tmp=0
      data.each { |row|
        if row["date"] == Time.at(d).utc.strftime("%Y-%m-%d") and row["hour"] == Time.at(d).utc.hour
          tmp = row["count"]
          break
        end
      } unless data.nil?
      res << tmp
    end
    res
  end

  def current_calls_in_queue(queue_log)
   response = HTTParty.get("https://ats.vgg.ru/incoming.php", :verify => false )
  end

  def current_queue(queue_log)
    tmp = 0
    queue = queue_log.values
    queue.each do |call|
      if call[0]["event"] == "DID" and call.size == 2
        tmp = tmp + 1
      end
    end
    tmp
  end
  
  def missed_calls(queue_log)
    tmp = 0
    queue = queue_log.values
    queue.each do |call|
      if call.size > 2 and call[call.size-1]["event"] == "ABANDON"
        tmp = tmp + 1
      end
    end
    tmp
  end

  def queue_weight(data,start,stop)
    res=[]
    tmp = start
    (start..stop).step(10.minutes) do |d|
         res << data.where({ time: (Time.at(tmp)-2.hours)..(Time.at(d)-2.hours) })
           tmp = d
    end
    res.to_a.map! do |queue|
      queue.to_a.map! { |row| row = row.data3 }
        if queue.size == 0
          queue = 0
        else 
          queue = queue.max.to_i
        end
    end
    res
  end

  def report_telephony_control_by_hour(current_hour)
   CallDataRecord.where(calldate: ((@date_range_for_cont.date_start.beginning_of_day-4.hour+(current_hour).hour)..(@date_range_for_cont.date_start.beginning_of_day-4.hour+(current_hour+1).hour)))
  end

  def get_call_quality_by_user(cal, user)
    if user.phone.present?
      a = user.phone.split(",").first
      calls = cal.where(destination: a)
      #quality_zero = calls.where(quality: 0).count
      quality_one = calls.where(quality: 1).count
      quality_two = calls.where(quality: 2).count
      quality_three = calls.where(quality: 3).count
      quality_four = calls.where(quality: 4).count
      quality_five = calls.where(quality: 5).count
      [quality_one, quality_two, quality_three, quality_four, quality_five]     
    else
      [0, 0, 0, 0, 0]
    end
  end

  def report_queue_log_by_time(current_hour)
    QueueLogRecord.where(time: (@date_range_for_cont.date_start.beginning_of_day-4.hour+(current_hour).hour)..(@date_range_for_cont.date_start.beginning_of_day-4.hour+(current_hour+1).hour)).group_by(&:callid)
  end

  def avg_assigment(data)
    time = []
    if (data != [])
      data.each do |ticket|
        time << ( ticket["assigned"] - ticket["opened"] )
      end
      ((time.reduce(:+) / time.size.to_f) / 3600).round(2)
    else
      0
    end
  end

  def avg_closed(data)
    time = []
    if (data != [])
      data.each do |ticket|
        time << ( ticket["closed_at"] - ticket["assigned"] )
      end
      ((time.reduce(:+) / time.size.to_f)/3600).round(2)
    else
      0
    end
  end

  def running_of_ticket(ticket)
    time = Time.now.to_i - ticket["opened"]
    (time.to_i/(3600*24))
  end
end
