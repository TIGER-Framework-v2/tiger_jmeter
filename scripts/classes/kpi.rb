class Kpi
  require 'csv'
  require 'yaml'

  def initialize(tests_repo_name,jmeter_test_path,test_results_folder)

    begin
      @aggregated_data_hash = CSV.read("#{test_results_folder}/log/aggregatedData.csv", :headers => true, converters: :numeric)
    rescue
      $logger.error "Can't read #{test_results_folder}/log/aggregatedData.csv file"
      exit 1
  	end

  	begin
      @predefined_kpi = CSV.read("#{jmeter_test_path}/#{tests_repo_name}/#{ENV['test_type']}/#{ENV['test_type']}.kpi.csv", :headers => true, converters: :numeric)
  	rescue
      $logger.error "Can't read #{jmeter_test_path}/#{tests_repo_name}/#{ENV['test_type']}/#{ENV['test_type']}.kpi.csv file"
      exit 1
    end

    begin
      @test_settings = YAML.load(File.read("#{jmeter_test_path}/#{tests_repo_name}/#{ENV['test_type']}/#{ENV['test_type']}.yml"))
    rescue
      $logger.error "Can't read #{jmeter_test_path}/#{tests_repo_name}/#{ENV['test_type']}/#{ENV['test_type']}.yml file"
      exit 1
    end
  end

  def count_gathered_values(csv_file)
    # Counting number of gathered metrics for getting percentage of red and yellow thresholds
    csv_file.delete('sampler_label')
    lines = 0
    csv_file.each {|row| lines += 1 }
    columns = csv_file.headers.count
    count = columns * lines
    return count
  end

  def analyze_metric(scope_name, sampler_label_name, red_threshold, yellow_threshold, report_value)
    case scope_name
    when /tps_rate|success_rate/
      if report_value < red_threshold
        $logger.info "#{scope_name} of #{sampler_label_name} = #{report_value} < red_threshold (#{red_threshold})"
        @red_threshold_violations_count += 1
      elsif report_value < yellow_threshold
        $logger.info "#{scope_name} of #{sampler_label_name} = #{report_value} < yellow_threshold (#{yellow_threshold}). Red threshold is #{red_threshold}"
        @yellow_threshold_violations_count += 1
      end
    when /aggregate_report_error/
      if report_value.to_f > red_threshold
        $logger.info "#{scope_name} of #{sampler_label_name} = #{report_value} > red_threshold (#{red_threshold})"
        @red_threshold_violations_count += 1
      elsif report_value.to_f > yellow_threshold
        $logger.info "#{scope_name} of #{sampler_label_name} = #{report_value} > yellow_threshold (#{yellow_threshold}). Red threshold is #{red_threshold}"
        @yellow_threshold_violations_count += 1
      end
    else
      if report_value > red_threshold
        $logger.info "#{scope_name} of #{sampler_label_name} = #{report_value} > red_threshold (#{red_threshold})"
        @red_threshold_violations_count += 1
      elsif report_value > yellow_threshold
        $logger.info "#{scope_name} of #{sampler_label_name} = #{report_value} > yellow_threshold (#{yellow_threshold}).Red threshold is #{red_threshold}"
        @yellow_threshold_violations_count += 1
      end
    end
  end

  def kpi_analyse
    @yellow_threshold_violations_count = 0
    @red_threshold_violations_count    = 0
    
    # Create array of all '.*'
    if @predefined_kpi['sampler_label'].include?('.*')
      any_values_from_kpi = @predefined_kpi.select { |item| item[0] == '.*' }             # Find all '.*' values and add them to separate array
      any_values_from_kpi.delete_if { |row| row['scope_name'].nil? }                      # Delete empty elements from array
      @predefined_kpi.delete_if { |row| any_values_from_kpi.include?(row) }               # Delete all '.*' from KPI's hash, to exclude them from the next checks
    end

    @aggregated_data_hash['sampler_label'].each do |sampler_label_name|

      p "Working with #{sampler_label_name}"

      selected_kpi  = Array.new
      label_matches = @predefined_kpi.select { |item| /#{item[0]}/ =~ sampler_label_name } # Create array of all Matches
      label_matches.delete_if { |row| row['scope_name'].nil? }                             # Delete empty elements from array
      selected_kpi.push(*label_matches)

      if !selected_kpi.empty? && !any_values_from_kpi.nil?                                 # Delete Any value from analyse if it's scope name has already exist in label_matches array
        any_values_from_kpi.each do |item|
          if label_matches.find { |el| el['scope_name'] == item['scope_name'] }
            $logger.warn "ANY '#{item['scope_name']}' has already set up for #{sampler_label_name}"
          else
            selected_kpi.push(item)
          end
        end
      elsif !any_values_from_kpi.nil?                                                      # Add all 'any' values if no match was founded and 'any' KPI's were set up
        selected_kpi.push(*any_values_from_kpi)    
      end

      report_sampler_index = @aggregated_data_hash['sampler_label'].index(sampler_label_name)

      if !selected_kpi.empty?                                                              # Start analysing KPI's
        selected_kpi.each do |item|
          scope_name         = item['scope_name']
          report_scope_index = @aggregated_data_hash.headers.index(scope_name)
          yellow_threshold   = item['yellow_threshold']
          red_threshold      = item['red_threshold']
          report_value       = @aggregated_data_hash[report_sampler_index][report_scope_index]
          analyze_metric(scope_name, sampler_label_name, red_threshold, yellow_threshold, report_value)
        end
      end
    end
    
    checks_count = count_gathered_values(@aggregated_data_hash)
    error_perc   = ((@red_threshold_violations_count.to_f/checks_count) * 100).round(2)
    warning_perc = ((@yellow_threshold_violations_count.to_f/checks_count) * 100).round(2)

    if error_perc >= @test_settings['red_threshold']
      $logger.error 'Test has exceeded values'
      status = 'failed'
    elsif @yellow_threshold_violations_count > 0
      $logger.info 'Test passed with warnings'
      status = 'warning'
    else
      $logger.info 'Test succeeded'
      status = 'success'
    end

    return {
              "status" => status,
              "yellow_threshold_perc" => warning_perc,
              "red_threshold_perc" => error_perc
           }
  end
end
