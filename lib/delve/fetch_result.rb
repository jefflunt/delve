module Delve
  FetchResult = Struct.new(
    :url, :content, :links, :status, :type, :error, :attachments,
    keyword_init: true
  )
end
