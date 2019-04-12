require 'yaml'
require 'fileutils'

test_type='sample'
puts "Clonning tests repository: git clone #{ENV['tests_repo']}"
jmeter_test_path="/opt/tiger/jmeter_test"
Dir.chdir jmeter_test_path
raise "Tests were not downloaded successfully" unless system("git clone #{ENV['tests_repo']}")
tests_repo_name=ENV['tests_repo'].split('/').last.gsub('.git','')
test_type=ENV['test_type']
Dir.chdir("#{jmeter_test_path}/#{tests_repo_name}/#{test_type}")
test_settings_hash=YAML.load(File.read("#{jmeter_test_path}/#{tests_repo_name}/#{test_type}/#{test_type}.yml"))
test_results_folder="/opt/tiger/#{test_type}/results"
data_folder=test_results_folder+"/data"
logs_folder=test_results_folder+"/log"
jmeter_cmd_options=''

jmeter_bin_path='/opt/apache-jmeter-5.1.1/bin/jmeter'

[
  data_folder,
  logs_folder
].each {|folder_path| FileUtils.mkdir_p(folder_path) unless File.exists?(folder_path)}

test_settings_hash['jmeter_args'].each {|setting,value| jmeter_cmd_options+="-J#{setting}=#{value} "}

jmeter_cmd=[
  "#{jmeter_bin_path} -n",
  "-t #{test_settings_hash['plan']}",
  "-p #{test_settings_hash['properties']}",
  jmeter_cmd_options.chomp,
  "-l #{data_folder}/#{test_type}.jtl",
  "-j #{logs_folder}/jmeter_#{test_type}.log"
].join(' ')
puts "JMeter execution compiled command line: #{jmeter_cmd}"
jmeter_cmd_res=system(jmeter_cmd)
puts jmeter_cmd_res
puts "Results folder: #{test_results_folder}"

