class Http_request
  require 'json'
  require 'net/http'

  def send (host,port,path,data)
    $logger.info "Sending request to the #{host}:#{port}#{path}"
    http = Net::HTTP.new(host,port)
    http.use_ssl = false
    req = Net::HTTP::Post.new(path, {'Content-Type' =>'application/json'})
    puts "Sending data to the #{host}:#{port}"
    req.body=data.to_json
    puts "Request data:"
    puts req.body.to_s
    response=http.start do |http|
      http.request(req)
    end

    return response.body
  end

end
