def sandbox
  File.expand_path(File.join('..', '..', 'sandbox'), __FILE__)
end

def set_sandbox
  system "rm -fr #{sandbox} && mkdir #{sandbox}"
end

