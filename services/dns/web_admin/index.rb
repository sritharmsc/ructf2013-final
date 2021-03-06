#!/usr/bin/ruby

require 'erb'
require 'sinatra'
require 'net/http'
require 'json'
require 'digest/md5'
require 'mysql'

show_template = ""
eval File.open('./templates/show.rb').read

add_template = ""
eval File.open('./templates/add.rb').read

set :environment, :production

def md5(s)
  return Digest::MD5.hexdigest(s)
end

r_host = '172.16.16.102'
teamN = 'team2'
r_user_name = "qqq"
r_dns_records = []
r_authored = false
r_has_records = false

dbh = Mysql.real_connect(nil, "root", nil, "dns", nil, "/home/dns/mysql/mysql.sock")

get '/add' do
  ses = request.cookies['session']
  if ses != nil
    r_host = request.host
    ses.gsub!('"', '')
    teamN = r_host[/team\d+/]
    payload = {'session' => ses}.to_json
    req = Net::HTTP::Post.new("/user/", initheader = {'X-Requested-With' => 'XMLHttpRequest', 'Content-Type' => 'application/json'})
    req.body = payload
    response = Net::HTTP.new("127.0.0.1", 80).start {|http| http.request(req) }
    r_hash = JSON.parse(response.body)

    if r_hash['status'] != 'OK'
      r_authored = false
      r_user_name = "Cheater"
    else
      r_authored = true
      r_user_name = r_hash['first_name'] + " " + r_hash['last_name'] + "!"
    end
  else
    r_authored = false
    r_user_name = "Log in!"
  end
  message = ERB.new(add_template, nil, "%")
  payload = message.result
  "#{payload}"
end

get "/show:id" do
  id = dbh.escape_string(params[:id])
  r_has_records = false
  r_dns_records = []
  res = dbh.query("Select did, dtype, dkey, dvalue from records where did = '#{id}'")
  if res.num_rows > 0
    r_has_records = true
    res.each do |row|
      r_dns_records.push([row[1] + " | " + row[2] + " -> " + row[3], row[0]])
    end
  end
  r_authored = r_has_records
  message = ERB.new(show_template, nil, "%")
  payload = message.result
  "#{payload}"
end

get "/index.html" do
  ses = request.cookies['session']
  if ses != nil
    r_host = request.host
    ses.gsub!('"', '')
    teamN = r_host[/team\d+/]
    payload = {'session' => request.cookies['session']}.to_json
    req = Net::HTTP::Post.new("/user/", initheader = {'X-Requested-With' => 'XMLHttpRequest', 'Content-Type' => 'application/json'})
    req.body = payload
    response = Net::HTTP.new("127.0.0.1", 80).start {|http| http.request(req) }
    r_hash = JSON.parse(response.body)

    if r_hash['status'] != 'OK'
      r_authored = false
    else
      r_authored = true
      r_user_name = r_hash['first_name'] + " " + r_hash['last_name'] + "!"
    end
  else
    r_authored = false
  end
  f = File.open("./templates/index.html")
  temp = f.read()
  f.close()
  message = ERB.new(temp, nil, "%")
  payload = message.result
  "#{payload}"
end

get %r{/(show)?} do
  ses = request.cookies['session']
  if ses != nil
    r_host = request.host
    ses.gsub!('"', '')
    teamN = r_host[/team\d+/]
    payload = {'session' => request.cookies['session']}.to_json
    req = Net::HTTP::Post.new("/user/", initheader = {'X-Requested-With' => 'XMLHttpRequest', 'Content-Type' => 'application/json'})
    req.body = payload
    response = Net::HTTP.new("127.0.0.1", 80).start {|http| http.request(req) }
    r_hash = JSON.parse(response.body)

    if r_hash['status'] != 'OK'
      r_authored = false
      r_has_records = false
      r_dns_records = []
      r_user_name = "Cheater"
    else
      r_authored = true
      id = dbh.escape_string(r_hash['uid'])
      r_has_records = false
      r_dns_records = []
      res = dbh.query("Select did, dtype, dkey, dvalue from records where dcreator = '#{id}'")
      if res.num_rows > 0
        r_has_records = true
        res.each do |row|
          r_dns_records.push([row[1] + " | " + row[2] + " -> " + row[3], row[0]])
        end
      end
      r_user_name = r_hash['first_name'] + " " + r_hash['last_name'] + "!"
    end
  else
    r_authored = false
    r_has_records = false
    r_dns_records = []
    r_user_name = "Log in!"
  end
  message = ERB.new(show_template, nil, "%")
  payload = message.result
  "#{payload}"
