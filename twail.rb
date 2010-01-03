#!/bin/env ruby -Ku

$: << File.dirname(File.expand_path(__FILE__)) + '/lib'
require 'rubygems'
require 'optparse'
require 'json'
require 'highline'
require 'twitter-streaming'

# set version
Appname = "Twail"
Version = '0.1a'

# default settings
options = {
  :username => nil,
  :password => nil,
  :autofollow => true,
  :followers => [],
  :followers_str => []
}

# cmdline opt
begin
  OptionParser.new { | opt |
    ## set user name
    opt.on('-u VAL', '--username=VAL', 'your twitter account(@username) *require') { | v | 
      options[:username] = v if v.kind_of?(String)
    }
    ## set followers
    # opt.on('-f VAL', '--followers=VAL', 'followers setting') { | v | 
    #   if v
    #     options[:followers] = v.split(/\s*,\s*/)
    #     raise OptionParser::InvalidOption, 'followers over limits(max 200)' if options[:followers].size > 200
    #   end
    # }
    ## set keyword
    opt.on('-k VAL', '--keyword=VAL', 'set follow keyword') { | v |
      if v
        options[:keyword] = v
      end
    }
    ## set list
    opt.on('-l VAL', '--list=VAL', 'set follow list(user/slug)') { | v |
      if v
        v = v.split('/')
        options[:list] = {
          :user => v[0],
          :slug => v[1]
        }
      end
    }
    opt.on('-f VAL', '--follow=VAL', 'set follow user (username,username,username...)') { | v |
        if v
            options[:followers_str] = v.split(',')
        end
    }
  }.parse!(ARGV)
  ## exception
  raise OptionParser::InvalidOption, "user name is missing" if options[:username].nil?
rescue OptionParser::InvalidOption => e
  puts e.message
  exit(-1)
end

# set password
hl = HighLine.new
options[:password] = hl.ask('password> ') { | inp | inp.echo = '*' }

# Start Stream
stream = Twitter::Stream.new(options)
if !options[:followers_str].empty?
  options[:followers] = options[:followers_str].map{ |u| a = Twitter::User.new(u);p a;a.user_id }
  puts 'Start Streaming...'
  stream.follow(options[:followers])
elsif !options[:list].nil?
  list = Twitter::List.new(options[:list][:user], options[:list][:slug], options[:username], options[:password])
  options[:followers] = list.membership

  puts 'Start Streaming...'
  stream.follow(options[:followers])
elsif !options[:keyword].nil?
  puts 'Start Streaming...'
  stream.track(options[:keyword])
end
