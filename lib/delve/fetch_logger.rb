module Delve
  class FetchLogger
    def self.log(result)
      type_field = (result.type || '').ljust(5)
      status_field = format('%3d', result.status || 0)
      puts "#{type_field} #{status_field} #{result.url}"
    end
  end
end
