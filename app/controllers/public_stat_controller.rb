class PublicStatController < ApplicationController
  unloadable


  menu_item :public_report_telephony, :only => :public_report_telephony


  before_filter :find_project,:date_range_from_params, :get_users, :authorize, :only => [:public_report_telephony,:public_quality_detailed]

  def public_quality_detailed
    tmp = AsteriskAnsweredCall.where(destination: params[:dst].split(",").first)
    .where(date: ((params[:date_start].to_datetime.beginning_of_day-4.hours)..(params[:date_stop].to_datetime.end_of_day-4.hours)))
    @details = { "full_stat" => tmp.where(quality: 1..5), "1" => tmp.where(quality: 1), "2" => tmp.where(quality: 2),
      "3" => tmp.where(quality: 3), "4" => tmp.where(quality: 4), "5" => tmp.where(quality: 5) }
  end

  def public_report_telephony
    session[:telephony_category] = %w(graph stat queuegraph control qstat forum_avg).include?(params[:telephony_category]) ? params[:telephony_category] : 'queue'
    case session[:telephony_category]
      when 'queue'
        report_queue_log
        report_cached_telephony_stat
      # default is 'queue'...
      when 'stat'
        report_cached_telephony_stat
        report_avg_queue_waiting
      when 'queuegraph'
        queue_graph
      when 'control'
        report_control_stat
      when 'qstat'
        report_avg_queue_waiting
        report_large_numbers
      when 'forum_avg'
        avg_forum_stat
    end
  end

  def report_time_entries
    @time_entries_by_login_and_issues = []
    time_entries = TimeEntry
      .preload(:project => :time_entry_activities)
      .preload(:issue)
      .preload(:user)
      .where(:spent_on => @date_range.date_start.beginning_of_day..@date_range.date_stop.beginning_of_day)
      .to_a
    time_entries.group_by{ |time_entry| time_entry.user.login }.each do |login, entries|
      entries.group_by(&:issue).each do |issue, g_entries|
        @time_entries_by_login_and_issues.push({
          login: login,
          issue: issue.subject,
          issue_tracker: issue.tracker.name,
          issue_id: issue.id,
          issue_status: issue.status.name,
          hours: g_entries.sum(&:hours)

        })
      end
    end
    @time_entries_by_login_and_issues = @time_entries_by_login_and_issues.sort_by { |a| -a[:hours] }.group_by { |t| t[:login] }
  end

  private

  def date_range_from_params
    if params[:range] && params[:range][:start]
      begin
        session[:range_start] = Date.parse(params[:range][:start])
      rescue
      end
    end
    session[:range_start] = Date.today.beginning_of_day unless session[:range_start]

    if params[:range] && params[:range][:stop]
      begin
        session[:range_stop] = Date.parse(params[:range][:stop])
      rescue
      end
    end
    session[:range_stop] = Date.today unless session[:range_stop]
    tmp=[session[:range_start],session[:range_stop]].sort
    @date_range = DateRange.new(tmp[0],tmp[1])
  end

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find('group_admin')
  end

  def get_users
      session[:statistics_group] = 19
      @stat_users = Person.where(id: Group.find(session[:statistics_group]).users.map{|i| i.id}).includes(:information).sort
      @users_hash = Person.includes(:information).where(id: @stat_users).group_by { |el| el.information.try(:job_title) }
  end

  def report_cached_telephony_stat
    @cached_calls = AsteriskAnsweredCall.where(date: ((@date_range.date_start.beginning_of_day-4.hour)..(@date_range.date_stop.end_of_day-4.hour)))
  end

  def report_queue_log
    @queuelog = QueueLogRecord.where(created: (DateTime.now-20.minutes)..(DateTime.now)).group_by(&:callid)
  end

  def queue_graph
    @queuegraph = QueueLogRecord.where(event: "ENTERQUEUE")
  end

  def report_control_stat
    begin
      @date_range_for_cont = DateRange.new(Date.parse(params[:range][:start]),Date.parse(params[:range][:start])+1.day)
    rescue
      @date_range_for_cont = DateRange.new(Date.today,Date.today+1.day)
    end
    @all_calls = AsteriskAnsweredCall.where(date: ((@date_range.date_start.beginning_of_day-4.hour)..(@date_range.date_stop.end_of_day-4.hour)))
  end

  def report_avg_queue_waiting
    tmp_hash = QueueLogRecord.avg_queue_waiting(@date_range.date_start.beginning_of_day,@date_range.date_stop.end_of_day).first
    @avg_connect = tmp_hash["before_connect"]
    @avg_abandon = tmp_hash["before_abandon"]
    @count_listened_balance = tmp_hash["got_own_balance"]
  end

  def report_large_numbers
    tmp_hash = QueueLogRecord.get_large_queue_time(@date_range.date_start.beginning_of_day,@date_range.date_stop.end_of_day).first
    @connected_large = tmp_hash["before_connect"].first(20)
    @abandoned_large = tmp_hash["before_abandon"].first(20)
  end


  def avg_forum_stat
    @stat_for_avg_values = ExophpdeskTicket.stat_count(@date_range.date_start.beginning_of_day.to_i,
                                                       @date_range.date_stop.end_of_day.to_i).to_a
    tmp = ExophpdeskTicket.stat_for_longrunning_tickets((Time.now-2.year).to_i,
                                                                           (Time.now-2.day).to_i).to_a
    @long_running_tickets = tmp.group_by{ |a,b| a["group"]}
  end
end
