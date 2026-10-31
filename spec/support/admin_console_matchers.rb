# The /root console screens' shared assertion (console-ui-for-all-admin,
# 2026-10-30): the page under the admin chrome is one .console--root
# carrying nothing from the legacy kit — no <style> / style="", no TuiCss
# window / button / table, no dead data-turbo-confirm (the admin has no
# Turbo), no fallback glyphs (the Terminus subset has no arrows —
# gotchas). The screen is the body after the chrome's </header> up to
# the layout's trailing script (admin/shared/_sortable_tables, gone with
# Phase 6); a screen with its own inline script passes the slice it
# wants checked instead of the whole body.
module AdminConsoleMatchers
  LEGACY = ["<style", 'style="', "tui-window", "tui-button", "tui-table", "data-turbo-confirm"].freeze
  GLYPHS = /[←→▾⚑✓⚠]/
end

RSpec::Matchers.define :be_console_clean do
  match do |body|
    screen = body.split("</header>", 2).last.split("<script", 2).first
    @missing_root = !screen.include?('class="console console--root"')
    @hits = AdminConsoleMatchers::LEGACY.select { |needle| screen.include?(needle) }
    @hits << "glyph #{screen[AdminConsoleMatchers::GLYPHS]}" if screen.match?(AdminConsoleMatchers::GLYPHS)
    !@missing_root && @hits.empty?
  end

  failure_message do
    parts = []
    parts << "no .console--root under the chrome" if @missing_root
    parts << "legacy kit on the screen: #{@hits.join(", ")}" if @hits.any?
    "expected a clean /root console screen — #{parts.join("; ")}"
  end
end
