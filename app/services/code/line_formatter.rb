module Code
  # Rouge's HTMLLinewise with ids and no trailing newline: one
  # div#L<n>.cb-line per source line, so a URL's #L12 lands on and lights it.
  class LineFormatter < Rouge::Formatter
    def initialize(html = Rouge::Formatters::HTML.new)
      @html = html
    end

    def stream(tokens)
      token_lines(tokens).with_index(1) do |line_tokens, n|
        yield %(<div id="L#{n}" class="cb-line">)
        line_tokens.each { |tok, val| yield @html.span(tok, val) }
        yield "</div>"
      end
    end
  end
end
