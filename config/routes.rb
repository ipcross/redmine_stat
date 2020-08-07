# -*- encoding : utf-8 -*-
# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#get 'stat_reports', :to => 'stat_reports#report_redmine'

resources :public_stat, :only => [:public_report_telephony]  do
    collection do
      get :public_report_telephony, :public_quality_detailed
    end
end
