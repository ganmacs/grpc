require 'forwardable'
require_relative '../grpc'

# GRPC contains the General RPC module.
module GRPC
  class BidiCall
    def initialize(call, marshal, unmarshal)
      @call = call
    end

    def run_on_client(requests, set_output_stream_done)
      begin
        t = Thread.new do
          begin
            requests.each do |req|
              @call.remote_send(req)
            end

            # done
            @call.run_batch(SEND_CLOSE_FROM_CLIENT => nil)
          ensure
            set_output_stream_done.call
          end
        end

        @call.each_remote_read.each { |resp| yield(resp) }

        # done
        batch_result = @call.run_batch(RECV_STATUS_ON_CLIENT => nil)
        @call.status = batch_result.status
        @call.trailing_metadata = @call.status.metadata if @call.status
        GRPC.logger.debug("bidi-read-loop: done status #{@call.status}")
        batch_result.check_status
      rescue StandardError => e
        GRPC.logger.warn("bidi-write-loop: failed #{e}")
        @call.cancel_with_status(GRPC::Core::StatusCodes::UNKNOWN, "GRPC bidi call error: #{e.inspect}")

        raise e
      ensure
        t.join
      end
    end
  end
end
