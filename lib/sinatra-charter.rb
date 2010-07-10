# encoding: UTF-8
require 'sinatra/base'
require 'json'
require 'gruff'

module Sinatra
  module Charter
    module Helpers
      def send_chart_url(options = {})
        content_type :json

        if options[:from] == 'json'
          @chart = JSON.parse request.body.read.to_s 
        else
          @chart = params[:chart]
        end

        if File.exists? chart_path
          chart_url
        else
          self.send "render_#{@chart['kind']}_chart"
          chart_url
        end
      end

      def chart_path
        @chart_path ||= "public/charts/#{Digest::MD5.hexdigest @chart.to_s}.png"
      end

      def chart_url
        hostname = /^http:\/\/([\w\.]+).*/.match(request.url)[1]
        @chart_url ||= {"chart_url" => "http://#{hostname}/charts/#{chart_path}"}.to_json
      end

      def chart_theme
        if @chart['theme']
          {
            :colors =>            (@chart['theme']['colors']            || ['#6cb12f']),
            :marker_color =>      (@chart['theme']['marker_color']      || '#000'),
            :font_color =>        (@chart['theme']['font_color']        || '#666'),
            :background_colors => (@chart['theme']['background_colors'] || ['#fff', '#fff'])
          }
        else
          { :colors => ['#6cb12f'], :marker_color => '#000', :font_color => '#666', :background_colors => ['#fff', '#fff'] }
        end
      end

      def render_bar_chart
        g = Gruff::Bar.new(@chart['size'])
        g.theme = chart_theme
        g.title = @chart['title']
        g.labels = @chart['labels']
        @chart['data'].each { |i| g.data i.first.to_i, i.last }
        g.write chart_path
      end
    end
  end
  helpers Charter::Helpers
end
