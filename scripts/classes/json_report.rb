class Json_report
  require 'csv'
  require 'json'

  def initialize(build_started, build_finished)
    test_type      = ENV['test_type']
    test_repo_name = ENV['tests_repo'].split('/').last.gsub('.git','')
    project_id     = ENV['project_id']

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
#  "transactions_details":{
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