end

post '/:action' do
  data = {}
  way = "mouse"

  if request.media_type =~ /json/
    data = JSON.parse request.body.read
    way = "json"
  else
    if params[:action] == "add"
      data['type'] = request["type"]
      data['name'] = request["name"]
      data['value'] = request["value"]
    elsif params[:action] == "delete"
      data['id'] = request["id"]
    end
  end

  h = {'code' => 'ERROR', 'why' => '42'}.to_json

  ses = request.cookies['session']
  if ses != nil
    r_host = request.host
    ses.gsub!('"', '')
    teamN = r_host[/team\d+/]
    payload = {'session' => ses}.to_json
    req = Net::HTTP::Post.new("/user/", initheader = {'X-Requested-With' => 'XMLHttpRequest', 'Content-Type' => 'application/json'})
    req.body = payload
    response = Net::HTTP.new("127.0.0.1", 80).start {|http| http.request(req) }
    r_hash = JSON.parse(response.body)

    if r_hash['status'] == 'OK'
      r_user_name = r_hash['first_name'] + " " + r_hash['last_name']
      uid = r_hash['uid']

      if params[:action] != nil

        if params[:action] == "add"

          if data['type'] != nil and data['name'] != nil and data['value'] != nil
            type = dbh.escape_string(data['type'])
            name = dbh.escape_string(data['name'])
            name.sub!(/\.team\d+\.ructf$/, '')
            value = dbh.escape_string(data['value'])
            res = dbh.query("Select * from records where dtype = '#{type}' and dkey = '#{name}' and dvalue = '#{value}';")
            
            if res.num_rows == 0
              id = md5(md5(Process.pid.to_s)+md5(Time.new.to_s))
              begin
                dbh.query("insert into records (did, dtype, dkey, dvalue, dcreator) values ('#{id}', '#{type}', '#{name}', '#{value}', '#{uid}');")
              rescue Mysql::Error => e
                puts e
            end
              h = {'code' => 'OK', 'id' => id}.to_json
            else
              h = {'code' => 'ERROR', 'why' => 'already_exists'}.to_json
            end
          else
            h = {'code' => 'ERROR', 'why' => '42'}.to_json
          end

        elsif params[:action] == "delete"

          if data['id'] != nil
            id = dbh.escape_string(data['id'])
            res = dbh.query("Select * from records where did = '#{id}';")
            
            if res.num_rows > 0
              dbh.query("Delete from records where did = '#{id}';")
              h = {'code' => 'OK'}.to_json
            else
              h = {'code' => 'ERROR', 'why' => 'id_not_found'}.to_json
            end
          else
            h = {'code' => 'ERROR', 'why' => '42'}.to_json
          end
        else
          h = {'code' => 'ERROR', 'why' => '42'}.to_json
        end
      else
        h = {'code' => 'ERROR', 'why' => '42'}.to_json
      end
    else
      h = {'code' => 'ERROR', 'why' => "bad_session: "+r_hash['error']['str']}.to_json
    end
  else
    h = {'code' => 'ERROR', 'why' => 'no_session'}.to_json
  end
  if (way == "mouse" and params[:action] == "add")
    redirect "http://#{r_host}/show"
  else
    content_type "application/json"
    "#{h}"
  end
end