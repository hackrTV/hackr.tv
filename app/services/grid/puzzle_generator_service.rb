# frozen_string_literal: true

module Grid
  # Generates puzzle content for BREACH circumvention gates.
  # Stateless — given a gate spec and seeded RNG, returns display data + solution.
  # Called from BreachService#generate_puzzle_gates! during encounter start.
  class PuzzleGeneratorService
    PUZZLE_TYPES = %w[sequence logic_gate circuit credential].freeze

    # Themed node labels for sequence and circuit puzzles
    NODE_POOL = %w[ALPHA BRAVO CRYPT DELTA ECHO FLUX GATE HELIX ION JAM KILO LINK MAST NODE OMNI PRISM QUAD RELAY SYNC TERM UNIT VECT WIRE XFER].freeze

    # Themed words for credential puzzles
    CREDENTIAL_WORDS = %w[
      SiliconRanger NeonCipher VaultKeeper DataWraith GridHunter
      PulseRunner ByteGhost NodeWalker CryptHawk SignalDrift
      NetShade CorePhase WaveJack LinkBreak TraceNull
    ].freeze

    CREDENTIAL_SUFFIXES = %w[1@3 _7x !99 #42 .0x $88 &v2 ^9k].freeze

    # Character substitution map for credential encryption
    SUBSTITUTION_MAP = {
      "S" => "$", "i" => "!", "o" => "0", "a" => "@", "e" => "3",
      "n" => "^", "l" => "1", "t" => "+", "r" => "2", "g" => "9",
      "k" => "K", "d" => "6", "u" => "v", "B" => "8", "c" => "("
    }.freeze

    # Generate a puzzle for a given gate spec.
    # Returns { display_data: Hash, solution: String }
    def self.generate(gate_spec, rng)
      type = gate_spec["type"]
      difficulty = (gate_spec["difficulty"] || 2).to_i.clamp(1, 5)

      case type
      when "sequence" then generate_sequence(difficulty, rng)
      when "logic_gate" then generate_logic_gate(difficulty, rng)
      when "circuit" then generate_circuit(difficulty, rng)
      when "credential" then generate_credential(difficulty, rng)
      else
        raise ArgumentError, "Unknown puzzle type: #{type}"
      end
    end

    class << self
      private

      # Sequence: reorder scrambled nodes into correct initialization order
      # Difficulty 1=4 nodes, 2=5, 3=6, 4=7, 5=8
      def generate_sequence(difficulty, rng)
        count = 3 + difficulty
        nodes = NODE_POOL.sample(count, random: rng)
        solution_order = nodes.dup
        display_order = nodes.shuffle(random: rng)

        # Ensure display is actually scrambled
        display_order = nodes.shuffle(random: rng) while display_order == solution_order && count > 1

        {
          display_data: {
            "type" => "sequence",
            "prompt" => "Reorder the boot sequence nodes into correct initialization order.",
            "nodes" => display_order
          },
          solution: solution_order.join(" ")
        }
      end

      # Logic gate: determine correct input values to produce target output
      # Difficulty 1=2 inputs, 2=3, 3=4, 4=5, 5=6
      # Answer validation uses evaluate_logic_gate to accept ANY valid input combo.
      def generate_logic_gate(difficulty, rng)
        input_count = 1 + difficulty
        inputs = (1..input_count).map { |i| "IN#{i}" }

        # Pick a gate type randomly, weighted by difficulty tier
        gate_pool = case difficulty
        when 1 then %w[OR AND]
        when 2 then %w[OR AND XOR]
        when 3 then %w[AND XOR NAND]
        when 4 then %w[XOR NAND NOR]
        else %w[NAND NOR XOR]
        end
        gate_type = gate_pool[rng.rand(gate_pool.size)]

        # Generate one known-good solution and compute target output
        values = inputs.map { (rng.rand(2) == 1) ? "HIGH" : "LOW" }
        bools = values.map { |v| v == "HIGH" }
        target = evaluate_gate(gate_type, bools) ? "HIGH" : "LOW"

        # Store gate_type and target in solution for validation — any valid combo accepted
        solution = "#{gate_type}:#{target}:#{input_count}"

        {
          display_data: {
            "type" => "logic_gate",
            "prompt" => "Set input signals to produce the target output.",
            "gate_type" => gate_type,
            "inputs" => inputs,
            "target_output" => target,
            "diagram" => "#{gate_type}(#{inputs.join(", ")}) \u2192 TARGET: #{target}"
          },
          solution: solution
        }
      end

      # Circuit: connect node pairs to restore signal paths.
      # Players get a limited probe budget to test individual connections
      # before submitting the full answer.
      # Difficulty 1=2 pairs, 2=3, 3=4, 4=5, 5=6
      def generate_circuit(difficulty, rng)
        pair_count = 1 + difficulty
        all_nodes = NODE_POOL.sample(pair_count * 2, random: rng)
        left = all_nodes[0, pair_count]
        right = all_nodes[pair_count, pair_count]

        # Build correct pairings and sort canonically
        pairs = left.zip(right).map { |l, r| [l, r].sort.join("-") }.sort

        # Scramble display
        display_left = left.shuffle(random: rng)
        display_right = right.shuffle(random: rng)

        # Probe budget: enough to solve with strategy, not enough to brute-force
        probe_budget = case difficulty
        when 1 then 1   # 2 pairs — probe 1, deduce other
        when 2 then 2   # 3 pairs — probe 2, deduce other
        when 3 then 3   # 4 pairs — probe 3, deduce other
        when 4 then 3   # 5 pairs — must reason about 2 remaining
        else 4           # 6 pairs — must reason about 2 remaining
        end

        {
          display_data: {
            "type" => "circuit",
            "prompt" => "Probe signal paths to map circuit connections.",
            "left_nodes" => display_left,
            "right_nodes" => display_right,
            "pair_count" => pair_count,
            "probe_budget" => probe_budget
          },
          solution: pairs.join(" ")
        }
      end

      # Credential: decrypt an encrypted string using a partial substitution map.
      #
      # Four difficulty axes:
      #   1. Substitution count — how many chars are replaced (1-5)
      #   2. Hints revealed — fraction of real substitutions shown, no positions (all → few)
      #   3. Red herrings — fake substitution hints mixed in (0-3)
      #   4. Decoy ciphers — 1 cipher at easy, 3 at hard (only one is real)
      #
      # | Diff | Subs | Hints | Herrings | Ciphers |
      # |------|------|-------|----------|---------|
      # |  1   |  1   |  1/1  |    0     |    1    |
      # |  2   |  2   |  1/2  |    1     |    1    |
      # |  3   |  3   |  2/3  |    1     |    3    |
      # |  4   |  4   |  2/4  |    2     |    3    |
      # |  5   |  5   |  2/5  |    3     |    3    |
      def generate_credential(difficulty, rng)
        word = CREDENTIAL_WORDS[rng.rand(CREDENTIAL_WORDS.size)]
        suffix = CREDENTIAL_SUFFIXES[rng.rand(CREDENTIAL_SUFFIXES.size)]
        plaintext = word + suffix

        # 1. Apply substitutions
        sub_count = difficulty.clamp(1, 5)
        encrypted, applied_subs = encrypt_credential(plaintext, sub_count, rng)

        # 2. Partial hints (no positions) — reveal only some real substitutions
        hints_shown = (difficulty <= 1) ? applied_subs.size : [2, applied_subs.size].min
        real_hints = applied_subs.first(hints_shown).map { |s| "#{s[:to]}\u2192#{s[:from]}" }

        # 3. Red herring substitutions (mappings not used in this encryption)
        herring_count = case difficulty
        when 1 then 0
        when 2 then 1
        when 3 then 1
        when 4 then 2
        else 3
        end
        used_chars = applied_subs.map { |s| s[:from] }
        herring_hints = SUBSTITUTION_MAP.except(*used_chars).to_a
          .sample(herring_count, random: rng)
          .map { |from, to| "#{to}\u2192#{from}" }

        all_hints = (real_hints + herring_hints).shuffle(random: rng)

        # 4. Decoy ciphers (difficulty 3+)
        ciphers = [encrypted]
        if difficulty >= 3
          decoy_words = (CREDENTIAL_WORDS - [word]).sample(2, random: rng)
          decoy_words.each do |dw|
            ds = CREDENTIAL_SUFFIXES[rng.rand(CREDENTIAL_SUFFIXES.size)]
            decoy_enc, _ = encrypt_credential(dw + ds, sub_count, rng)
            ciphers << decoy_enc
          end
          ciphers.shuffle!(random: rng)
        end

        {
          display_data: {
            "type" => "credential",
            "prompt" => "Decrypt the access credential.",
            "ciphers" => ciphers,
            "substitution_hints" => all_hints
          },
          solution: plaintext
        }
      end

      # Apply N random substitutions to a plaintext string.
      # Returns [encrypted_string, applied_substitutions_array].
      def encrypt_credential(plaintext, count, rng)
        encrypted = plaintext.dup
        applied = []

        eligible = plaintext.chars.each_with_index.select { |ch, _| SUBSTITUTION_MAP.key?(ch) }
        eligible.shuffle!(random: rng)

        [count, eligible.size].min.times do
          char, pos = eligible.shift
          sub = SUBSTITUTION_MAP[char]
          encrypted[pos] = sub
          applied << {from: char, to: sub}
        end

        [encrypted, applied]
      end
    end

    def self.evaluate_gate(gate_type, bools)
      case gate_type
      when "AND" then bools.all?
      when "OR" then bools.any?
      when "XOR" then bools.count(true).odd?
      when "NAND" then !bools.all?
      when "NOR" then bools.none?
      else bools.any?
      end
    end
  end
end
