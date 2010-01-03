# Twitter Streaming API

require 'net/http'
require 'json'
require 'uri'

module Twitter
  class Account
    def initialize(user, pass)
      @user = user
      @pass = pass
    end

    def connection(uri, method = :get)
      uri = URI.parse(uri)
      http = Net::HTTP.new('api.twitter.com')
      req = nil
      case method
      when :get
        req = Net::HTTP::Get.new(uri.path+'?'+uri.query.to_s)
      when :post
        req = Net::HTTP::Post.new(uri.path)
        req.body = uri.query
      end
      req.basic_auth(@user.to_s, @pass.to_s)

      res = http.request(req)
      return res
    end
  end

  class User
    def initialize(usr) 
      if /^[0-9]+$/ =~ usr.to_s
        @user_id = usr.to_i
        Net::HTTP.start('twitter.com') do |h|
          r = h.get('/statuses/user_timeline/' + @user_id.to_s + '.rss')
          if /<title>Twitter \/ (.+)<\/title>/ =~ r.body
            @username = $1
          end
        end 
      else
        @username = usr
        Net::HTTP.start('twitter.com') do |h|
          r = h.get('/' + usr)
          if /<a href="\/statuses\/user_timeline\/([0-9]+).rss" class="xref rss profile-rss" rel="alternate" type="application\/rss\+xml">/ =~ r.body
            @user_id = $1.to_i
          end
        end
      end
    end

    attr_reader :user_id, :username
  end

  class Stream
    require 'twitterstream'

    def initialize(prms)
      @option = prms || {}
      @stream = TwitterStream.new(@option[:username], @option[:password])
    end

    def track(keyword)
      @stream.track(keyword) do | status |
        disp(status)
      end
    end

    def follow(followers)
      @stream.filter('follow' => followers.join(',')) do | status |
        disp(status)
      end
    end

    def disp(status)
      return unless status['text']
      username = status['user']['screen_name']
      username = username[0...12] if username.size > 15
      puts "#{status['user']['screen_name'].ljust(15)}: #{status['text']}"
    end
  end

  class List
    def initialize(user, slug, login_user, login_pass)
      @user = user
      @slug = slug
      @account = Twitter::Account.new(login_user, login_pass)
    end

    def info
      unless @info.nil?
        return @info
      else
        res = @account.connection("http://api.twitter.com/1/#{@user}/lists/#{@slug}.json")
        if res.code.to_i == 200
          res = JSON.parse(res.body)
        else
          res = nil
        end
        @info = res

        return res
      end
    end

    def membership
      unless @members.nil?
        return @members
      else
        @members = []
        cursor = '0'
        res = @account.connection("http://api.twitter.com/1/#{@user}/#{@slug}/members.json")
        res = JSON.parse(res.body)
        if res['users'].nil?
          puts res
        end
        res['users'].each do | user |
          @members << user['id']
        end
        while res['next_cursor'] != cursor
          cursor = res['next_cursor']
          res = @account.connection("http://api.twitter.com/1/#{@user}/#{@slug}/members.json?cursor=#{res['next_cursor']}")
          res = JSON.parse(res.body)
          res['users'].each do | user |
            @members << user['id']
          end
        end

        return @members
      end
    end
  end
end

# vim: tabstop=2 shiftwidth=2 softtabstop=4
