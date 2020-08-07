module RedminePublicStat
  module Patches
    module IssuePatch
      def self.included(base)
        base.class_eval do
      
          #field = 'assignid_to_id' and 'author_id'
          def self.count_for_stat_report(field,start,stop)
            ActiveRecord::Base.connection.select_all("select    s.id as status_id,
                                                s.is_closed as closed,
                                                j.id as #{field},
                                                count(#{Issue.table_name}.id) as total
                                              from 
                                                  #{Issue.table_name}, #{IssueStatus.table_name} s, #{User.table_name} j
                                              where
                                                #{Issue.table_name}.status_id=s.id
                                                and #{Issue.table_name}.#{field}=j.id
                                                and #{Issue.table_name}.created_on >= '#{start}'
                                                and #{Issue.table_name}.created_on <= '#{stop}'
                                              group by s.id, s.is_closed, j.id")
          end

          def self.count_for_stat_report_closed(field,start,stop)
            ActiveRecord::Base.connection.select_all("select    s.id as status_id,
                                                s.is_closed as closed,
                                                j.id as #{field},
                                                count(#{Issue.table_name}.id) as total
                                              from
                                                  #{Issue.table_name}, #{IssueStatus.table_name} s, #{User.table_name} j
                                              where
                                                #{Issue.table_name}.status_id=s.id
                                                and #{Issue.table_name}.#{field}=j.id
                                                and #{Issue.table_name}.closed_on >= '#{start}'
                                                and #{Issue.table_name}.closed_on <= '#{stop}'
                                              group by s.id, s.is_closed, j.id")
          end

          def self.count_for_stat_report_overdue(field)
            ActiveRecord::Base.connection.select_all("select    s.id as status_id, 
                                                s.is_closed as closed, 
                                                j.id as #{field},
                                                count(#{Issue.table_name}.id) as total 
                                              from 
                                                  #{Issue.table_name}, #{IssueStatus.table_name} s, #{User.table_name} j
                                              where 
                                                #{Issue.table_name}.status_id=s.id 
                                                and #{Issue.table_name}.#{field}=j.id
                                                and #{Issue.table_name}.due_date < '#{Date.today}' 
                                              group by s.id, s.is_closed, j.id")
          end

        end # base.class_eval
      end # self.included
    end # issue patch
  end # patches
end # StatReports

unless Issue.included_modules.include?(RedminePublicStat::Patches::IssuePatch)
  Issue.send(:include, RedminePublicStat::Patches::IssuePatch)
end
