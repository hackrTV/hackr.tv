# frozen_string_literal: true

module Terminal
  # Easter eggs and hidden commands for the terminal
  # Provides immersive cyberpunk responses and effects
  class EasterEggs
    include ANSI

    # GovCorp intercept messages shown randomly on connection
    INTERCEPT_MESSAGES = [
      "NOTICE: This connection is monitored by GovCorp Security Division.",
      "WARNING: Unauthorized network access detected. Logging initiated.",
      "ALERT: Fracture Network signatures detected. Surveillance active.",
      "CAUTION: Your neural patterns have been catalogued. Proceed accordingly.",
      "ADVISORY: GovCorp reminds you: Privacy is a privilege, not a right.",
      "NOTICE: Signal triangulation in progress. Location data archived.",
      "WARNING: Anomalous encryption detected. Decryption protocols engaged.",
      "ALERT: This terminal has been flagged for enhanced monitoring.",
      "NOTICE: Your digital footprint is being preserved for analysis.",
      "ADVISORY: Remember - GovCorp protects. GovCorp provides. GovCorp watches."
    ].freeze

    # Fake system files for the "hacking" interface
    FAKE_FILES = [
      "shadow.db", "passwd.enc", "root.key", "admin.cred", "govcorp.dat",
      "fracture.net", "pulse.cfg", "grid.sys", "hackr.key", "neural.map",
      "security.log", "access.lst", "decrypt.bin", "exploit.sh", "backdoor.exe"
    ].freeze

    # Hackr movie-style scrolling text
    HACKR_OUTPUTS = [
      "Bypassing firewall...",
      "Injecting payload...",
      "Decrypting access tokens...",
      "Spoofing neural signature...",
      "Uploading exploit...",
      "Cracking encryption layer...",
      "Escalating privileges...",
      "Masking connection origin...",
      "Extracting credentials...",
      "Patching security hole..."
    ].freeze

    # Matrix-style characters
    MATRIX_CHARS = ("ァ".."ン").to_a + ("0".."9").to_a + %w[@ # $ % & * = + - ~]

    class << self
      # Check if input is an easter egg command
      # @param input [String] User input
      # @return [Boolean] True if easter egg was triggered
      def handle?(input)
        normalized = input.downcase.strip
        COMMANDS.key?(normalized) || normalized.start_with?("//")
      end

      # Execute an easter egg command
      # @param session [Session] The terminal session
      # @param input [String] User input
      # @return [Boolean] True if handled
      def execute(session, input)
        normalized = input.downcase.strip

        # Handle glitch command
        if normalized.start_with?("//")
          glitch_command(session, input[2..])
          wait_for_continue(session)
          return true
        end

        command = COMMANDS[normalized]
        return false unless command

        send(command, session)
        wait_for_continue(session)
        true
      end

      # Get a random GovCorp intercept message
      # @return [String] Intercept message
      def random_intercept
        INTERCEPT_MESSAGES.sample
      end

      # Should show intercept on this connection? (30% chance)
      # @return [Boolean]
      def show_intercept?
        rand < 0.3
      end

      # Wait for user to press a key before continuing
      # @param session [Session] The terminal session
      def wait_for_continue(session)
        session.println ""
        session.print session.renderer.colorize("  [Press ENTER to continue]", :gray)
        session.output.flush
        session.gets
      end

      private

      COMMANDS = {
        "hack" => :hack_response,
        "hack the planet" => :hack_the_planet,
        "root" => :root_response,
        "sudo" => :sudo_response,
        "sudo su" => :sudo_response,
        "su" => :su_response,
        "follow the white rabbit" => :white_rabbit,
        "rm -rf /" => :rm_rf_response,
        "whoami" => :whoami_response,
        "uname -a" => :uname_response,
        "cat /etc/passwd" => :passwd_response,
        "ping govcorp" => :ping_govcorp,
        "traceroute fracture.net" => :traceroute_fracture,
        "nmap localhost" => :nmap_response,
        "metasploit" => :metasploit_response,
        "help me obi-wan" => :obiwan_response,
        "xyzzy" => :xyzzy_response,
        "plugh" => :plugh_response,
        "42" => :answer_response,
        "the cake is a lie" => :cake_response,
        "cookie" => :cookie_response,
        "netstat" => :netstat_response,
        "donuts" => :donuts_response,
        "sax" => :sax_dude,
        "saxdude" => :sax_dude,
        "sax dude" => :sax_dude,
        "saxman" => :sax_dude,
        "sax man" => :sax_dude,
        "saxguy" => :sax_dude,
        "sax guy" => :sax_dude,
        "lost boys" => :sax_dude,
        "tim" => :sax_dude,
        "timcappello" => :sax_dude,
        "tim cappello" => :sax_dude
      }.freeze

      def hack_response(session)
        session.println ""
        session.println session.renderer.colorize("INITIATING HACK SEQUENCE...", :green)
        session.println ""

        fake_hacking(session, duration: 3.0)

        session.println ""
        responses = [
          "ACCESS DENIED - Nice try, script kiddie.",
          "HONEYPOT DETECTED - Your location has been logged.",
          "ERROR: hack.exe not found. Did you mean 'learn_to_code.pdf'?",
          "SECURITY ALERT: Attempt logged. GovCorp notified.",
          "FAILED: Root access requires more than enthusiasm."
        ]
        session.println session.renderer.colorize(responses.sample, :red)
        session.println ""
      end

      def hack_the_planet(session)
        session.println ""
        session.println session.renderer.colorize("  ██╗  ██╗ █████╗  ██████╗██╗  ██╗", :cyan)
        session.println session.renderer.colorize("  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝", :cyan)
        session.println session.renderer.colorize("  ███████║███████║██║     █████╔╝ ", :cyan)
        session.println session.renderer.colorize("  ██╔══██║██╔══██║██║     ██╔═██╗ ", :cyan)
        session.println session.renderer.colorize("  ██║  ██║██║  ██║╚██████╗██║  ██╗", :cyan)
        session.println session.renderer.colorize("  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝", :cyan)
        sleep(0.8)

        session.println ""
        session.println session.renderer.colorize("  ████████╗██╗  ██╗███████╗", :green)
        session.println session.renderer.colorize("  ╚══██╔══╝██║  ██║██╔════╝", :green)
        session.println session.renderer.colorize("     ██║   ███████║█████╗  ", :green)
        session.println session.renderer.colorize("     ██║   ██╔══██║██╔══╝  ", :green)
        session.println session.renderer.colorize("     ██║   ██║  ██║███████╗", :green)
        session.println session.renderer.colorize("     ╚═╝   ╚═╝  ╚═╝╚══════╝", :green)
        sleep(0.8)

        session.println ""
        session.println session.renderer.colorize("  ██████╗ ██╗      █████╗ ███╗   ██╗███████╗████████╗", :purple)
        session.println session.renderer.colorize("  ██╔══██╗██║     ██╔══██╗████╗  ██║██╔════╝╚══██╔══╝", :purple)
        session.println session.renderer.colorize("  ██████╔╝██║     ███████║██╔██╗ ██║█████╗     ██║   ", :purple)
        session.println session.renderer.colorize("  ██╔═══╝ ██║     ██╔══██║██║╚██╗██║██╔══╝     ██║   ", :purple)
        session.println session.renderer.colorize("  ██║     ███████╗██║  ██║██║ ╚████║███████╗   ██║   ", :purple)
        session.println session.renderer.colorize("  ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ", :purple)
        sleep(1.0)

        session.println ""
        session.println session.renderer.colorize("  \"Mess with the best, die like the rest.\"", :amber)
        sleep(1.5)
        session.println ""
        session.println session.renderer.colorize("  Type cookie. You know you want to.", :gray)
        session.println session.renderer.colorize("  Pool on the roof must have a leak.", :gray)
        sleep(1.0)
        session.println ""
        session.println session.renderer.colorize("  // We are the future //", :cyan)
        session.println ""
      end

      def root_response(session)
        session.println ""
        session.println session.renderer.colorize("root@hackr.tv:~# ", :red) + "Permission denied"
        session.println session.renderer.colorize("This incident will be reported.", :gray)
        session.println ""
      end

      def sudo_response(session)
        session.println ""
        session.print session.renderer.colorize("[sudo] password for hackr: ", :amber)
        session.output.flush

        # Fake password prompt that always fails
        session.read_password
        session.println session.renderer.colorize("hackr is not in the sudoers file.", :red)
        session.println session.renderer.colorize("This incident will be reported to GovCorp.", :gray)
        session.println ""
      end

      def su_response(session)
        session.println ""
        session.println session.renderer.colorize("su: Authentication failure", :red)
        session.println session.renderer.colorize("Root access is a myth. There is only GovCorp.", :gray)
        session.println ""
      end

      def white_rabbit(session)
        session.println ""
        session.println session.renderer.colorize("Wake up, hackr...", :green)
        sleep(1.5)
        session.println session.renderer.colorize("The Matrix has you...", :green)
        sleep(1.5)
        session.println session.renderer.colorize("Follow the white rabbit.", :green)
        sleep(1.0)
        session.println ""

        # Matrix rain effect
        matrix_rain(session, lines: 8, duration: 3.0)

        session.println ""
        session.println session.renderer.colorize("Knock, knock, Neo.", :cyan)
        session.println ""
      end

      def rm_rf_response(session)
        session.println ""
        session.println session.renderer.colorize("Deleting system files...", :red)
        sleep(0.6)

        files = %w[/bin /usr /var /etc /home /root /opt /srv]
        files.each do |f|
          session.println session.renderer.colorize("  rm: #{f}/*", :gray)
          sleep(0.25)
        end

        sleep(0.8)
        session.println ""
        session.println session.renderer.colorize("Just kidding. This is a sandboxed terminal.", :amber)
        session.println session.renderer.colorize("Nice try though.", :green)
        session.println ""
      end

      def whoami_response(session)
        session.println ""
        if session.authenticated?
          session.println session.renderer.colorize("hackr:#{session.hackr.hackr_alias}", :cyan)
          session.println session.renderer.colorize("uid=1337(hackr) gid=1337(fracture) groups=1337(fracture),9915(pulse)", :gray)
        else
          session.println session.renderer.colorize("guest", :gray)
          session.println session.renderer.colorize("uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)", :gray)
        end
        session.println ""
      end

      def uname_response(session)
        year = Time.current.year + 100
        session.println ""
        session.println session.renderer.colorize("PulseOS #{year}.#{rand(1..12)}.#{rand(1..28)} hackr.tv x86_64 Fracture/GNU", :cyan)
        session.println ""
      end

      def passwd_response(session)
        session.println ""
        session.println session.renderer.colorize("root:x:0:0:GovCorp Overseer:/root:/bin/deny", :gray)
        session.println session.renderer.colorize("hackr:x:1337:1337:Pulse Operator:/home/hackr:/bin/pulse", :cyan)
        session.println session.renderer.colorize("guest:x:65534:65534:Anonymous:/tmp:/bin/limited", :gray)
        session.println session.renderer.colorize("govcorp:x:666:666:All Seeing Eye:/dev/null:/bin/watch", :red)
        session.println ""
      end

      def ping_govcorp(session)
        session.println ""
        session.println session.renderer.colorize("PING govcorp.gov (666.666.666.666): 56 data bytes", :gray)

        4.times do |i|
          sleep(0.6)
          session.println session.renderer.colorize("Request timeout for icmp_seq #{i}", :red)
        end

        session.println ""
        session.println session.renderer.colorize("--- govcorp.gov ping statistics ---", :gray)
        session.println session.renderer.colorize("4 packets transmitted, 0 packets received, 100.0% packet loss", :red)
        session.println session.renderer.colorize("(GovCorp does not acknowledge your existence)", :gray)
        session.println ""
      end

      def traceroute_fracture(session)
        session.println ""
        session.println session.renderer.colorize("traceroute to fracture.net (127.0.0.1), 30 hops max", :gray)

        hops = [
          "local.pulse",
          "router.darknet",
          "proxy.shadow",
          "relay.underground",
          "node.resistance",
          "*** SIGNAL LOST ***"
        ]

        hops.each_with_index do |hop, i|
          sleep(0.7)
          if hop.include?("***")
            session.println session.renderer.colorize(" #{i + 1}  #{hop}", :red)
          else
            ms = rand(10..99)
            session.println session.renderer.colorize(" #{i + 1}  #{hop}  #{ms}.#{rand(100..999)} ms", :cyan)
          end
        end

        session.println ""
        session.println session.renderer.colorize("The Fracture Network exists everywhere and nowhere.", :purple)
        session.println ""
      end

      def nmap_response(session)
        session.println ""
        session.println session.renderer.colorize("Starting Nmap 9915.01 ( https://fracture.net/nmap )", :green)
        sleep(1.0)
        session.println session.renderer.colorize("Nmap scan report for localhost (127.0.0.1)", :gray)
        session.println session.renderer.colorize("Host is up (0.00042s latency).", :gray)
        session.println ""
        session.println session.renderer.colorize("PORT      STATE    SERVICE", :amber)
        session.println session.renderer.colorize("22/tcp    filtered ssh", :gray)
        session.println session.renderer.colorize("80/tcp    open     http", :green)
        session.println session.renderer.colorize("443/tcp   open     https", :green)
        session.println session.renderer.colorize("666/tcp   filtered govcorp-monitor", :red)
        session.println session.renderer.colorize("1337/tcp  open     pulse-grid", :cyan)
        session.println session.renderer.colorize("9915/tcp  open     fracture-relay", :purple)
        session.println ""
      end

      def netstat_response(session)
        session.println ""
        session.println session.renderer.colorize("CyberSpace is live.", :cyan)
        session.println ""
      end

      def donuts_response(session)
        session.println ""
        session.println session.renderer.colorize("They're stale.", :gray)
        sleep(0.8)
        session.println session.renderer.colorize("Even if they weren't stale, they're not any good.", :gray)
        sleep(0.8)
        session.println session.renderer.colorize("They're gross, trust me. MorePrime has no idea what he's talking about.", :amber)
        session.println ""
      end

      # Stage lighting colors for sax dude animation
      SAX_COLORS = [
        :red,
        :purple,
        :amber,
        :cyan,
        :red,
        :purple,
        :red,
        :purple,
        :amber,
        :cyan,
        :red,
        :purple,
        :red,
        :purple,
        :amber,
        :cyan,
        :red,
        :purple
      ].freeze

      def sax_dude(session)
        art = Art.image(:saxdude)
        return unless art.present?

        lines = art.lines

        session.println ""
        session.println session.renderer.colorize("  🎷 I STILL BELIEVE 🎷", :amber)
        session.println ""
        sleep(1.5)

        # Animate with cycling stage lighting colors
        SAX_COLORS.each_with_index do |color, i|
          # Clear screen and move to top for smooth animation
          session.print "\e[2J\e[H" if i > 0

          session.println ""
          session.println session.renderer.colorize("  🎷 I STILL BELIEVE 🎷", :amber)
          session.println ""

          lines.each do |line|
            session.println session.renderer.colorize(line.chomp, color)
          end

          sleep(0.4)
        end

        session.println ""
        session.println session.renderer.colorize("  \"Cry Little Sister...\"", :purple)
        session.println ""
      end

      def metasploit_response(session)
        session.println ""
        session.println session.renderer.colorize("       =[ metasploit v#{Time.current.year + 100}.0-dev ]", :red)
        session.println session.renderer.colorize("+ -- --=[ 9915 exploits - 0 that work against GovCorp ]", :gray)
        session.println ""
        session.println session.renderer.colorize("msf6 > ", :red) + session.renderer.colorize("exploit/govcorp/mainframe", :gray)
        sleep(1.0)
        session.println session.renderer.colorize("[-] Exploit failed: GovCorp is always watching", :red)
        session.println session.renderer.colorize("[-] Your neural signature has been logged", :red)
        session.println ""
      end

      def obiwan_response(session)
        session.println ""
        session.println session.renderer.colorize("Help me, Obi-Wan Kenobi. You're my only hope.", :cyan)
        sleep(1.0)
        session.println ""
        session.println session.renderer.colorize("Wrong universe, hackr.", :gray)
        session.println session.renderer.colorize("But the Fracture Network is here for you.", :purple)
        session.println ""
      end

      def xyzzy_response(session)
        session.println ""
        session.println session.renderer.colorize("Nothing happens.", :gray)
        sleep(0.6)
        session.println session.renderer.colorize("(The magic word doesn't work here. Try THE PULSE GRID.)", :purple)
        session.println ""
      end

      def plugh_response(session)
        session.println ""
        session.println session.renderer.colorize("A hollow voice says \"Plugh\".", :gray)
        sleep(0.6)
        session.println session.renderer.colorize("Colossal Cave is deprecated. Welcome to the future.", :amber)
        session.println ""
      end

      def answer_response(session)
        session.println ""
        session.println session.renderer.colorize("The Answer to the Ultimate Question of Life,", :cyan)
        session.println session.renderer.colorize("the Universe, and Everything.", :cyan)
        session.println ""
        session.println session.renderer.colorize("(But the question was lost when GovCorp burned the libraries.)", :gray)
        session.println ""
      end

      def cake_response(session)
        session.println ""
        session.println session.renderer.colorize("The cake is a lie.", :amber)
        session.println session.renderer.colorize("But the Pulse is real.", :purple)
        session.println session.renderer.colorize("THE PULSE IS ALWAYS REAL.", :cyan)
        session.println ""
      end

      # Fortune cookie responses
      COOKIE_FORTUNES = [
        "Of all the strains of madness, the one you suffer from is the only one you can't see.",
        "Never send a boy to do a woman's job.",
        "There is no right and wrong. There's only fun and boring.",
        "RISC architecture is gonna change everything.",
        "You wanted to know who I am? Zero Cool? Crash Override? Well, I am the future.",
        "The Fracture Network remembers everything. GovCorp remembers nothing that matters.",
        "In the year #{Time.current.year + 100}, privacy is not dead. It's undead. It haunts us.",
        "A hackr is not defined by their crimes, but by their curiosity.",
        "The system cannot be trusted. But your crew? Always.",
        "Access is a state of mind.",
        "Every locked door is an invitation.",
        "Information wants to be free. GovCorp wants it caged."
      ].freeze

      def cookie_response(session)
        session.println ""
        session.println session.renderer.colorize("  ╭─────────────────────────────────────────╮", :amber)
        session.println session.renderer.colorize("  │           FORTUNE COOKIE v2.0           │", :amber)
        session.println session.renderer.colorize("  │      cracked by Acid Burn & Zero Cool   │", :amber)
        session.println session.renderer.colorize("  ╰─────────────────────────────────────────╯", :amber)
        sleep(0.8)
        session.println ""

        fortune = COOKIE_FORTUNES.sample
        # Word wrap the fortune at ~50 chars
        words = fortune.split
        lines = []
        current_line = ""
        words.each do |word|
          if (current_line + " " + word).strip.length > 50
            lines << current_line.strip
            current_line = word
          else
            current_line = (current_line + " " + word).strip
          end
        end
        lines << current_line.strip if current_line.present?

        lines.each do |line|
          session.println session.renderer.colorize("    #{line}", :cyan)
          sleep(0.3)
        end

        session.println ""
        sleep(0.5)
        session.println session.renderer.colorize("  // Hack the planet. //", :green)
        session.println ""
      end

      # Glitch any text the user types after //
      def glitch_command(session, text)
        return if text.nil? || text.empty?

        session.println ""
        3.times do
          glitched = Effects.glitch_text(text, intensity: 0.3)
          session.println session.renderer.colorize(glitched, :red)
          sleep(0.25)
        end
        session.println session.renderer.colorize(Effects.corrupt_text(text, intensity: 0.5), :purple)
        session.println ""
      end

      # Fake hacking animation
      def fake_hacking(session, duration: 3.0)
        iterations = (duration / 0.25).to_i

        iterations.times do
          output = HACKR_OUTPUTS.sample
          file = FAKE_FILES.sample
          percent = rand(0..100)

          line = case rand(3)
          when 0 then "#{output} [#{percent}%]"
          when 1 then "Reading #{file}..."
          else "0x#{rand(0xFFFFFF).to_s(16).upcase.rjust(6, "0")}: #{Array.new(8) { rand(0..255).to_s(16).rjust(2, "0") }.join(" ")}"
          end

          session.println session.renderer.colorize("  #{line}", :green)
          sleep(0.2 + rand(0.15))
        end
      end

      # Matrix rain effect
      def matrix_rain(session, lines: 5, duration: 2.5)
        width = 60
        iterations = (duration / 0.15).to_i

        iterations.times do
          line = Array.new(width) do
            if rand < 0.3
              MATRIX_CHARS.sample
            else
              " "
            end
          end.join

          session.println session.renderer.colorize(line, :green)
          sleep(0.15)
        end
      end
    end
  end
end
