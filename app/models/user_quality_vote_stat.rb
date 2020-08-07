class UserQualityVoteStat < ActiveResource::Base
  if Rails.env.production?
    self.site = "http://vs.vgg.ru/api/v2r"
  else
    self.site = "http://vs.vgg.ru/api/v2r"
  end
  self.element_name = "user-quality-vote-stats"
end
