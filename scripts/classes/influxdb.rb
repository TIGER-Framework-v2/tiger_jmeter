class Influx
  require 'date'
  require 'influxdb'
  require 'time'

  def initialize
    @version_id      = ""
    @influx_protocol = ENV['influx_protocol']
    @influx_host     = ENV['influx_host']
    @influx_port     = ENV['influx_port']
    @influx_db       = ENV['influx_db']
    @influx_username = ENV['influx_username']
    @influx_password = ENV['influx_password']
    @lg_id           = ENV['lg_id']
    @project_id      = ENV['project_id']
    @env_type        = ENV['env_type']
    @test_type       = ENV['test_type']

    influxdbUrl      = "#{@influx_protocol}://#{@influx_host}:#{@influx_port}/"
    influxdbDatabase = "#{@influx_db}"
    @influxdb = InfluxDB::Client.new influxdbDatabase,
                url: influxdbUrl,
                username: @influx_username,
                password: @influx_password,
                open_timeout: 320,
                read_timeout: 320
  end
  
  def get_aggregated_data_to_csv(start_time)
    getBuildDurationTime(start_time)
  end



  private

  def getBuildDurationTime(time)
  	queryStartTime = "SELECT first(responseTime) FROM \"requestsRaw\" WHERE \"projectName\"=\'#{@project_id}\' AND \"envType\"=\'#{@env_type}\' AND \"testType\"=\'#{@test_type}\' and time > \'#{time}\'"
  	queryEndTime   = "SELECT last(responseTime)  FROM \"requestsRaw\" WHERE \"projectName\"=\'#{@project_id}\' AND \"envType\"=\'#{@env_type}\' AND \"testType\"=\'#{@test_type}\' and time > \'#{time}\'"
  	begin
      retries ||= 0
      getStartTime = `curl -G "#{@influx_protocol}://#{@influx_host}:#{@influx_port}/query?u=#{@influx_username}&p=#{@influx_password}" --data-urlencode "db=#{@influx_db}" --data-urlencode "q=#{queryStartTime}" `
      p getStartTime 
      testdata = @influxdb.query  queryStartTime
      p testdata
      getEndTime   = `curl -G "#{@influx_protocol}://#{@influx_host}:#{@influx_port}/query?u=#{@influx_username}&p=#{@influx_password}" --data-urlencode "db=#{@influx_db}" --data-urlencode "q=#{queryEndTime}" `
      buildStarted = getStartTime[/\d{4}-\d{2}-\d{2}[T]\d{2}:\d{2}:\d{2}.\d*[Z]/]
      $buildStarted = (DateTime.parse(buildStarted).to_time - 5).strftime("%Y-%m-%dT%H:%M:%SZ")
      $buildEnded   = getEndTime[/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d*[Z]/]
    rescue
      puts "Error #{$!}. Start time: #{getStartTime}  End time: #{getEndTime} Time: #{time}"
      puts "#{queryStartTime}"
      $logger.info "  |- Could not parse start or end time. Start time: #{getStartTime}  End time: #{getEndTime} .Retry #{retries}"
      retry if (retries +=1 ) < 5
    end
  end
end
