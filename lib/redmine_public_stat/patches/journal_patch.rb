module RedminePublicStat
  module Patches
    module JournalPatch
      def self.included(base)
        base.class_eval do

          def self.count_journal_for_user(start,stop)
            ActiveRecord::Base.connection.select_all("select j.id as user_id,
                                                count(#{Journal.table_name}.id) as total 
                                              from 
                                                  #{Journal.table_name}, #{User.table_name} j
                                              where 
                                                #{Journal.table_name}.user_id=j.id and 
                                                #{Journal.table_name}.created_on >= '#{start}' 
                                                and #{Journal.table_name}.created_on <= '#{stop}'
                                              group by j.id")
          end

        end # base.class_eval
      end # self.included
    end # journal patch
  end # patches
end # StatReports

unless Journal.included_modules.include?(RedminePublicStat::Patches::JournalPatch)
  Journal.send(:include, RedminePublicStat::Patches::JournalPatch)
end
