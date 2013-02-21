require 'rubygems'
require 'openssl'
require 'digest/sha2'
require 'digest/md5'
require 'zlib'
require 'macaddr'

module Bequest
  class Data
    def initialize(secret_data, opts = {})
      opts = {:expires_at => nil, :password => '', :mac_addr => ''}.merge(opts)
      compressed = Zlib::Deflate.deflate(secret_data)
      key = key(opts[:password], opts[:mac_addr])
      iv = Digest::MD5.hexdigest(rand.to_s)
      encrypted_data = encrypt(compressed, key, iv)
      encrypted_expires_at = opts[:expires_at] ? encrypt(opts[:expires_at].to_i.to_s, key, iv) : nil

      body = [encrypted_expires_at, opts[:password].any?, opts[:mac_addr].any?, encrypted_data, iv]
      checksum = Digest::MD5.hexdigest(body.join)
      @data = [checksum, body]
    end
    
    def dump(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w") { |f| f.write(Marshal::dump(self)) }
    end

    def unpack(password, mac_addr)
      password = prompt_if_required(password)
      mac_addr = get_if_required(mac_addr)

      if Digest::MD5.hexdigest(body.join) == checksum
        compressed = decrypt(encrypted_data, key(password, mac_addr), iv)

        begin
          data = Zlib::Inflate.inflate(compressed)

          if encrypted_expires_at
            expires_at = Time.at(decrypt(encrypted_expires_at, key(password, mac_addr), iv).to_i)

            if expires_at.to_i < Time.now.to_i
              [nil, :expired, expires_at]
            else
              [data, :ok, expires_at]
            end
          else
            [data, :ok, nil]
          end
        rescue
          [nil, :unauthorized, nil]
        end
      else
        [nil, :tampered, nil]
      end
    end

    private
    
    def checksum
      @data[0]
    end
    
    def body
      @data[1]
    end

    def encrypted_expires_at
      body[0]
    end
    
    def need_password?
      body[1]
    end
    
    def need_mac_addr?
      body[2]
    end

    def encrypted_data
      body[3]
    end
    
    def iv
      body[4]
    end
    
    def prompt_if_required(password)
      if need_password? && password.nil?
        STDOUT.puts "Password: "
        STDOUT.flush
        gets.chomp
      else
        password
      end
    end

    def get_if_required(mac_addr)
      if need_mac_addr? && mac_addr.nil?
        Mac.addr
      else
        mac_addr
      end
    end
    
    def key(password, mac_addr)
      sha256 = Digest::SHA2.new(256)
      sha256.digest(
        'ZggthtmuGfDWy4D' + (password || '') + 'gt5gIrfMcgyb8ii' + (mac_addr || '') + 'C1pq3gi65SX2ckx'
      )
    end

    def encrypt(data, key, iv)
      aes = OpenSSL::Cipher.new("AES-256-CFB")
      aes.encrypt
      aes.key = key
      aes.iv = iv
      aes.update(data) + aes.final
    end

    def decrypt(data, key, iv)
      aes = OpenSSL::Cipher.new("AES-256-CFB")
      aes.decrypt
      aes.key = key
      aes.iv = iv
    
      begin
        aes.update(data) + aes.final
      rescue
        false
      end
    end
  end
  
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