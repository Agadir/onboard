require 'forwardable'

require 'onboard/extensions/ipaddr'
require 'onboard/network/routing/route'
require 'onboard/system/command'

class OnBoard
  module Network
    class Routing
      class Table

        @@static_routes = [] unless class_variable_defined? :@@static_routes

        def self.getCurrent
          pp @@static_routes

          ary = []

          # IPv4
          `ip -f inet route`.each_line do |line| 
            ary << rawline2routeobj(line, Socket::AF_INET)
          end

          # IPv6
          `ip -f inet6 route`.each_line do |line| 
            ary << rawline2routeobj(line, Socket::AF_INET6)
          end

          return self.new(ary)
        end

        def self.rawline2routeobj(line, af=Socket::AF_INET)
          case af
          when Socket::AF_INET # IPv4
            if line =~ /^(\S+)\s+via\s+(\S+)\s+dev\s+(\S+)/
              gw = IPAddr.new($2) # for some reasons global captures disappear
              dev = $3 # keep as a string
              if $1 == "default"  
                dest = IPAddr.new("0.0.0.0/0")
                rawline = line.sub('default', '0.0.0.0/0').strip
              else
                dest = IPAddr.new($1)
                rawline = line.strip
              end
              return Route.new( 
                :dest     => dest,
                :gw       => gw,
                :dev      => dev,
                :rawline  => rawline
              )
            elsif line =~ /^(\S+)\s+dev\s+(\S+)/
              deststr = $1
              dev = $2
              if deststr.strip == "default"
                dest = IPAddr.new("0.0.0.0/0")
                rawline = line.sub('default', '0.0.0.0/0').strip
                deststr = "0.0.0.0/0"
              else
                dest = IPAddr.new(deststr)
                rawline = line.strip
              end
              return Route.new( 
                :dest => IPAddr.new(deststr),
                :gw   => IPAddr.new("0.0.0.0"),
                :dev  => dev,
                :rawline  => rawline
              ) 
            end
          when Socket::AF_INET6 # IPv6
            if line =~ /^(\S+)\s+via\s+(\S+)\s+dev\s+(\S+)/ 
              gw = IPAddr.new($2)
              dev = $3
              if $1 == "default"
                dest = IPAddr.new("::/0")
                rawline = line.sub('default', '::/0').strip
              else
                dest = IPAddr.new($1)
                rawline = line.strip
              end
              ary << Route.new( 
                :dest => dest,
                :gw   => gw,
                :dev  => dev,
                :rawline  => rawline
              )
            elsif line =~ /^(\S+)\s+dev\s+(\S+)/
              if $1 == "default"
                dest = IPAddr.new("::/0")
                rawline = line.sub('default', '::/0').strip
              else
                dest = IPAddr.new($1)
                rawline = line.strip
              end
              return Route.new(
                :dest => dest,
                :gw   => IPAddr.new("::"),
                :dev  => $2, # keep as a string
                :rawline  => rawline
              ) 
            end
          else 
            raise ArgumentError, "af must be either Socket::AF_INET or Socket::AF_INET6, got #{af}" 
          end
        end
       
        
        def self.ip_route_del(str)
          OnBoard::System::Command.run "ip route del #{str}", :sudo
        end

        def self.ip_route_add(str, *opts) # opts may include :try
          if opts.include? :try
            return \
                OnBoard::System::Command.run "ip route add #{str}", :sudo, :try
          else
            return \
                OnBoard::System::Command.run "ip route add #{str}", :sudo
          end
        end

        def self.ip_route_change(str)
          OnBoard::System::Command.run "ip route change #{str}", :sudo
        end

        def self.route_from_HTTP_request(params) # create new or change
          str = ""
          if params['prefixlen'] =~ /^\s*$/
            if params['ip'] =~ /\//
              str << params['ip'] << ' '
            elsif params['ip'] =~ /^\s*(0\.0\.0\.0|::)\s*$/
              str << params['ip'] << '/0 '
            elsif params['ip'] =~ /^[^\w\d]*(default)?[^\w\d]*$/ 
              str << "default "
            end
          else # a prefix length in CIDR notation has been provided
            str << params['ip'] << '/' << params['prefixlen'] << ' '
          end
          str << "via #{params['gw']} "   if params['gw']   =~ /[\da-f:]/i
          str << "dev #{params['dev']} "  if params['dev']  =~ /\S/
          result = self.ip_route_add(str.strip, :try)
          if not result[:ok] 
            if result[:stderr] =~ /file exists/i
              LOGGER.info "Retrying \"ip route change #{str.strip}\""
              result = self.ip_route_change(str.strip) 
            else
              LOGGER.error \
                  "Couldn't add route as requested (see messages above)"
            end
          end
          if result[:ok]
            @@static_routes << rawline2routeobj(str)
          end
          return result
        end

        attr_reader :routes

        def initialize(ary)
          @routes = ary
        end

        def data
          @routes.map {|x| x.data} 
        end

        extend Forwardable
        def_delegator :@routes, :each, :each_route

      end
    end
  end
end
