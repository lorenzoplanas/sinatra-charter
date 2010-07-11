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

        if File.exists? chart_full_path
          chart_url
        else
          self.send "render_#{@chart['kind']}_chart"
          chart_url
        end
      end

      def charts_dir
        @charts_dir ||= "public/charts"
      end

      def chart_file_name
        @chart_file_name ||= "#{Digest::MD5.hexdigest @chart.to_s}.png"
      end

      def chart_full_path
        @chart_full_path ||= File.join(charts_dir, chart_file_name)
      end

      def chart_url
        hostname = /^http:\/\/([\w\.]+).*/.match(request.url)[1]
        @chart_url ||= {"chart_url" => "http://#{hostname}/charts/#{chart_file_name}"}.to_json
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

      def render_bar_chart(options = {})
        labels = {}
        @chart['labels'].each_pair {|k,v| labels[k.to_i] = v}
        g = Gruff::Bar.new(@chart['size'])
        g.theme = chart_theme
        g.title = @chart['title']
        g.labels = labels
        g.data @chart['data'].first, @chart['data'].last.map(&:to_i)
        g.bar_spacing = 0.8
        options.each_pair { |k, v| g.send :"#{k}=", v }
        g.write chart_full_path
      end

      def render_hbar_chart(options = {})
        labels = {}
        @chart['labels'].each_pair {|k,v| labels[k.to_i] = v}
        g = Gruff::SideBar.new(@chart['size'])
        g.theme = chart_theme
        g.title = @chart['title']
        g.labels = labels
        #g.data @chart['data'].last.map(&:to_i)
        g.data 1,4
        g.data 1,2
        options.each_pair { |k, v| g.send :"#{k}=", v }
        g.write chart_full_path
      end

      def render_pie_chart(options = {})
        labels = {}
        @chart['labels'].each_pair {|k,v| labels[k.to_i] = v}
        g = Gruff::Pie.new(@chart['size'])
        g.theme_pastel
        g.title = @chart['title']
        g.labels = labels
        labels.each_with_index {|label, i| g.data label[i], @chart['data'].last[i]}
        #options.each_pair { |k, v| g.send :"#{k}=", v } 
        g.write chart_full_path
      end
    end
  end
  helpers Charter::Helpers
end
