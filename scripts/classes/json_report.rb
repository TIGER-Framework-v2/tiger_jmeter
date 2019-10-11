class Json_report
  require 'json'
  require 'influxdb'

  def initialize(build_started, build_finished)
    @build_started  = build_started
    @build_finished = build_finished

    influxdbUrl      = ENV['influx_protocol'] + '://' + ENV['influx_host'] + ':' + ENV['influx_port'] + '/'
    influxdbDatabase = ENV['influx_db']
    @influxdb = InfluxDB::Client.new influxdbDatabase,
                  url: influxdbUrl,
                  username: ENV['influx_username'],
                  password: ENV['influx_password'],
                  retry: 5,
                  open_timeout: 320,
                  read_timeout: 320
  end
  
  def generate_json_report (status, result_folder)
    report = Hash.new
    report['test_results']        = test_results_section(status)
    report['test_settings']       = test_settings_section
    report['tiger_settings']      = tiger_settings_section
    report['transaction_details'] = transactions_details_section

    File.open("#{result_folder}/test_report.json","w") do |f|
      f.write(report.to_json)
    end
  end

  ##### Private methods #####
  private

  def test_results_section(status)
    test_results = Hash.new
    max_threads_count = @influxdb.query "SELECT SUM(\"max_threads_value\") FROM (SELECT max(\"startedThreads\") as \"max_threads_value\" FROM \"virtualUsers\" WHERE \"projectName\" = '#{ENV['project_id']}' AND \"envType\" = '#{ENV['env_type']}' AND \"testType\" = '#{ENV['test_type']}' AND \"buildID\" = '#{ENV['current_build_number']}' AND time >= #{@build_started.to_i}s and time <= #{@build_finished.to_i}s GROUP BY \"loadGenerator\")"
    total             = @influxdb.query "SELECT count(\"responseTime\") FROM \"requestsRaw\" WHERE \"projectName\" = '#{ENV['project_id']}' AND \"envType\" = '#{ENV['env_type']}' AND \"testType\" = '#{ENV['test_type']}' AND \"buildID\" = '#{ENV['current_build_number']}' AND time >= #{@build_started.to_i}s and time <= #{@build_finished.to_i}s"
    total_passed      = @influxdb.query "SELECT count(\"responseTime\") FROM \"requestsRaw\" WHERE \"errorCount\" = 0 AND \"projectName\" = '#{ENV['project_id']}' AND \"envType\" = '#{ENV['env_type']}' AND \"testType\" = '#{ENV['test_type']}' AND \"buildID\" = '#{ENV['current_build_number']}' AND time >= #{@build_started.to_i}s and time <= #{@build_finished.to_i}s"
    total_failed      = @influxdb.query "SELECT count(\"responseTime\") FROM \"requestsRaw\" WHERE \"errorCount\" = 1 AND \"projectName\" = '#{ENV['project_id']}' AND \"envType\" = '#{ENV['env_type']}' AND \"testType\" = '#{ENV['test_type']}' AND \"buildID\" = '#{ENV['current_build_number']}' AND time >= #{@build_started.to_i}s and time <= #{@build_finished.to_i}s"

    test_results = {
      "lg_count"                   => 'HARDCODED',
      "grafana_link"               => "HARDCODED",
      "start_time"                 => @build_started.to_i,
      "end_time"                   => @build_finished.to_i,
      "duration"                   => @build_finished.to_i - @build_started.to_i,
      "status"                     => status,
      "max_threads_count"          => max_threads_count[0]['values'][0]['sum'],
      "transactions"               => {
        "total"                    => total[0]['values'][0]['count'],
        "total_passed"             => total_passed[0]['values'][0]['count'],
        "total_failed"             => total_failed[0]['values'][0]['count'],
        "red_transactions_perc"    => "HARDCODED",
        "yellow_transactions_perc" => "HARDCODED"
      }
    }
    return test_results
  end

  def test_settings_section
    test_settings = Hash.new
    test_settings  = {
      "comment"         => "HARDCODED",
      "version_id"      => "HARDCODED",
      "build_id"        => ENV['current_build_number'].to_i,
      "project_id"      => ENV['project_id'],
      "env_type"        => ENV['env_type'],
      "test_type"       => ENV['test_type'],
      "test_duration"   => @build_finished.to_i - @build_started.to_i,
      "target_host"     => "HARDCODED",
      "target_protocol" => "HARDCODED"
    }
    return test_settings
  end

  def tiger_settings_section
    tiger_settings = Hash.new
    tiger_settings = {
      "docker_host"    =>  "HARDCODED",
      "lg_id"          =>  "HARDCODED",
      "tests_repo"     =>  ENV['tests_repo'],
      "influx_db_name" =>  ENV['influx_db'],
      "influxdb_host"  =>  ENV['influx_host'],
      "influxdb_port"  =>  ENV['influx_port']
    }
    return tiger_settings
  end

  def transactions_details_section
    transaction_details = Hash.new
    data = @influxdb.query "SELECT count(responseTime) as \"Total Count\", count(responseTime)-sum(errorCount) as \"Successful Count\", sum(errorCount) as \"Error Count\", mean(responseTime)/1000 as Average, median(responseTime)/1000 as Median, percentile(responseTime, 90)/1000 as \"90%% Line\",percentile(responseTime, 95)/1000 as \"95%% Line\",percentile(responseTime, 99)/1000 as \"99%% Line\", min(responseTime)/1000 as Min, max(responseTime)/1000 as Max, (sum(errorCount)/count(responseTime))*100 as \"Error Rate\", stddev(\"responseTime\") as \"Standard Deviation\" FROM \"requestsRaw\" WHERE \"errorCount\" = 1 AND \"projectName\" = '#{ENV['project_id']}' AND \"envType\" = '#{ENV['env_type']}' AND \"testType\" = '#{ENV['test_type']}' AND \"buildID\" = '#{ENV['current_build_number']}' AND time >= #{@build_started.to_i}s and time <= #{@build_finished.to_i}s GROUP BY \"requestName\""
    data.each do |el|
      transaction_details[el['tags']['requestName']] = {
        "Total Count"        => el['values'][0]['Total Count'],
        "Error Count"        => el['values'][0]['Error Count'],
        "Successful Count"   => el['values'][0]['Successful Count'],
        "Average"            => el['values'][0]['Average'],
        "Median"             => el['values'][0]['Median'],
        "90% Line"           => el['values'][0]['90% Line'],
        "95% Line"           => el['values'][0]['95% Line'],
        "99% Line"           => el['values'][0]['99% Line'],
        "Min"                => el['values'][0]['Min'],
        "Max"                => el['values'][0]['Max'],
        "Error Rate"         => el['values'][0]['Error Rate'],
        "Standard Deviation" => el['values'][0]['Standard Deviation']
      }
    end
    return transaction_details
  end
end