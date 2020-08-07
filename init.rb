require 'redmine'
require 'redmine_public_stat'

Redmine::Plugin.register :public_stat do
  name 'Public stat plugin'
  author 'Alifanov Dmitry'
  description 'This is statistics for Unico team'
  version '0.0.3'
  url 'http://www.is.vgg.ru'
  author_url 'http://www.is.vgg.ru'

  project_module :public_stat do
    permission :view_stat_public_report_telephony, :public_stat => :public_report_telephony
    permission :view_stat_public_quality_detailed, :public_stat => :public_quality_detailed
  end

  menu :project_menu, :public_report_telephony, { :controller => 'public_stat', :action => 'public_report_telephony' }, :caption => :label_report_telephony, :after => :report_dsmf, :param => :project_id
end
