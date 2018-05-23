this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(File.dirname(File.dirname(this_dir)), 'lib')
pb_dir = File.dirname(this_dir)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)
$LOAD_PATH.unshift(pb_dir) unless $LOAD_PATH.include?(pb_dir)
$LOAD_PATH.unshift(this_dir) unless $LOAD_PATH.include?(this_dir)

require 'logger'
require_relative '../../lib/grpc'
require_relative '../grpc/health/v1/health_pb.rb'
require_relative '../grpc/health/v1/health_services_pb.rb'
require_relative '../grpc/health/checker.rb'

module RubyLogger
  def logger
    LOGGER
  end

  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::DEBUG
end
GRPC.extend(RubyLogger)

health_checker = Grpc::Health::Checker.new
health_checker.add_status('sample', Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)

s = GRPC::RpcServer.new
s.add_http2_port('127.0.0.1:8000', :this_port_is_insecure)
s.handle(health_checker)

stop_server = false
stop_server_cv = ConditionVariable.new
stop_server_mu = Mutex.new

stop_server_thread = Thread.new do
  loop do
    break if stop_server
    stop_server_mu.synchronize { stop_server_cv.wait(stop_server_mu, 60) }
  end
  GRPC.logger.info('Stopping...')
  s.stop
end

trap('INT') do
  GRPC.logger.info('Trapping SIGINT')

  stop_server = true
  stop_server_cv.broadcast
end

trap('TERM') do
  GRPC.logger.info('Trapping SIGTERM')

  stop_server = true
  stop_server_cv.broadcast
end

s.run_till_terminated
stop_server_thread.join
