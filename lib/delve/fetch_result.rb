module Delve
  FetchResult = Struct.new(
    :url, :content, :links, :status, :type, :error,
    keyword_init: true
  )
end
