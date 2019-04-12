class TigerLogger

  require 'logger'

  def initialize(log_file_path)
    @logger=Logger.new("#{log_file_path}/tiger_framework.log")
  end

  def info(message)
    puts "INFO: #{message}"
    @logger.info message
  end

  def warn(message)
    puts "INFO: #{message}"
    @logger.warn message
  end

  def error(message)
    puts "ERROR: #{message}"
    @logger.error message
  end

  def fatal(message)
    puts "INFO: #{message}"
    @logger.fatal message
  end

  def close
    puts "Closing logger"
    @logger.close
  end
end

