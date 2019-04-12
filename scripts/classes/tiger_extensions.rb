class TigerExtension
  # encoding: utf-8
  require 'pathname'
  require 'fileutils'

  def initialize (jmeter_jmx_path,tiger_extensions_path)
    @jmeter_jmx_path=jmeter_jmx_path
    @tiger_extensions_path=tiger_extensions_path    
  end

  def extend_jmeter_jmx(data_folder_path)
    $logger.info "Extending JMeter scenario #{@jmeter_jmx_path} with #{@tiger_extensions_path} content"
    tiger_extension=File.read(@tiger_extension_path)
    xml_cont=File.read(@jmeter_jmx_path).encode('UTF-8', :invalid => :replace)
    xml_ar=xml_cont.split(/<\/TestPlan>\W+<hashTree>/)
    xml_modified=xml_ar[0]+"    </TestPlan>\n    <hashTree>\n"+tiger_extension+xml_ar[1]
    jmx_path= Pathname.new(@jmeter_jmx_path)
    jmx_file_name=jmx_path.basename.to_s
    merged_file_name=jmx_file_name.gsub(".jmx","_merged.jmx")
    File.write("#{jmx_path.dirname}/#{merged_file_name}",xml_modified)
    FileUtils.cp "#{jmx_path.dirname}/#{merged_file_name}",data_folder_path
    FileUtils.cp @jmeter_jmx_path,data_folder_path
    FileUtils.cp "#{@tiger_extensions_path}/jmeter/tiger_extension.jmx",data_folder_path
    return "#{jmx_path.dirname}/#{merged_file_name}"
  end

end

