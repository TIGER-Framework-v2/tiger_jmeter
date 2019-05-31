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
        	$logger.info "#{scope_name} Exsided #{red_threshold} for #{sampler_label_name}"
          @red_threshold_violations_count += 1
        elsif (report_value > yellow_threshold)
          @yellow_threshold_violations_count += 1
        end
    end
  end

  def kpi_analyse
    @yellow_threshold_violations_count = 0
    @red_threshold_violations_count    = 0
    
    # Create array of all Any
    if (@predefined_kpi['sampler_label'].include?('any'))
      any_values_from_kpi = @predefined_kpi.select{|item| item[0] == 'any'}
      any_values_from_kpi.delete_if {|row| row['scope_name'].nil? }                     # Delete empty elements from array
    end

    @aggregated_data_hash['sampler_label'].each do |sampler_label_name|
    
      p "Working with #{sampler_label_name}"
   
      selected_kpi  = Array.new
      label_matches = @predefined_kpi.select{|item| /#{item[0]}/ =~ sampler_label_name } # Create array of all Matches
      label_matches.delete_if {|row| row['scope_name'].nil? }                            # Delete empty elements from array
      selected_kpi.push(*label_matches)
    
      if selected_kpi.length > 0 && !any_values_from_kpi.nil?                            # Delete Any value from analyse if it's scope name has already exist in label_matches array       
        any_values_from_kpi.each do |item|
          if label_matches.find { |el| el['scope_name'] == item['scope_name']}
            $logger.warn "ANY '#{item['scope_name']}' has already set up for #{sampler_label_name}"
          else
            selected_kpi.push(item)
          end
        end
      elsif !any_values_from_kpi.nil?                                                    # Add all 'any' values if no match was founded and 'any' KPI's were set up
        selected_kpi.push(*any_values_from_kpi)    
      end  
   
      report_sampler_index = @aggregated_data_hash['sampler_label'].index(sampler_label_name)

      if selected_kpi.length > 0                                                         # Start analysing KPI's 
        selected_kpi.each do |item|
          begin
            scope_name         = item['scope_name']
            report_scope_index = aggregated_data_hash.headers.index(scope_name)
            yellow_threshold   = item['yellow_threshold']
            red_threshold      = item['red_threshold']
            report_value       = aggregated_data_hash[report_sampler_index][report_scope_index]
            analyze_metric(scope_name,sampler_label_name,red_threshold,yellow_threshold,report_value)
          rescue 
            $logger.error "Wrong 'scope_name' defined in KPI's. Please check it for '#{sampler_label_name}'"
          end
        end
      end
    end






    #@aggregated_data_hash['sampler_label'].each do |sampler_label_name|
    #  report_sampler_index = @aggregated_data_hash['sampler_label'].index(sampler_label_name)
#
    #  if (@predefined_kpi['sampler_label'].find { |e| /#{e}/ =~ sampler_label_name })
    #    all_matches = @predefined_kpi.select{|item| /#{item[0]}/ =~ sampler_label_name }
    #    all_matches.each do |item|
    #      begin
    #        scope_name         = item['scope_name']
    #        report_scope_index = @aggregated_data_hash.headers.index(scope_name)
    #        yellow_threshold   = item['yellow_threshold']
    #        red_threshold      = item['red_threshold']
    #        report_value       = @aggregated_data_hash[report_sampler_index][report_scope_index]
    #        analyze_metric(scope_name,sampler_label_name,red_threshold,yellow_threshold,report_value)
    #      rescue 
    #        p "Wrong 'sampler_label' defined in KPI's. Please check it for '#{sampler_label_name}'"
    #      end
    #    end
    #  elsif (@predefined_kpi['sampler_label'].include?('any'))
    #    kpi_any_array = @predefined_kpi.select{|item| item[0]=='any'}
    #    kpi_any_array.each do |item| # checking all the KPIs for all the 'any' statements in the KPI CSV file
    #      scope_name         = item[1]
    #      report_scope_index = @aggregated_data_hash.headers.index(scope_name)
    #      yellow_threshold   = item[2]
    #      red_threshold      = item[3]
    #      report_value       = @aggregated_data_hash[report_sampler_index][report_scope_index]
    #      analyze_metric(scope_name,sampler_label_name,red_threshold,yellow_threshold,report_value)
    #    end
    #  end
    #end

    if @red_threshold_violations_count > 0
      p "Test has exceeded values"
    else 
      p "Test succeeded"
    end
  end
  
end
