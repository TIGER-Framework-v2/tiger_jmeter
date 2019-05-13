class Kpi
  require 'csv'
  
  def initialize
    test_type = ENV['test_type']

  	begin
  	  @aggregated_data_hash = CSV.read("#{$test_results_folder}/log/aggregatedData.csv", :headers => true, converters: :numeric)
  	rescue
  		$logger.error "Can't read #{$test_results_folder}/log/aggregatedData.csv file"
  		exit 1
  	end

  	begin 
  		@predefined_kpi = CSV.read("#{$jmeter_test_path}/#{$tests_repo_name}/#{test_type}/#{test_type}.kpi.csv", :headers => true, converters: :numeric)
  	rescue
  		$logger.error "Can't read #{$jmeter_test_path}/#{$tests_repo_name}/#{test_type}/#{test_type}.kpi.csv file"
  		exit 1
  	end
  end


  def analyze_metric(scope_name,sampler_label_name,red_threshold,yellow_threshold,report_value)
    case scope_name
      when /tps_rate/
        if (report_value < red_threshold)
          @red_threshold_violations_count += 1
        elsif (report_value < yellow_threshold)
          @yellow_threshold_violations_count += 1
        end
      when /aggregate_report_error/
        if (report_value.to_f > red_threshold)
          @red_threshold_violations_count += 1
        elsif (report_value.to_f > yellow_threshold)
          @yellow_threshold_violations_count += 1
        end
      else
        if (report_value > red_threshold)
        	$logger.info "Applying KPI settings for #{sampler_label_name}, #{scope_name}:"
          $logger.info " |- Red threshold: #{red_threshold}"
          $logger.info " |- Yellow threshold: #{yellow_threshold}"
          $logger.info " |- Comparing with report data: #{report_value}"
          @red_threshold_violations_count += 1
        elsif (report_value > yellow_threshold)
          @yellow_threshold_violations_count += 1
        end
    end
  end

  def kpi_analyse
    @yellow_threshold_violations_count = 0
    @red_threshold_violations_count    = 0

    @aggregated_data_hash['sampler_label'].each do |sampler_label_name|
      report_sampler_index = @aggregated_data_hash['sampler_label'].index(sampler_label_name)

      if (@predefined_kpi['sampler_label'].find { |e| /#{e}/ =~ sampler_label_name })
        kpi_record_index   = @predefined_kpi['sampler_label'].index{ |e| /#{e}/ =~ sampler_label_name }
        scope_name         = @predefined_kpi[kpi_record_index][1]
        report_scope_index = @aggregated_data_hash.headers.index(scope_name)
        yellow_threshold   = @predefined_kpi[kpi_record_index][2]
        red_threshold      = @predefined_kpi[kpi_record_index][3]
        report_value       = @aggregated_data_hash[report_sampler_index][report_scope_index]
        analyze_metric(scope_name,sampler_label_name,red_threshold,yellow_threshold,report_value)
      #elsif (@predefined_kpi['sampler_label'].include?('any'))
      #  kpi_any_array = @predefined_kpi.select{|item| item[0]=='any'}
      #  kpi_any_array.each do |item| # checking all the KPIs for all the 'any' statements in the KPI CSV file
      #    $logger.info "Analyzing ANY statement of the KPI file: #{item}"
      #    scope_name         = item[1]
      #    report_scope_index = @aggregated_data_hash.headers.index(scope_name)
      #    yellow_threshold   = item[2]
      #    red_threshold      = item[3]
      #    report_value       = @aggregated_data_hash[report_sampler_index][report_scope_index]
      #    analyze_metric(scope_name,sampler_label_name,red_threshold,yellow_threshold,report_value)
      #  end
      end
    end
  end

  p "Total error count is #{@red_threshold_violations_count}"

end
