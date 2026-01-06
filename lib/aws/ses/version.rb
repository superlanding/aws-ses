module AWS
  module SES
    module VERSION #:nodoc:
      MAJOR    = '1'
      MINOR    = '0'
      TINY     = '0' 
      BETA     = Time.now.to_i.to_s
    end
    
    Version = [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY, VERSION::BETA].compact * '.'
  end
end
