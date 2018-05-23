this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(File.dirname(File.dirname(this_dir)), 'lib')
pb_dir = File.dirname(this_dir)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)
$LOAD_PATH.unshift(pb_dir) unless $LOAD_PATH.include?(pb_dir)

require 'logger'
require_relative '../../lib/grpc'
require_relative '../grpc/health/v1/health_pb.rb'
require_relative '../grpc/health/v1/health_services_pb.rb'

module RubyLogger
  def logger
    LOGGER
  end

  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::DEBUG
end

GRPC.extend(RubyLogger)

@stop = false

v = 20.times.map do |x|
  Thread.start do
    loop {
      if @stop
        GRPC.logger.info("Stop")
        break
      end

      GRPC.logger.info("request invoke")
      v = Grpc::Health::V1::Health::Stub
        .new('127.0.0.1:8000', :this_channel_is_insecure)
        .check(Grpc::Health::V1::HealthCheckRequest.new(service: 'sample'))
      GRPC.logger.info(v)
    }
  end
end

trap('INT') do
  GRPC.logger.info('Trapping SIGINT')
  @stop = true
end

v.map(&:join)
