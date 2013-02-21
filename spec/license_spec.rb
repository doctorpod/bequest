require 'bequest'
require 'helper'

module Bequest
  describe License do
    before(:each) do
      set_sandbox
      @lic_file = './sandbox/lic.dat'
      @tampered_lic_file = './samples/tampered_lic.dat'
      @tampered_checksum_lic_file = './samples/tampered_checksum_lic.dat'
      @data_file = './samples/secret.txt'
      @soon = Time.now + 10
      @just_passed = Time.now - 10
      @password = 'secret'
      @mac_addr = 'mac:addr'
    end
  
    describe "Bequester makes a new license" do
      before(:each) do
        License.create(@data_file, @lic_file, :expires_at => @soon, :password => @password)
        @lic, data = License.load(@lic_file, :password => @password)
      end
      
      it "creates a file" do
        File.exist?(@lic_file).should be_true
      end
      
      it "has a correct expiry time" do
        @lic.expires_at.to_i.should == @soon.to_i
      end

      it "requires at least ONE of password or mac_addr" do
        @lic = License.create(@data_file, @lic_file)
        @lic.should be_nil
      end

      it "requires at least ONE of password or mac_addr to have a length" do
        @lic = License.create(@data_file, @lic_file, :password => '')
        @lic.should be_nil
      end
    end
  
    describe "Bequestee loads an 'in date', password protected license file" do
      before(:each) do
        License.create(@data_file, @lic_file, :expires_at => @soon, :password => @password)
      end

      describe "Correct password supplied" do
        before(:each) do
          @lic, @data = License.load(@lic_file, :password => @password)
        end
          
        it "should be a license" do
          @lic.class.should == License
        end
          
        it "should be valid" do
          @lic.valid?.should be_true
        end
          
        it "status should be OK" do
          @lic.status.should == :ok
        end
          
        it "has a correct expiry time" do
          @lic.expires_at.to_i.should == @soon.to_i
        end
      
        it "should not be expired" do
          @lic.expired?.should == false
        end
      
        it "should yield original data" do
          @data.should == File.read(@data_file)
        end
      end
    
      describe "Wrong password supplied" do
        before(:each) do
          @lic, @data = License.load(@lic_file, :password => 'plainly wrong')
        end
          
        it "should not be valid" do
          @lic.valid?.should be_false
        end
          
        it "status should be unauthorized" do
          @lic.status.should == :unauthorized
        end
          
        it "should have a nil expiry time" do
          @lic.expires_at.should be_nil
        end
      
        it "expired? should be nil" do
          @lic.expired?.should be_nil
        end
      
        it "should yield no data" do
          @data.should be_nil
        end
      end

      describe "No password supplied" do
        it "should prompt" do
          STDOUT.should_receive(:puts).with("Password: ")
          @lic, @data = License.load(@lic_file)
        end
      end
    end
  
    describe "Bequestee loads an expired, password protected license file" do
      before(:each) do
        lic = License.create(@data_file, @lic_file, :expires_at => @just_passed, :password => @password)
        @lic, @data = License.load(@lic_file, :password => @password)
      end
    
      it "should not be valid" do
        @lic.valid?.should be_false
      end
        
      it "status should be expired" do
        @lic.status.should == :expired
      end
        
      it "should have correct expiry time" do
        @lic.expires_at.to_i.should == @just_passed.to_i
      end
    
      it "expired? should be true" do
        @lic.expired?.should be_true
      end
    
      it "should yield no data" do
        @data.should be_nil
      end
    end
    
    describe "Bequestee loads a password protected license file with a tampered body" do
      before(:each) do
        @lic, @data = License.load(@tampered_lic_file, :password => @password)
      end
    
      it "should not be valid" do
        @lic.valid?.should be_false
      end
        
      it "status should be tampered" do
        @lic.status.should == :tampered
      end
        
      it "should have nil expiry time" do
        @lic.expires_at.should be_nil
      end
    
      it "expired? should be nil" do
        @lic.expired?.should be_nil
      end
    
      it "should yield no data" do
        @data.should be_nil
      end
    end
    
    describe "Bequestee loads a password protected license file with a tampered checksum" do
      before(:each) do
        @lic, @data = License.load(@tampered_checksum_lic_file, :password => @password)
      end
    
      it "should not be valid" do
        @lic.valid?.should be_false
      end
        
      it "status should be tampered" do
        @lic.status.should == :tampered
      end
        
      it "should have nil expiry time" do
        @lic.expires_at.should be_nil
      end
    
      it "expired? should be nil" do
        @lic.expired?.should be_nil
      end
    
      it "should yield no data" do
        @data.should be_nil
      end
    end

    describe "Bequestee loads an imortal, password protected license file" do 
      before(:each) do
        lic = License.create(@data_file, @lic_file, :password => @password)
        @lic, @data = License.load(@lic_file, :password => @password)
      end

      it "should be valid" do
        @lic.valid?.should be_true
      end
        
      it "status should be ok" do
        @lic.status.should == :ok
      end
        
      it "should have nil expiry time" do
        @lic.expires_at.should be_nil
      end
    
      it "expired? should be nil" do
        @lic.expired?.should be_nil
      end
    
      it "should yield original data" do
        @data.should == File.read(@data_file)
      end
    end
    
    describe "Bequestee loads an imortal, MAC protected (for bequestee machine) license file" do
      before(:each) do
        lic = License.create(@data_file, @lic_file, :mac_addr => Mac.addr)
      end
      
      describe "no MAC supplied" do
        before(:each) do
          @lic, @data = License.load(@lic_file)
        end
        
        it "should be valid" do
          @lic.valid?.should be_true
        end

        it "status should be ok" do
          @lic.status.should == :ok
        end

        it "should yield original data" do
          @data.should == File.read(@data_file)
        end
      end
      
      describe "Wrong MAC supplied" do
        before(:each) do
          @lic, @data = License.load(@lic_file, :mac_addr => 'very:wrong:mac:addr:indeed')
        end
        
        it "should not be valid" do
          @lic.valid?.should be_false
        end
          
        it "status should be unauthorized" do
          @lic.status.should == :unauthorized
        end
          
        it "should have a nil expiry time" do
          @lic.expires_at.should be_nil
        end
      
        it "expired? should be nil" do
          @lic.expired?.should be_nil
        end
      
        it "should yield no data" do
          @data.should be_nil
        end
      end
    end
  end
end