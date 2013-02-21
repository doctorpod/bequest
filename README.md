# Overview

Bequest enables password, MAC address and expiry-based validation and secure data provision via a single license file.

The bequestor would run:

    Bequest::License.create('path/to/source/data', 'path/to/out/file', 
      :expires_at => Time.now + 1.year,
      :password => 'secret word or phrase',
      :mac_addr => 'bequestee:MAC:address:for:example')

Parameters:

  1. Source data file - this is the secret data you want made securely available to the client
  2. Out file - the license file that will be created

Options (at least ONE of :password or :mac_addr must be set):

  * :expires_at - time as a Ruby Time object, no expiry if omitted or set to nil
  * :password - this can be any word or phrase and will be prompted for (if set and not supplied as an option) when the license is loaded
  * :mac_addr - if set this will be read from the local machine when the bequestee loads the license if not supplied as an option

The serialised, binary license file contains a main checksum and a body. The body is composed of:

  * The encrypted expiry time
  * Password and MAC address booleans
  * The compressed, encrypted source data
  * The initialisation vector

The main checksum is of the body as a joined array, before it was serialised in the license file. It is used to validate the integrity of the license file.

The client would run:

    lic, data = Bequest::License.load('path/to/lic/file',
      :password => 'whatever', :mac_addr => 'whatever')

The password will be prompted for if set and *:password* not supplied. The first MAC address of the local machine will be used if set and *:mac_addr* not supplied. *data* will be set to nil if authentication fails or it has expired. *lic* will always be populated regardless of success and may be queried as follows:

    lic.valid?             # => true or false
    lic.expired?           # => true or false
    lic.expires_at         # => Ruby Time object
    lic.status             # => :ok, :expired, :unauthorized, or :tampered

The license file is installed at the client. This system should be used where the source data is sensitive, or should be kept secret and not readily available to the client, but is needed by the client's system. The recommended use is to keep the returned unencrypted data in memory only, and not write it to disk at any time.
