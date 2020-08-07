class AsteriskAnsweredCall < ActiveRecord::Base
	validates :source, presence: true
	validates :date, presence: true
	validates :duration, numericality: { only_integer: true, greater_than: 0 }
	validates :uniqueid, uniqueness: true
end
