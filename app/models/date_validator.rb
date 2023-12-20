class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value = Array.wrap(value)
    value.each do |val|
      if AMS::NonExactDateService.invalid?(val)
        record.errors.add attribute, (options[:message] || "invalid date format: #{val}")
      end
    end
  end
end
