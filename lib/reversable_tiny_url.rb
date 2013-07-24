require 'base62'
module ReversableTinyUrl
  PATTERNS = [
    # Photos are indicated by first bit, to maximise space for id
    # id can be up to 2**28-1 (268,435,455)
    {:regex => %r|^/(?:\d+/)?photos/(\d+)$|,        :format => '/photos/%s', :offset => 0, :length => 1, :tag => 1 },

    # Albums and users, uses next 2 bits, id can be up to 2**26-1 (67,108,863)
    {:regex => %r|^(?:/users/\d+)?/albums/(\d+)$|, :format => '/albums/%s', :offset => 1, :length => 2, :tag => 1 },
    {:regex => %r|^/users/(\d+)$|,                 :format => '/users/%s',  :offset => 1, :length => 2, :tag => 2 },
  ]

  MAX_BITS = 28

  def self.to_tiny(uri)
    unless uri.respond_to? :path
      uri = URI(uri) rescue nil
    end
    return nil unless uri

    path = ReversableTinyUrl.encode(uri.path)
    if path
      tiny_uri = URI(uri.scheme + ':/')
      tiny_uri.path = '/' + path
      if Rails.env =~ /^prod/ || uri.host == "snapmylife.com"
        tiny_uri.host = "sml.vg"
      else
        host = uri.host.match(/^(.*?).(?:snapmylife|snap2twitter).com$/)[1] rescue nil
        if host
          tiny_uri.host =  host + '.sml.vg'
        else
          tiny_uri.host = "sml.vg"
        end
      end
      tiny_uri
    else
      nil
    end
  end

  def self.to_normal(tiny_uri)
    unless tiny_uri.respond_to? :path
      tiny_uri = URI(tiny_uri) rescue nil
    end
    return nil unless tiny_uri

    path = ReversableTinyUrl.decode(tiny_uri.path[1..-1])
    if path
      uri = URI(tiny_uri.scheme + ':/')
      uri.path = path
      if Rails.env =~ /^prod/ || tiny_uri.host == "sml.vg"
        uri.host = 'www.snapmylife.com'
      else
        env = tiny_uri.host.match(/^(.*?).sml.vg$/)[1] rescue nil
        if env
          uri.host =  env + ".snapmylife.com"
        else
          uri.host = 'www.snapmylife.com' 
        end
      end
      uri
    else
      nil
    end
  end

  def self.encode(path)
    id = nil
    pattern = PATTERNS.find do |pattern|
      id = path.match(pattern[:regex])[1].to_i rescue nil
    end

    unless pattern
      return nil
    end
    # Only allow ids that fit
    if id.nil? || id > 2**(MAX_BITS - pattern[:length] - pattern[:offset])
      return nil
    end

    tag_offset = MAX_BITS - pattern[:offset] - pattern[:length]
    code = pattern[:tag] << tag_offset
    code += id
    Base62.encode(code)
  end

  def self.decode(code)
    if code.length != 5
      return nil
    end

    code = Base62.decode(code).to_i
    tag_offset = nil
    pattern = PATTERNS.find do |pattern|

      # Figure out the offset of the tag
      tag_offset = MAX_BITS - pattern[:offset] - pattern[:length]

      # Create a bitmask of the correct tag size for this pattern
      # Shift the mask so it's in the right spot
      tag_mask = ( 2**pattern[:length] - 1 ) << tag_offset

      # Apply the mask, and shift the result back
      tag = (code & tag_mask) >> tag_offset

      tag == pattern[:tag]
    end

    return nil unless pattern

    # Use mask to split out id
    id_mask = 2**tag_offset - 1
    id = code & id_mask

    pattern[:format] % id
  end
end
