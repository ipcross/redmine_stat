class DateRange
  include Enumerable

  def initialize(date_start, date_stop = nil)
    @range = if date_stop
      [date_start, date_stop]
    else
      [date_start.beginning_of_month, date_start.end_of_month]
    end
  end

  def first
    @range.first
  end
  alias_method :date_start, :first

  def last
    @range.last
  end
  alias_method :date_stop, :last

  def days
    self.count
  end

  def each(&block)
    (@range.first..@range.last).each(&block)
  end

  def months
    self.select {|date| date.day == 1}
  end
end