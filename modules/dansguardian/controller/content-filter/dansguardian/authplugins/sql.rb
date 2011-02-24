require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    get '/content-filter/dansguardian/authplugins/sql/db.:format' do
      sqlauth = ::DansGuardian::Config::Auth::SQL.new
      data    = ::DansGuardian::Parser.read_file (
        ::OnBoard::ContentFilter::DG::AuthPlugin.config_file(:sql) 
      )
      sqlauth.load data
      format(
        :path     => '/content-filter/dansguardian/authplugins/sql/db',
        :module   => 'dansguardian',
        :title    => "DansGuardian: SQL/RADIUS Authentication",
        :format   => params[:format],
        :objects  => sqlauth  
      )
    end

    put '/content-filter/dansguardian/authplugins/sql/db.:format' do
      # pp params

      file = ::OnBoard::ContentFilter::DG::AuthPlugin.config_file(:sql)
      u = {}
      %w{
        sqlauthdb sqlauthdbhost sqlauthdbuser sqlauthdbpass 
        sqlauthipuserquery sqlauthusergroupquery
      }.each do |name|
        u[name] = %Q{'#{params[name]}'} if params[name] =~ /\S/
      end
      ::DansGuardian::Updater.update! file, u

      sqlauth = ::DansGuardian::Config::Auth::SQL.new
      data    = ::DansGuardian::Parser.read_file file
      sqlauth.load data
      format(
        :path     => '/content-filter/dansguardian/authplugins/sql/db',
        :module   => 'dansguardian',
        :title    => "DansGuardian: SQL/RADIUS Authentication",
        :format   => params[:format],
        :objects  => sqlauth  
      )
    end

    get '/content-filter/dansguardian/authplugins/sql/groups.:format' do
      
      dg = OnBoard::ContentFilter::DG.new
      dgconf = dg.config
      fgnames = {}
      1.upto dgconf.main[:filtergroups] do |fgid|
        next if dg.deleted_filtergroups.include? fgid
        fgnames[fgid] = dgconf.filtergroup(fgid)[:groupname] 
      end

      sqlauth_data      = ::DansGuardian::Parser.read_file (
        ::OnBoard::ContentFilter::DG::AuthPlugin.config_file(:sql) 
      )
      sqlauth_groupfile = sqlauth_data[:sqlauthgroups] 
      sqlgroups_data    = ::DansGuardian::Parser.read_file sqlauth_groupfile

      groups = {}
      sqlgroups_data.each_pair do |radgroup, fgstring|
        groups[radgroup.to_s] = fgstring.sub('filter', '').to_i
      end

      format(
        :path     => '/content-filter/dansguardian/authplugins/sql/groups',
        :module   => 'dansguardian',
        :title    => "DansGuardian: SQL/RADIUS Authentication",
        :format   => params[:format],
        :objects  => {
          :fgnames    => fgnames,
          :groups     => groups
        }  
      )
    end

    put '/content-filter/dansguardian/authplugins/sql/groups.:format' do
      dg = OnBoard::ContentFilter::DG.new
      dgconf = dg.config
      fgnames = {}
      1.upto dgconf.main[:filtergroups] do |fgid|
        next if dg.deleted_filtergroups.include? fgid
        fgnames[fgid] = dgconf.filtergroup(fgid)[:groupname] 
      end

      sqlauth_data      = ::DansGuardian::Parser.read_file (
        ::OnBoard::ContentFilter::DG::AuthPlugin.config_file(:sql) 
      )
      sqlauth_groupfile = sqlauth_data[:sqlauthgroups] 
      
      # REWRITE THE FILE
      File.open sqlauth_groupfile, 'w' do |f|
        f.puts "# Auto-generated by #{self.class} ."
        params['groups'].each do |group_h|
          f.puts "#{group_h['sqlname']} = filter#{group_h['fgid']}" if
              group_h['sqlname'] =~ /\S/ and 
              group_h['fgid'].to_i > 0
        end
      end

      sqlgroups_data    = ::DansGuardian::Parser.read_file sqlauth_groupfile

      groups = {}
      sqlgroups_data.each_pair do |radgroup, fgstring|
        groups[radgroup.to_s] = fgstring.sub('filter', '').to_i
      end

      format(
        :path     => '/content-filter/dansguardian/authplugins/sql/groups',
        :module   => 'dansguardian',
        :title    => "DansGuardian: SQL/RADIUS Authentication",
        :format   => params[:format],
        :objects  => {
          :fgnames    => fgnames,
          :groups     => groups
        }  
      )
    end
  
  end
end
