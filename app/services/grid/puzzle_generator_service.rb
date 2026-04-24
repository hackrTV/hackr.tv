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

      # Circuit: connect node pairs to restore signal paths
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

        {
          display_data: {
            "type" => "circuit",
            "prompt" => "Connect open circuit nodes to restore signal path.",
            "left_nodes" => display_left,
            "right_nodes" => display_right,
            "pair_count" => pair_count
          },
          solution: pairs.join(" ")
        }
      end

      # Credential: decrypt an encrypted string using a partial cipher hint
      # Difficulty 1=1 substitution, 2=2, 3=3, 4=4, 5=5
      def generate_credential(difficulty, rng)
        word = CREDENTIAL_WORDS[rng.rand(CREDENTIAL_WORDS.size)]
        suffix = CREDENTIAL_SUFFIXES[rng.rand(CREDENTIAL_SUFFIXES.size)]
        plaintext = word + suffix

        encrypted = plaintext.dup
        hint_parts = []

        # Apply substitutions at random positions (shift ensures no duplicates)
        eligible = plaintext.chars.each_with_index.select { |ch, _| SUBSTITUTION_MAP.key?(ch) }
        eligible.shuffle!(random: rng)

        [difficulty, eligible.size].min.times do
          char, pos = eligible.shift
          sub = SUBSTITUTION_MAP[char]
          encrypted[pos] = sub
          hint_parts << "pos #{pos + 1}: #{sub}\u2192#{char}"
        end

        {
          display_data: {
            "type" => "credential",
            "prompt" => "Decrypt the access credential.",
            "encrypted" => encrypted,
            "cipher_hint" => hint_parts.join(", ")
          },
          solution: plaintext
        }
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
