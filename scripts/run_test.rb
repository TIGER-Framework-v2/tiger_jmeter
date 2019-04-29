require 'yaml'
require 'fileutils'
require 'date'

# Require all files from 'classes' directory
Dir["classes/*.rb"].each {|file| require_relative file }


# defining variables
tests_repo_name      = ENV['tests_repo'].split('/').last.gsub('.git','')
current_build_number = ENV['current_build_number'].to_i
project_id           = ENV['project_id']
env_type             = ENV['env_type']
lg_id                = ENV['lg_id']
test_type            = ENV['test_type']
jmeter_test_path     = "/opt/tiger/jmeter_test"
$test_results_folder  = "/opt/tiger/#{test_type}/results"
data_folder          = $test_results_folder+"/data"
logs_folder          = $test_results_folder+"/log"
jmeter_cmd_options   = ''
jmeter_bin_path      = '/opt/apache-jmeter-5.1.1/bin/jmeter'
tiger_influxdb_extension_path = '/opt/tiger/scripts/tiger_extensions/jmeter_tiger_extension.jmx'

# creating folders
[
  data_folder,
  logs_folder
].each {|folder_path| FileUtils.mkdir_p(folder_path) unless File.exists?(folder_path)}

$logger=TigerLogger.new(logs_folder)

$logger.info "Clonning tests repository: git clone #{ENV['tests_repo']}"
Dir.chdir jmeter_test_path
raise "Tests were not downloaded successfully" unless system("git clone #{ENV['tests_repo']}")
Dir.chdir("#{jmeter_test_path}/#{tests_repo_name}/#{test_type}")



test_settings_hash=YAML.load(File.read("#{jmeter_test_path}/#{tests_repo_name}/#{test_type}/#{test_type}.yml"))

# reading tests settings from the YAML configuration file


internal_jmeter_cmd_options_hash={
  "build.id"        => "#{current_build_number}",
  "report.csv"      => "#{data_folder}/#{test_type}_html_report.csv",
  "errors.jtl"      => "#{data_folder}/#{test_type}_error.jtl",
  "test.type"       => "#{test_type}",
  "lg.id"           => "#{lg_id}",
  "influx.protocol" => "#{ENV['influx_protocol']}",
  "influx.host"     => "#{ENV['influx_host']}",
  "influx.port"     => "#{ENV['influx_port']}",
  "influx.db"       => "#{ENV['influx_db']}",
  "project.id"      => "#{project_id}",
  "influx.username" => "#{ENV['influx_username']}",
  "influx.password" => "#{ENV['influx_password']}",
  "env.type"        => "#{env_type}"
}

test_settings_hash['jmeter_args'].merge!(internal_jmeter_cmd_options_hash)
test_settings_hash['jmeter_args'].each {|setting,value| jmeter_cmd_options += "-J#{setting}=#{value} "}

tiger_extension_obj=TigerExtension.new(test_settings_hash['plan'],tiger_influxdb_extension_path)
extended_jmeter_plan_path=tiger_extension_obj.extend_jmeter_jmx(data_folder)


# compiling command line for the tests execution
jmeter_cmd=[
  "#{jmeter_bin_path} -n",
  "-t #{extended_jmeter_plan_path}",
  "-p #{test_settings_hash['properties']}",
  jmeter_cmd_options.chomp,
  "-l #{data_folder}/#{test_type}.jtl",
  "-j #{logs_folder}/jmeter_#{test_type}.log"
].join(' ')

$logger.info "Launching JMeter using compiled command line: #{jmeter_cmd}"

build_started  = (DateTime.now.new_offset(0) - (5/86400.0)).strftime("%Y-%m-%d %H:%M:%S") # Get the build start time and decrese it becouse of InfluxDB time delays
# Starting tests
jmeter_cmd_res = system(jmeter_cmd)
get_CSV = Influx.new()
get_CSV.get_aggregated_data_to_csv(build_started)

$logger.info jmeter_cmd_res
$logger.info "Results folder: #{$test_results_folder}"