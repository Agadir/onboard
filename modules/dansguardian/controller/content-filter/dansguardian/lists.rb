require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    %w{
      /content-filter/dansguardian/lists/*/*/*.:format
      /content-filter/dansguardian/lists/*/*.:format
    }.each do |path| # Order matters.
      #
      # Example: /content-filter/dansguardian/lists/banned/sites/sub1/sub2.html
      # You get params[:splat] #=> ["banned", "sites", "sub1/sub2" ]
      #
      # Example: /content-filter/dansguardian/lists/banned/sites.html
      # You get params[:splat] #=> ["banned", "sites"]
      get path do
        format(
          :path     => '/content-filter/dansguardian/lists',
          :module   => 'dansguardian',
          :title    => 
              "DansGuardian: #{ContentFilter::DG::List.title(params[:splat])}",
          :format   => params[:format],
          :objects  => ContentFilter::DG::List.ls(params[:splat]) 
        )
      end

    end
   
  end
end
