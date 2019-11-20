module Foreman
  module Renderer
    module Scope
      class Report < Foreman::Renderer::Scope::Template
        extend ApipieDSL::Class

        apipie :class, desc: 'Report' do
          name 'Report'
          sections only: %w[all reports]
        end

        def initialize(**args)
          super
          @report_data = []
          @report_headers = []
        end

        # FIXME returns one_of: [:csv, :yaml] does not work
        apipie :method, desc: "Render a report for all rows defined" do
          # long_description: "This macro is typically called at the end of the report template, after all rows
          # with data has been registered.  do
          keyword :format, Array, desc: 'the desired format of output'
          returns String, desc: 'this is the resulting report'
          example "report_render # => 'name,ip\nhost1.example.com,192.168.0.2\nhost2.example.com,192.168.0.3'"
          example "report_render(format: :yaml) # => '---\n- name: host1.example.com\n  ip: 192.168.0.2\n- name: host2.example.com\n  ip: 192.168.0.3'"
        end
        def report_render(format: report_format&.id)
          case format
          when :csv, :txt, nil
            report_render_csv
          when :yaml
            report_render_yaml
          when :json
            report_render_json
          when :html
            report_render_html
          end
        end

        # TODO - add documentation
        def report_headers(*headers)
          @report_headers = headers.map(&:to_s)
        end

        apipie :method, desc: "Register a row of data for the report" do
          # long_description: "For every record that should be part of the report, +report_row+ macro needs to be called.
          # The only argument it accepts is a record definition. This is typically called in some +each+ loop. Calling
          # this at least once is important so we know what columns are to be rendered in this report.
          # Calling this macro adds a record to the rendering queue." do
          required :row_data, Hash, desc: 'data in form of hash, keys are column names, values are values for this record'
          returns Array, desc: 'currently registered report data'
          example "report_row(:name => 'host1.example.com', :ip => '192.168.0.2')"
          example "<%- load_hosts.each_record do |host|\n  report_row(:name => host.name, :ip => host.ip)\nend -%>"
        end
        def report_row(row_data)
          new_headers = row_data.keys
          if @report_headers.size < new_headers.size
            @report_headers |= new_headers.map(&:to_s)
          end
          @report_data << row_data.values
        end

        def allowed_helpers
          @allowed_helpers ||= super + [ :report_row, :report_render, :report_format, :report_headers ]
        end

        def report_format
          @params[:format]
        end

        private

        def report_render_yaml
          @report_data.map do |row|
            valid_row = row.map { |cell| valid_yaml_type(cell) }
            Hash[@report_headers.zip(valid_row)]
          end.to_yaml
        end

        def report_render_json
          @report_data.map do |row|
            valid_row = row.map { |cell| valid_json_type(cell) }
            Hash[@report_headers.zip(valid_row)]
          end.to_json
        end

        def report_render_csv
          CSV.generate(headers: true, encoding: Encoding::UTF_8) do |csv|
            csv << @report_headers
            @report_data.each do |row|
              csv << row.map { |cell| serialize_cell(cell) }
            end
          end
        end

        def report_render_html
          html = ""

          html << "<html><head><title>#{@template_name}</title><style>#{html_style}</style></head><body><table><thead><tr>"
          html << @report_headers.map { |header| "<th>#{ERB::Util.html_escape(header)}</th>" }.join('')
          html << "</tr></thead><tbody>"

          @report_data.each do |row|
            html << "<tr>"
            html << row.map { |cell| "<td>#{ERB::Util.html_escape(cell)}</td>" }.join('')
            html << "</tr>"
          end
          html << "</tbody></table></body></html>"

          html
        end

        def html_style
          <<CSS
th { background-color: black; color: white; }
table,th,td { border-collapse: collapse; border: 1px solid black; }
CSS
        end

        def serialize_cell(cell)
          if cell.is_a?(Enumerable)
            cell.map(&:to_s).join(',')
          else
            cell.to_s
          end
        end

        def valid_yaml_type(cell)
          if cell.is_a?(String) || [true, false].include?(cell) || cell.is_a?(Numeric) || cell.nil?
            cell
          elsif cell.is_a?(Enumerable)
            cell.map { |item| valid_yaml_type(item) }
          else
            cell.to_s
          end
        end

        def valid_json_type(cell)
          if cell.is_a?(String) || [true, false].include?(cell) || cell.is_a?(Numeric) || cell.nil?
            cell
          elsif cell.is_a?(Enumerable)
            hashify = cell.is_a?(Hash)
            cell = cell.map { |item| valid_json_type(item) }
            cell = cell.to_h if hashify
            cell
          else
            cell.to_s
          end
        end
      end
    end
  end
end
