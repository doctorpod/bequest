module Bequest
  class License
    attr_reader :expires_at, :status
    
    def initialize(status, expires_at)
      @status = status
      @expires_at = expires_at
    end
  
    class << self
      def create(data_path, out_path, opts = {})
        if (opts[:password]||'').any? || (opts[:mac_addr]||'').any?
          Data.new(File.read(data_path), opts).dump(out_path)
        else
          puts "At least ONE of password or mac_addr required"
        end
      end

      def load(lic_file_path, opts = {})
        begin
          data = Marshal::load(File.read(lic_file_path))
          original_data, status, expires_at = data.unpack(opts[:password], opts[:mac_addr])
          [self.new(status, expires_at), original_data]
        rescue
          [self.new(:tampered, nil), nil]
        end
      end
    end
    
    def valid?
      @status == :ok
    end
  
    def expired?
      expires_at ? expires_at < Time.now : nil
    end
  end
end