class Json_report
  require 'json'
  require 'influxdb'

  def initialize(build_started, build_finished)
    @build_started  = build_started,
    @build_finished = build_finished

    influxdbUrl      = ENV['influx_protocol'] + '://' + ENV['influx_host'] + ':' + ENV['influx_port'] + '/'
    influxdbDatabase = ENV['influx_db']
    @influxdb = InfluxDB::Client.new influxdbDatabase,
                  url: influxdbUrl,
                  username: ENV['influx_username'],
                  password: ENV['influx_password'],
                  open_timeout: 320,
                  read_timeout: 320

  end
  
  def generate_json_report
    test_results_section
    test_settings_section
    tiger_settings_section
    transactions_details_section
  end

  ##### Private methods #####
  private

  def test_results_section
    test_results = Hash.new
    test_results[:test_results] = {
      "lg_count"                   => 'HARDCODED',                 # Not avaliable
      "grafana_link"               => "HARDCODED",                 # Not avaliable
      "start_time"                 => @build_started.to_i,
      "end_time"                   => @build_finished.to_i,
      "duration"                   => @build_finished.to_i - @build_started.to_i,
      "status"                     => "pass|fail|warning",               # Not availble
      "max_threads_count"          => 4600,                              # Take from request
      "transactions"               => {
        "total"                    => 56798993, # Take from request
        "total_passed"             => 56798342,   # Take from request
        "total_failed"             => 821,        # Take from request
        "red_transactions_perc"    => 5,          # Take from request
        "yellow_transactions_perc" => 10          # Take from request
      }
    }
    return test_results
  end

  def test_settings_section
    test_settings = Hash.new
    test_results[:test_settings] = {
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
    tiger_settings[:tiger_settings] = {
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

  end

end
#{
#  "test_result":{    
#    "lg_count": 3,
#    "grafana_link": "https:// ......",
#    "start_time": "1565331600000",               # default time zone: UTC, parameter is configurable
#    "end_time": "1565362800000", # default time zone: UTC, parameter is configurable
#    "duration":300, # hh:mm:ss
#    "status": "pass|fail|warning",     # available in case KPI analysis was enabled
#    "max_threads_count": 4600,
#    "transactions_":{
#      "total":"56798993",
#      "total_passed": 56798342, 
#      "total_failed": 821, 
#      "red_transactions_perc":5,                          # available in case KPI analysis was enabled
#      "yellow_transactions_perc":10   # available in case KPI analysis was enabled                                          
#    },                             
#  },
#  "test_settings":{
#    "comment": "Basic test",
#    "version_id": "v.2.0.1",
#    "build_id":7,
#    "project_id":"Test",
#    "env_type": "test_env",                 
#    "test_type": "basic",
#    "test_duration":240,
#    "target_host": "mega.com",
#    "target_protocol": "https"
#  },
#  "tiger_settings": {
#    "docker_host": "fqdn(s)",
#    "lg_id": "lg_1 lc_2",
#    "tests_repo": "git@test.git",        # SSH available Git compatible server repository
#    "influx_db_name": "tests_results",
#    "influxdb_host": "fqdn",                                # yaml based configurable parameter
#    "influxdb_port": "fqdn",                # yaml based configurable parameter
#  },
#  "transactions_details":{     # aggregated data
#    "01.TrxName01": {
#      "passed_count": 100,
#      "failed_count": 1,
#      "avg":{
#        "test_value":120,                             
#        "red_threshold":10,                        # available in case KPI analysis was enabled
#        "yellow_threshold":100 # available in case KPI analysis was enabled
#      },
#      "min":{
#        "test_value":12,
#        "red_threshold":10,                        # available in case KPI analysis was enabled
#        "yellow_threshold":100 # available in case KPI analysis was enabled
#      },
#                                ....
#  }
#}
