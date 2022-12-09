=begin
spell.rb: Core lich file for spell management and for spell related scripts.
Further modifications are to support the retirement of spell-list.xml.

    Maintainer: Elanthia-Online
    Original Author: Tillmen, others
    game: Gemstone
    tags: CORE, spells
    required: Lich > 5.0.19
    version: 1.2.1

  changelog:
    v1.2.1 (2022-05-10)
      add unknown spell result to regex results
    v1.2.0 (2022-03-14)
      add Spell.force_cast(target, args, results_of_interest)
      add Spell.force_channel(target, args, results_of_interest)
      add Spell.force_evoke(target, args, results_of_interest)
      add Spell.force_incant(args, results_of_interest)
    v1.1.0 (2021-09-27
      rebaselined as spell.rb to support spell-list.xml retirement
    v1.0.0 (2021-09-22)
      initial release and subsequent modifications as SIMU changes warranted

=end

module Games
  module Gemstone
    class Spell
      @@list ||= []
      @@loaded ||= false
      @@cast_lock ||= []
      @@bonus_list ||= []
      @@cost_list ||= []
      @@load_mutex = Mutex.new
      @@elevated_load = proc { Spell.load }
      @@after_stance = nil
      attr_accessor :active, :stance, :channel
      attr_reader :num, :name, :timestamp, :msgup, :msgdn, :circle, :type, :cast_proc, :real_time, :persist_on_death, :availability, :no_incant

      @@prepare_regex = /^You already have a spell readied!  You must RELEASE it if you wish to prepare another!$|^Your spell(?:song)? is ready\.|^You can't think clearly enough to prepare a spell!$|^You are concentrating too intently .*?to prepare a spell\.$|^You are too injured to make that dextrous of a movement|^The searing pain in your throat makes that impossible|^But you don't have any mana!\.$|^You can't make that dextrous of a move!$|^As you begin to prepare the spell the wind blows small objects at you thwarting your attempt\.$|^You do not know that spell!$|^All you manage to do is cough up some blood\.$|The incantations of countless spells swirl through your mind as a golden light flashes before your eyes\./
      @@results_regex = /^(?:Cast|Sing) Roundtime [0-9]+ Seconds?\.$|^Cast at what\?$|^But you don't have any mana!$|^\[Spell Hindrance for|^You don't have a spell prepared!$|keeps? the spell from working\.|^Be at peace my child, there is no need for spells of war in here\.$|Spells of War cannot be cast|^As you focus on your magic, your vision swims with a swirling haze of crimson\.$|^Your magic fizzles ineffectually\.$|^All you manage to do is cough up some blood\.$|^And give yourself away!  Never!$|^You are unable to do that right now\.$|^You feel a sudden rush of power as you absorb [0-9]+ mana!$|^You are unable to drain it!$|leaving you casting at nothing but thin air!$|^You don't seem to be able to move to do that\.$|^Provoking a GameMaster is not such a good idea\.$|^You can't think clearly enough to prepare a spell!$|^You do not currently have a target\.$|The incantations of countless spells swirl through your mind as a golden light flashes before your eyes\.|You can only evoke certain spells\.|You can only channel certain spells for extra power\.|That is not something you can prepare\./

      def initialize(xml_spell)
        @num = xml_spell.attributes['number'].to_i
        @name = xml_spell.attributes['name']
        @type = xml_spell.attributes['type']
        @no_incant = (xml_spell.attributes['incant'] == 'no')
        if xml_spell.attributes['availability'] == 'all'
          @availability = 'all'
        elsif xml_spell.attributes['availability'] == 'group'
          @availability = 'group'
        else
          @availability = 'self-cast'
        end
        @bonus = {}
        xml_spell.elements.find_all { |e| e.name == 'bonus' }.each { |e|
          @bonus[e.attributes['type']] = e.text
          @bonus[e.attributes['type']].untaint
        }
        @msgup = xml_spell.elements.find_all { |e| (e.name == 'message') and (e.attributes['type'].downcase == 'start') }.collect(&:text).join('$|^')
        @msgup = nil if @msgup.empty?
        @msgdn = xml_spell.elements.find_all { |e| (e.name == 'message') and (e.attributes['type'].downcase == 'end') }.collect(&:text).join('$|^')
        @msgdn = nil if @msgdn.empty?
        @stance = (xml_spell.attributes['stance'] =~ /^(yes|true)$/i ? true : false)
        @channel = (xml_spell.attributes['channel'] =~ /^(yes|true)$/i ? true : false)
        @cost = {}
        xml_spell.elements.find_all { |e| e.name == 'cost' }.each { |xml_cost|
          @cost[xml_cost.attributes['type'].downcase] ||= {}
          if xml_cost.attributes['cast-type'].downcase == 'target'
            @cost[xml_cost.attributes['type'].downcase]['target'] = xml_cost.text
          else
            @cost[xml_cost.attributes['type'].downcase]['self'] = xml_cost.text
          end
        }
        @duration = {}
        xml_spell.elements.find_all { |e| e.name == 'duration' }.each { |xml_duration|
          if xml_duration.attributes['cast-type'].downcase == 'target'
            cast_type = 'target'
          else
            cast_type = 'self'
            if xml_duration.attributes['real-time'] =~ /^(yes|true)$/i
              @real_time = true
            else
              @real_time = false
            end
          end
          @duration[cast_type] = {}
          @duration[cast_type][:duration] = xml_duration.text
          @duration[cast_type][:stackable] = (xml_duration.attributes['span'].downcase == 'stackable')
          @duration[cast_type][:refreshable] = (xml_duration.attributes['span'].downcase == 'refreshable')
          if xml_duration.attributes['multicastable'] =~ /^(yes|true)$/i
            @duration[cast_type][:multicastable] = true
          else
            @duration[cast_type][:multicastable] = false
          end
          if xml_duration.attributes['persist-on-death'] =~ /^(yes|true)$/i
            @persist_on_death = true
          else
            @persist_on_death = false
          end
          if xml_duration.attributes['max']
            @duration[cast_type][:max_duration] = xml_duration.attributes['max'].to_f
          else
            @duration[cast_type][:max_duration] = 250.0
          end
        }
        @cast_proc = xml_spell.elements['cast-proc'].text
        @cast_proc.untaint
        @timestamp = Time.now
        @timeleft = 0
        @active = false
        @circle = (num.to_s.length == 3 ? num.to_s[0..0] : num.to_s[0..1])
        @@list.push(self) unless @@list.find { |spell| spell.num == @num }
        self
      end

      def self.after_stance=(val)
        @@after_stance = val
      end

      def self.load(filename = nil)
        if $SAFE == 0
          if filename.nil?
            if File.exist?("#{DATA_DIR}/spell-list.xml")
              filename = "#{DATA_DIR}/spell-list.xml"
            elsif File.exist?("#{SCRIPT_DIR}/spell-list.xml") # deprecated
              filename = "#{SCRIPT_DIR}/spell-list.xml"
            else
              filename = "#{DATA_DIR}/spell-list.xml"
            end
          end
          script = Script.current
          @@load_mutex.synchronize {
            return true if @loaded

            begin
              spell_times = {}
              # reloading spell data should not reset spell tracking...
              unless @@list.empty?
                @@list.each { |spell| spell_times[spell.num] = spell.timeleft if spell.active? }
                @@list.clear
              end
              File.open(filename) { |file|
                xml_doc = REXML::Document.new(file)
                xml_root = xml_doc.root
                xml_root.elements.each { |xml_spell| Spell.new(xml_spell) }
              }
              @@list.each { |spell|
                if spell_times[spell.num]
                  spell.timeleft = spell_times[spell.num]
                  spell.active = true
                end
              }
              @@bonus_list = @@list.collect { |spell| spell._bonus.keys }.flatten
              @@bonus_list |= @@bonus_list
              @@cost_list = @@list.collect { |spell| spell._cost.keys }.flatten
              @@cost_list |= @@cost_list
              @@loaded = true
              return true
            rescue
              respond "--- Lich: error: Spell.load: #{$!}"
              Lich.log "error: Spell.load: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
              @@loaded = false
              return false
            end
          }
        else
          @@elevated_load.call
        end
      end

      def self.[](val)
        Spell.load unless @@loaded
        if val.instance_of?(Spell)
          val
        elsif val.instance_of?(Integer) or (val.instance_of?(String) and val =~ /^[0-9]+$/)
          @@list.find { |spell| spell.num == val.to_i }
        else
          val = Regexp.escape(val)
          (@@list.find { |s| s.name =~ /^#{val}$/i } || @@list.find { |s| s.name =~ /^#{val}/i } || @@list.find { |s| s.msgup =~ /#{val}/i or s.msgdn =~ /#{val}/i })
        end
      end

      def self.active
        Spell.load unless @@loaded
        active = []
        @@list.each { |spell| active.push(spell) if spell.active? }
        active
      end

      def self.active?(val)
        Spell.load unless @@loaded
        Spell[val].active?
      end

      def self.list
        Spell.load unless @@loaded
        @@list
      end

      def self.upmsgs
        Spell.load unless @@loaded
        @@list.collect(&:msgup).compact
      end

      def self.dnmsgs
        Spell.load unless @@loaded
        @@list.collect(&:msgdn).compact
      end

      def time_per_formula(options = {})
        activator_modifier = { 'tap' => 0.5, 'rub' => 1, 'wave' => 1, 'raise' => 1.33, 'drink' => 0, 'bite' => 0, 'eat' => 0, 'gobble' => 0 }
        can_haz_spell_ranks = /Spells\.(?:minorelemental|majorelemental|minorspiritual|majorspiritual|wizard|sorcerer|ranger|paladin|empath|cleric|bard|minormental)/
        skills = ['Spells.minorelemental', 'Spells.majorelemental', 'Spells.minorspiritual', 'Spells.majorspiritual', 'Spells.wizard', 'Spells.sorcerer', 'Spells.ranger', 'Spells.paladin', 'Spells.empath', 'Spells.cleric', 'Spells.bard', 'Spells.minormental', 'Skills.magicitemuse', 'Skills.arcanesymbols']
        if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
          if options[:target] and (options[:target].downcase == options[:caster].downcase)
            formula = @duration['self'][:duration].to_s.dup
          else
            formula = @duration['target'][:duration].dup || @duration['self'][:duration].to_s.dup
          end
          if options[:activator] =~ /^(#{activator_modifier.keys.join('|')})$/i
            if formula =~ can_haz_spell_ranks
              skills.each { |skill_name| formula.gsub!(skill_name, "(SpellRanks['#{options[:caster]}'].magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
              formula = "(#{formula})/2.0"
            elsif formula =~ /Skills\.(?:magicitemuse|arcanesymbols)/
              skills.each { |skill_name| formula.gsub!(skill_name, "(SpellRanks['#{options[:caster]}'].magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
            end
          elsif options[:activator] =~ /^(invoke|scroll)$/i
            if formula =~ can_haz_spell_ranks
              skills.each { |skill_name| formula.gsub!(skill_name, "SpellRanks['#{options[:caster]}'].arcanesymbols.to_i") }
              formula = "(#{formula})/2.0"
            elsif formula =~ /Skills\.(?:magicitemuse|arcanesymbols)/
              skills.each { |skill_name| formula.gsub!(skill_name, "SpellRanks['#{options[:caster]}'].arcanesymbols.to_i") }
            end
          else
            skills.each { |skill_name| formula.gsub!(skill_name, "SpellRanks[#{options[:caster].to_s.inspect}].#{skill_name.sub(/^(?:Spells|Skills)\./, '')}.to_i") }
          end
        else
          if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
            formula = @duration['target'][:duration].dup || @duration['self'][:duration].to_s.dup
          else
            formula = @duration['self'][:duration].to_s.dup
          end
          if options[:activator] =~ /^(#{activator_modifier.keys.join('|')})$/i
            if formula =~ can_haz_spell_ranks
              skills.each { |skill_name| formula.gsub!(skill_name, "(Skills.magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
              formula = "(#{formula})/2.0"
            elsif formula =~ /Skills\.(?:magicitemuse|arcanesymbols)/
              skills.each { |skill_name| formula.gsub!(skill_name, "(Skills.magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
            end
          elsif options[:activator] =~ /^(invoke|scroll)$/i
            if formula =~ can_haz_spell_ranks
              skills.each { |skill_name| formula.gsub!(skill_name, 'Skills.arcanesymbols.to_i') }
              formula = "(#{formula})/2.0"
            elsif formula =~ /Skills\.(?:magicitemuse|arcanesymbols)/
              skills.each { |skill_name| formula.gsub!(skill_name, 'Skills.arcanesymbols.to_i') }
            end
          end
        end
        formula.untaint
        formula
      end

      def time_per(options = {})
        formula = time_per_formula(options)
        line = options[:line] if options[:line]
        proc { begin; $SAFE = 3; rescue; nil; end; eval(formula) }.call.to_f
      end

      def timeleft=(val)
        @timeleft = val
        @timestamp = Time.now
      end

      def timeleft
        if time_per_formula.to_s == 'Spellsong.timeleft'
          @timeleft = Spellsong.timeleft
        else
          @timeleft -= ((Time.now - @timestamp) / 60.to_f)
          if @timeleft <= 0
            putdown
            return 0.to_f
          end
        end
        @timestamp = Time.now
        @timeleft
      end

      def minsleft
        timeleft
      end

      def secsleft
        timeleft * 60
      end

      def active?
        (timeleft > 0) and @active
      end

      def stackable?(options = {})
        if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
          if options[:target] and (options[:target].downcase == options[:caster].downcase)
            @duration['self'][:stackable]
          elsif @duration['target'][:stackable].nil?
            @duration['self'][:stackable]
          else
            @duration['target'][:stackable]
          end
        elsif options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
          if @duration['target'][:stackable].nil?
            @duration['self'][:stackable]
          else
            @duration['target'][:stackable]
          end
        else
          @duration['self'][:stackable]
        end
      end

      def refreshable?(options = {})
        if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
          if options[:target] and (options[:target].downcase == options[:caster].downcase)
            @duration['self'][:refreshable]
          elsif @duration['target'][:refreshable].nil?
            @duration['self'][:refreshable]
          else
            @duration['target'][:refreshable]
          end
        elsif options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
          if @duration['target'][:refreshable].nil?
            @duration['self'][:refreshable]
          else
            @duration['target'][:refreshable]
          end
        else
          @duration['self'][:refreshable]
        end
      end

      def multicastable?(options = {})
        if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
          if options[:target] and (options[:target].downcase == options[:caster].downcase)
            @duration['self'][:multicastable]
          elsif @duration['target'][:multicastable].nil?
            @duration['self'][:multicastable]
          else
            @duration['target'][:multicastable]
          end
        elsif options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
          if @duration['target'][:multicastable].nil?
            @duration['self'][:multicastable]
          else
            @duration['target'][:multicastable]
          end
        else
          @duration['self'][:multicastable]
        end
      end

      def known?
        if @num.to_s.length == 3
          circle_num = @num.to_s[0..0].to_i
        elsif @num.to_s.length == 4
          circle_num = @num.to_s[0..1].to_i
        else
          return false
        end
        if circle_num == 1
          ranks = [Spells.minorspiritual, XMLData.level].min
        elsif circle_num == 2
          ranks = [Spells.majorspiritual, XMLData.level].min
        elsif circle_num == 3
          ranks = [Spells.cleric, XMLData.level].min
        elsif circle_num == 4
          ranks = [Spells.minorelemental, XMLData.level].min
        elsif circle_num == 5
          ranks = [Spells.majorelemental, XMLData.level].min
        elsif circle_num == 6
          ranks = [Spells.ranger, XMLData.level].min
        elsif circle_num == 7
          ranks = [Spells.sorcerer, XMLData.level].min
        elsif circle_num == 9
          ranks = [Spells.wizard, XMLData.level].min
        elsif circle_num == 10
          ranks = [Spells.bard, XMLData.level].min
        elsif circle_num == 11
          ranks = [Spells.empath, XMLData.level].min
        elsif circle_num == 12
          ranks = [Spells.minormental, XMLData.level].min
        elsif circle_num == 16
          ranks = [Spells.paladin, XMLData.level].min
        elsif circle_num == 17
          if (@num == 1700) and (Char.prof =~ /^(?:Wizard|Cleric|Empath|Sorcerer|Savant)$/)
            return true
          else
            return false
          end
        elsif (circle_num == 97) and (Society.status == 'Guardians of Sunfist')
          ranks = Society.rank
        elsif (circle_num == 98) and (Society.status == 'Order of Voln')
          ranks = Society.rank
        elsif (circle_num == 99) and (Society.status == 'Council of Light')
          ranks = Society.rank
        elsif circle_num == 96
          return false

        #          deprecate CMan from Spell class .known?
        #          See CMan, CMan.known? and CMan.available? methods in CMan class

        else
          return false
        end
        if (@num % 100) <= ranks
          return true
        else
          return false
        end
      end

      def available?(options = {})
        if known?
          if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
            if options[:target] and (options[:target].downcase == options[:caster].downcase)
              true
            else
              @availability == 'all'
            end
          elsif options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
            @availability == 'all'
          else
            true
          end
        else
          false
        end
      end

      def incant?
        !@no_incant
      end

      def incant=(val)
        @no_incant = !val
      end

      def to_s
        @name.to_s
      end

      def max_duration(options = {})
        if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
          if options[:target] and (options[:target].downcase == options[:caster].downcase)
            @duration['self'][:max_duration]
          else
            @duration['target'][:max_duration] || @duration['self'][:max_duration]
          end
        elsif options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
          @duration['target'][:max_duration] || @duration['self'][:max_duration]
        else
          @duration['self'][:max_duration]
        end
      end

      def putup(options = {})
        if stackable?(options)
          self.timeleft = [timeleft + time_per(options), max_duration(options)].min
        else
          self.timeleft = [time_per(options), max_duration(options)].min
        end
        @active = true
      end

      def putdown
        self.timeleft = 0
        @active = false
      end

      def remaining
        timeleft.as_time
      end

      def affordable?(options = {})
        # FIXME: deal with them dirty bards!
        release_options = options.dup
        release_options[:multicast] = nil
        if (stamina_cost(options) > 0) and (Spell[9699].active? or !checkstamina(stamina_cost(options)))
          false
        elsif (spirit_cost(options) > 0) and !checkspirit(spirit_cost(options) + 1 + [9912, 9913, 9914, 9916, 9916, 9916].delete_if { |num| !Spell[num].active? }.length)
          false
        elsif mana_cost(options) > 0
          ## convert Spell[9699].active? to Effects::Debuffs test (if Debuffs is where it shows)
          if Feat.known?(:mental_acuity) and (Spell[9699].active? or !checkstamina(mana_cost(options) * 2))
            false
          elsif !Feat.known?(:mental_acuity) && (!checkmana(mana_cost(options)) or (Spell[515].active? and !checkmana(mana_cost(options) + [mana_cost(release_options) / 4, 1].max)))
            false
          else
            true
          end
        else
          true
        end
      end

      def self.lock_cast
        script = Script.current
        @@cast_lock.push(script)
        until (@@cast_lock.first == script) or @@cast_lock.empty?
          sleep 0.1
          Script.current # allows this loop to be paused
          @@cast_lock.delete_if { |s| s.paused or !Script.list.include?(s) }
        end
      end

      def self.unlock_cast
        @@cast_lock.delete(Script.current)
      end

      def cast(target = nil, results_of_interest = nil, arg_options = nil)
        # FIXME: find multicast in target and check mana for it
        check_energy = proc {
          if Feat.known?(:mental_acuity)
            unless (mana_cost <= 0) or checkstamina(mana_cost * 2)
              echo 'cast: not enough stamina there, Monk!'
              sleep 0.1
              return false
            end
          else
            unless (mana_cost <= 0) or checkmana(mana_cost)
              echo 'cast: not enough mana'
              sleep 0.1
              return false
            end
          end
          unless (spirit_cost > 0) or checkspirit(spirit_cost + 1 + [9912, 9913, 9914, 9916, 9916, 9916].delete_if { |num| !Spell[num].active? }.length)
            echo 'cast: not enough spirit'
            sleep 0.1
            return false
          end
          unless (stamina_cost <= 0) or checkstamina(stamina_cost)
            echo 'cast: not enough stamina'
            sleep 0.1
            return false
          end
        }
        script = Script.current
        if @type.nil?
          echo "cast: spell missing type (#{@name})"
          sleep 0.1
          return false
        end
        check_energy.call
        begin
          save_want_downstream = script.want_downstream
          save_want_downstream_xml = script.want_downstream_xml
          script.want_downstream = true
          script.want_downstream_xml = false
          @@cast_lock.push(script)
          until (@@cast_lock.first == script) or @@cast_lock.empty?
            sleep 0.1
            Script.current # allows this loop to be paused
            @@cast_lock.delete_if { |s| s.paused or !Script.list.include?(s) }
          end
          check_energy.call
          if @cast_proc
            waitrt?
            waitcastrt?
            check_energy.call
            begin
              proc { begin; $SAFE = 3; rescue; nil; end; eval(@cast_proc) }.call
            rescue
              echo "cast: error: #{$!}"
              respond $!.backtrace[0..2]
              return false
            end
          else
            if @channel
              cast_cmd = 'channel'
            else
              cast_cmd = 'cast'
            end
            if !(arg_options.nil? || arg_options.empty?) && (arg_options.split(' ')[0] =~ /incant|channel|evoke|cast/)
              cast_cmd = arg_options.split(' ')[0]
              arg_options = arg_options.split(' ').drop(1)
              arg_options = arg_options.join(' ') unless arg_options.empty?
            end

            if (((target.nil? || target.to_s.empty?) && !@no_incant) && (cast_cmd == 'cast' && arg_options.nil?) || cast_cmd == 'incant') && cast_cmd !~ /^(?:channel|evoke)/
              cast_cmd = "incant #{@num}"
            elsif (target.nil? or target.to_s.empty?) and (@type =~ /attack/i) and ![410, 435, 525, 912, 909, 609].include?(@num)
              cast_cmd += ' target'
            elsif target.instance_of?(GameObj)
              cast_cmd += " ##{target.id}"
            elsif target.instance_of?(Integer)
              cast_cmd += " ##{target}"
            elsif cast_cmd !~ /^incant/
              cast_cmd += " #{target}"
            end

            cast_cmd += " #{arg_options}" unless arg_options.nil? || arg_options.empty?

            cast_result = nil
            loop {
              waitrt?
              if cast_cmd =~ /^incant/
                dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/ if (checkprep != @name) and (checkprep != 'None')
              else
                unless checkprep == @name
                  unless checkprep == 'None'
                    dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
                    unless (mana_cost <= 0) or checkmana(mana_cost)
                      echo 'cast: not enough mana'
                      sleep 0.1
                      return false
                    end
                    unless (spirit_cost <= 0) or checkspirit(spirit_cost + 1 + (checkspell(9912) ? 1 : 0) + (checkspell(9913) ? 1 : 0) + (checkspell(9914) ? 1 : 0) + (checkspell(9916) ? 5 : 0))
                      echo 'cast: not enough spirit'
                      sleep 0.1
                      return false
                    end
                    unless (stamina_cost <= 0) or checkstamina(stamina_cost)
                      echo 'cast: not enough stamina'
                      sleep 0.1
                      return false
                    end
                  end
                  loop {
                    waitrt?
                    waitcastrt?
                    prepare_result = dothistimeout "prepare #{@num}", 8, @@prepare_regex
                    if prepare_result =~ /^Your spell(?:song)? is ready\./
                      break
                    elsif prepare_result == 'You already have a spell readied!  You must RELEASE it if you wish to prepare another!'
                      dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
                      unless (mana_cost <= 0) or checkmana(mana_cost)
                        echo 'cast: not enough mana'
                        sleep 0.1
                        return false
                      end
                    elsif prepare_result =~ /^You can't think clearly enough to prepare a spell!$|^You are concentrating too intently .*?to prepare a spell\.$|^You are too injured to make that dextrous of a movement|^The searing pain in your throat makes that impossible|^But you don't have any mana!\.$|^You can't make that dextrous of a move!$|^As you begin to prepare the spell the wind blows small objects at you thwarting your attempt\.$|^You do not know that spell!$|^All you manage to do is cough up some blood\.$|The incantations of countless spells swirl through your mind as a golden light flashes before your eyes\./
                      sleep 0.1
                      return prepare_result
                    end
                  }
                end
              end
              waitcastrt?
              if @stance and checkstance != 'offensive'
                put 'stance offensive'
                # dothistimeout 'stance offensive', 5, /^You (?:are now in|move into) an? offensive stance|^You are unable to change your stance\.$/
              end
              if results_of_interest.instance_of?(Regexp)
                merged_results_regex = /#{@@results_regex}|#{results_of_interest}/
              else
                merged_results_regex = @@results_regex
              end
              cast_result = dothistimeout cast_cmd, 5, merged_results_regex
              if cast_result == "You don't seem to be able to move to do that."
                100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep 0.1 }
                cast_result = dothistimeout cast_cmd, 5, merged_results_regex
              end
              if @stance
                if @@after_stance
                  if checkstance !~ /#{@@after_stance}/
                    waitrt?
                    dothistimeout "stance #{@@after_stance}", 3, /^You (?:are now in|move into) an? \w+ stance|^You are unable to change your stance\.$/
                  end
                elsif checkstance !~ /^guarded$|^defensive$/
                  waitrt?
                  if checkcastrt > 0
                    dothistimeout 'stance guarded', 3, /^You (?:are now in|move into) an? \w+ stance|^You are unable to change your stance\.$/
                  else
                    dothistimeout 'stance defensive', 3, /^You (?:are now in|move into) an? \w+ stance|^You are unable to change your stance\.$/
                  end
                end
              end
              dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/ if cast_result =~ /^Cast at what\?$|^Be at peace my child, there is no need for spells of war in here\.$|^Provoking a GameMaster is not such a good idea\.$/
              if cast_result =~ /You can only evoke certain spells\.|You can only channel certain spells for extra power\./
                echo "cast: can't evoke/channel #{@num}"
                cast_cmd = cast_cmd.gsub(/^(?:evoke|channel)/, 'cast')
                next
              end
              break unless (@circle.to_i == 10) && (cast_result =~ /^\[Spell Hindrance for/)
            }
            cast_result
          end
        ensure
          script.want_downstream = save_want_downstream
          script.want_downstream_xml = save_want_downstream_xml
          @@cast_lock.delete(script)
        end
      end

      def force_cast(target = nil, arg_options = nil, results_of_interest = nil)
        if arg_options.nil? || arg_options.empty?
          arg_options = 'cast'
        else
          arg_options = "cast #{arg_options}"
        end
        cast(target, results_of_interest, arg_options)
      end

      def force_channel(target = nil, arg_options = nil, results_of_interest = nil)
        if arg_options.nil? || arg_options.empty?
          arg_options = 'channel'
        else
          arg_options = "channel #{arg_options}"
        end
        cast(target, results_of_interest, arg_options)
      end

      def force_evoke(target = nil, arg_options = nil, results_of_interest = nil)
        if arg_options.nil? || arg_options.empty?
          arg_options = 'evoke'
        else
          arg_options = "evoke #{arg_options}"
        end
        cast(target, results_of_interest, arg_options)
      end

      def force_incant(arg_options = nil, results_of_interest = nil)
        if arg_options.nil? || arg_options.empty?
          arg_options = 'incant'
        else
          arg_options = "incant #{arg_options}"
        end
        cast(nil, results_of_interest, arg_options)
      end

      def _bonus
        @bonus.dup
      end

      def _cost
        @cost.dup
      end

      def method_missing(*args)
        if @@bonus_list.include?(args[0].to_s.gsub('_', '-'))
          if @bonus[args[0].to_s.gsub('_', '-')]
            proc { begin; $SAFE = 3; rescue; nil; end; eval(@bonus[args[0].to_s.gsub('_', '-')]) }.call.to_i
          else
            0
          end
        elsif @@bonus_list.include?(args[0].to_s.sub(/_formula$/, '').gsub('_', '-'))
          @bonus[args[0].to_s.sub(/_formula$/, '').gsub('_', '-')].dup
        elsif (args[0].to_s =~ /_cost(?:_formula)?$/) and @@cost_list.include?(args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, ''))
          options = args[1].to_hash
          if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
            if options[:target] and (options[:target].downcase == options[:caster].downcase)
              formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['self'].dup
            else
              formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['target'].dup || @cost[args[0].to_s.gsub('_', '-')]['self'].dup
            end
            skills = { 'Spells.minorelemental' => "SpellRanks['#{options[:caster]}'].minorelemental.to_i", 'Spells.majorelemental' => "SpellRanks['#{options[:caster]}'].majorelemental.to_i", 'Spells.minorspiritual' => "SpellRanks['#{options[:caster]}'].minorspiritual.to_i", 'Spells.majorspiritual' => "SpellRanks['#{options[:caster]}'].majorspiritual.to_i", 'Spells.wizard' => "SpellRanks['#{options[:caster]}'].wizard.to_i", 'Spells.sorcerer' => "SpellRanks['#{options[:caster]}'].sorcerer.to_i", 'Spells.ranger' => "SpellRanks['#{options[:caster]}'].ranger.to_i", 'Spells.paladin' => "SpellRanks['#{options[:caster]}'].paladin.to_i", 'Spells.empath' => "SpellRanks['#{options[:caster]}'].empath.to_i", 'Spells.cleric' => "SpellRanks['#{options[:caster]}'].cleric.to_i", 'Spells.bard' => "SpellRanks['#{options[:caster]}'].bard.to_i", 'Stats.level' => '100' }
            skills.each_pair { |a, b| formula.gsub!(a, b) }
          elsif options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
            formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['target'].dup || @cost[args[0].to_s.gsub('_', '-')]['self'].dup
          else
            formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['self'].dup
          end
          formula = "#{formula}+5" if args[0].to_s =~ /mana/ and Spell[597].active? # Rapid Fire Penalty
          formula = "(#{formula})*#{options[:multicast].to_i}" if options[:multicast].to_i > 1
          if args[0].to_s =~ /_formula$/
            formula.dup
          elsif formula
            formula.untaint if formula.tainted?
            proc { begin; $SAFE = 3; rescue; nil; end; eval(formula) }.call.to_i
          else
            0
          end
        else
          respond "missing method: #{args.inspect}"
          raise NoMethodError
        end
      end

      def circle_name
        Spells.get_circle_name(@circle)
      end

      def clear_on_death
        !@persist_on_death
      end

      # rubocop:disable Naming/MethodName for backwards compatiblity
      def duration;      time_per_formula;            end
      def cost;          mana_cost_formula    || '0'; end
      def manaCost;      mana_cost_formula    || '0'; end
      def spiritCost;    spirit_cost_formula  || '0'; end
      def staminaCost;   stamina_cost_formula || '0'; end
      def boltAS;        bolt_as_formula;             end
      def physicalAS;    physical_as_formula;         end
      def boltDS;        bolt_ds_formula;             end
      def physicalDS;    physical_ds_formula;         end
      def elementalCS;   elemental_cs_formula;        end
      def mentalCS;      mental_cs_formula;           end
      def spiritCS;      spirit_cs_formula;           end
      def sorcererCS;    sorcerer_cs_formula;         end
      def elementalTD;   elemental_td_formula;        end
      def mentalTD;      mental_td_formula;           end
      def spiritTD;      spirit_td_formula;           end
      def sorcererTD;    sorcerer_td_formula;         end
      def castProc;      @cast_proc; end
      def stacks;        stackable? end
      def command;       nil; end
      def circlename;    circle_name; end
      def selfonly;      @availability != 'all'; end
      # rubocop:enable Naming/MethodName
    end # class
  end # mod
end # mod
