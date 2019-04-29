class Influx
  require 'date'
  require 'influxdb'
  require 'time'
  require 'json'
  require 'csv'

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
    @current_build_number = ENV['current_build_number'].to_i

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
    getAggregatedData
    aggregatedDataToCsv
  end

  ##### Private methods #####
  private

  def getBuildDurationTime(time)
  	queryStartTime = "SELECT first(responseTime) FROM \"requestsRaw\" WHERE \"projectName\"=\'#{@project_id}\' AND \"envType\"=\'#{@env_type}\' AND \"testType\"=\'#{@test_type}\' and time > \'#{time}\'"
  	queryEndTime   = "SELECT last(responseTime)  FROM \"requestsRaw\" WHERE \"projectName\"=\'#{@project_id}\' AND \"envType\"=\'#{@env_type}\' AND \"testType\"=\'#{@test_type}\' and time > \'#{time}\'"
  	begin
      retries ||= 0
      getStartTime   = @influxdb.query queryStartTime 
      @buildStarted   = getStartTime[0]['values'][0]['time']
      getEndTime     = @influxdb.query queryEndTime
      @buildEnded    = getEndTime[0]['values'][0]['time']
    rescue
      puts "Error #{$!}. Start time: #{getStartTime}  End time: #{getEndTime} Time: #{time}"
      $logger.info "  |- Could not parse start or end time. Start time: #{getStartTime}  End time: #{getEndTime} .Retry #{retries}"
      retry if (retries +=1 ) < 5
    end
  end

  def getAggregatedData
    queryGetAggregatedData = "SELECT count(responseTime) as \"aggregate_report_count\",mean(responseTime) as \"average\",median(responseTime) as \"aggregate_report_median\",min(responseTime) as \"aggregate_report_min\",max(responseTime) as \"aggregate_report_max\",percentile(responseTime,90) as \"aggregate_report_90%%_line\",percentile(responseTime,95) as \"aggregate_report_95%%_line\",percentile(responseTime,99) as \"aggregate_report_99%%_line\",stddev(responseTime) as \"aggregate_report_stddev\",(sum(errorCount)/count(responseTime))*100 as \"aggregate_report_error%%\" FROM \"requestsRaw\" WHERE \"projectName\"=\'#{@project_id}\' AND \"envType\"=\'#{@env_type}\' AND \"buildID\"=\'#{@current_build_number}\' AND \"testType\"=\'#{@test_type}\' AND time > \'#{@buildStarted}\' GROUP BY \"requestName\",\"buildID\",\"projectName\",\"envType\",\"testType\""
    @getAggregatedData = @influxdb.query queryGetAggregatedData , denormalize: false
  end

  def aggregatedDataToCsv
    CSV.open("#{$test_results_folder}/log/aggregatedData.csv", "wb") do |csv|
      data = JSON.parse(@getAggregatedData.to_json)
      csv << ["sampler_label"] + data[0]['columns'][1..-1].each {|el| el}
      data.each do |i|
        csv << [i['tags']['requestName']] + i['values'][0][1..-1]
      end
    end
  end

end
