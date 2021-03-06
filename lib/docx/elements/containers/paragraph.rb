
module Docx
  module Elements
    module Containers
      class Paragraph < Container
        def self.tag
          'p'
        end

        # Child elements: pPr, r, fldSimple, hlink, subDoc
        # http://msdn.microsoft.com/en-us/library/office/ee364458(v=office.11).aspx
        def initialize(node, document_properties = {})
          @node = node
          @properties_tag = 'pPr'
          @document_properties = document_properties
          @font_size = @document_properties[:font_size]
        end

        # Set text of paragraph
        def text=(content)
          if text_runs.size == 1
            text_runs.first.text = content
          elsif text_runs.empty?
            new_r = Run.create_within(self)
            new_r.text = content
            self.style = style if style
          else
            text_runs.each { |r| r.node.remove }
            new_r = Run.create_within(self)
            new_r.text = content
            self.style = style if style
          end
        end

        def style
          @node.at_xpath('.//w:rPr')
        end

        def style=(args)
          text_runs.each do |tr|
            tr.style = args
          end
        end

        def copy_styles(paragraph)
          self.style = paragraph.style
        end

        # Return text of paragraph
        def to_s
          text_runs.map(&:text).join('')
        end

        # Return paragraph as a <p></p> HTML fragment with formatting based on properties.
        def to_html
          html = ''
          text_runs.each do |text_run|
            html << text_run.to_html
          end
          styles = { 'font-size' => "#{font_size}pt" }
          styles['text-align'] = alignment if alignment
          html_tag(:p, content: html, styles: styles)
        end

        # Array of text runs contained within paragraph
        def text_runs
          @node.xpath('w:r|w:hyperlink/w:r').map { |r_node| Containers::Run.new(r_node, @document_properties) }
        end

        # Iterate over each text run within a paragraph
        def each_text_run
          text_runs.each { |tr| yield(tr) }
        end

        def aligned_left?
          ['left', nil].include?(alignment)
        end

        def aligned_right?
          alignment == 'right'
        end

        def aligned_center?
          alignment == 'center'
        end

        def font_size
          size_tag = @node.xpath('w:pPr//w:sz').first
          size_tag ? size_tag.attributes['val'].value.to_i / 2 : @font_size
        end

        alias text to_s

        protected

        def style_tags
          r.at_xpath('./w:rPr') || r.add_child(Nokogiri::XML::Node.new('w:rPr', @node))
        end

        # Returns the alignment if any, or nil if left
        def alignment
          alignment_tag = @node.xpath('.//w:jc').first
          alignment_tag ? alignment_tag.attributes['val'].value : nil
        end
      end
    end
  end
end

Dir["#{__dir__}/paragraphs/*.rb"].each do |paragraph|
  require paragraph
end
