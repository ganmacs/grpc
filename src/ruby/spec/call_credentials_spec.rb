# Copyright 2015 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe GRPC::Core::CallCredentials do
  let(:auth_proc) { proc { { 'plugin_key' => 'plugin_value' } } }

  describe '#new' do
    it 'can successfully create a CallCredentials from a proc' do
      expect { described_class.new(auth_proc) }.not_to raise_error
    end
  end

  describe '#compose' do
    it 'can compose with another described_class' do
      creds1 = described_class.new(auth_proc)
      creds2 = described_class.new(auth_proc)
      expect { creds1.compose creds2 }.not_to raise_error
    end

    it 'can compose with multiple described_class' do
      creds1 = described_class.new(auth_proc)
      creds2 = described_class.new(auth_proc)
      creds3 = described_class.new(auth_proc)
      expect { creds1.compose(creds2, creds3) }.not_to raise_error
    end
  end
end
