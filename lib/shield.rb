## breakout for Shield released with PSM3
## new code for 5.0.16
## includes new functions .known? and .affordable?

class Shield
  @@adamantine_bulwark            ||= 0
  @@block_the_elements            ||= 0
  @@deflect_magic                 ||= 0
  @@deflect_missiles              ||= 0
  @@deflect_the_elements          ||= 0
  @@disarming_presence            ||= 0
  @@guard_mastery                 ||= 0
  @@large_shield_focus            ||= 0
  @@medium_shield_focus           ||= 0
  @@phalanx                       ||= 0
  @@prop_up                       ||= 0
  @@protective_wall               ||= 0
  @@shield_bash                   ||= 0
  @@shield_charge                 ||= 0
  @@shield_forward                ||= 0
  @@shield_mind                   ||= 0
  @@shield_pin                    ||= 0
  @@shield_push                   ||= 0
  @@shield_riposte                ||= 0
  @@shield_spike_mastery          ||= 0
  @@shield_strike                 ||= 0
  @@shield_strike_mastery         ||= 0
  @@shield_swiftness              ||= 0
  @@shield_throw                  ||= 0
  @@shield_trample                ||= 0
  @@shielded_brawler              ||= 0
  @@small_shield_focus            ||= 0
  @@spell_block                   ||= 0
  @@steady_shield                 ||= 0
  @@steely_resolve                ||= 0
  @@tortoise_stance               ||= 0
  @@tower_shield_focus            ||= 0

  def self.adamantine_bulwark;        @@aadamantine_bulwark;          end
  def self.block_the_elements;        @@block_the_elements;           end
  def self.deflect_magic;             @@deflect_magic;                end
  def self.deflect_missiles;          @@deflect_missiles;             end
  def self.deflect_the_elements;      @@deflect_the_elements;         end
  def self.disarming_presence;        @@disarming_presence;           end
  def self.guard_mastery;             @@guard_mastery;                end
  def self.large_shield_focus;        @@large_shield_focus;           end
  def self.medium_shield_focus;       @@medium_shield_focus;          end
  def self.phalanx;                   @@phalanx;                      end
  def self.prop_up;                   @@prop_up;                      end
  def self.protective_wall;           @@protective_wall;              end
  def self.shield_bash;               @@shield_bash;                  end
  def self.shield_charge;             @@shield_charge;                end
  def self.shield_forward;            @@shield_forward;               end
  def self.shield_mind;               @@shield_mind;                  end
  def self.shield_pin;                @@shield_pin;                   end
  def self.shield_push;               @@shield_push;                  end
  def self.shield_riposte;            @@shield_riposte;               end
  def self.shield_spike_mastery;      @@shield_spike_mastery;         end
  def self.shield_strike;             @@shield_strike;                end
  def self.shield_strike_mastery;     @@shield_strike_mastery;        end
  def self.shield_swiftness;          @@shield_swiftness;             end
  def self.shield_throw;              @@shield_throw;                 end
  def self.shield_trample;            @@shield_trample;               end
  def self.shielded_brawler;          @@shielded_brawler;             end
  def self.small_shield_focus;        @@small_shield_focus;           end
  def self.spell_block;               @@spell_block;                  end
  def self.steady_shield;             @@steady_shield;                end
  def self.steely_resolve;            @@steely_resolve;               end
  def self.tortoise_stance;           @@tortoise_stance;              end
  def self.tower_shield_focus;        @@tower_shield_focus;           end

  def self.adamantine_bulwark=(val);    @@adamantine_bulwark = val;     end
  def self.block_the_elements=(val);    @@block_the_elements = val;     end
  def self.deflect_magic=(val);         @@deflect_magic = val;          end
  def self.deflect_missiles=(val);      @@deflect_missiles = val;       end
  def self.deflect_the_elements=(val);  @@deflect_the_elements = val;   end
  def self.disarming_presence=(val);    @@disarming_presence = val;     end
  def self.guard_mastery=(val);         @@guard_mastery = val;          end
  def self.large_shield_focus=(val);    @@large_shield_focus = val;     end
  def self.medium_shield_focus=(val);   @@medium_shield_focus = val;    end
  def self.phalanx=(val);               @@phalanx = val;                end
  def self.prop_up=(val);               @@prop_up = val;                end
  def self.protective_wall=(val);       @@protective_wall = val;        end
  def self.shield_bash=(val);           @@shield_bash = val;            end
  def self.shield_charge=(val);         @@shield_charge = val;          end
  def self.shield_forward=(val);        @@shield_forward = val;         end
  def self.shield_mind=(val);           @@shield_mind = val;            end
  def self.shield_pin=(val);            @@shield_pin = val;             end
  def self.shield_push=(val);           @@shield_push = val;            end
  def self.shield_riposte=(val);        @@shield_riposte = val;         end
  def self.shield_spike_mastery=(val);  @@shield_spike_mastery = val;   end
  def self.shield_strike=(val);         @@shield_strike = val;          end
  def self.shield_strike_mastery=(val); @@shield_strike_mastery = val;  end
  def self.shield_swiftness=(val);      @@shield_swiftness = val;       end
  def self.shield_throw=(val);          @@shield_throw = val;           end
  def self.shield_trample=(val);        @@shield_trample = val;         end
  def self.shielded_brawler=(val);      @@shielded_brawler = val;       end
  def self.small_shield_focus=(val);    @@small_shield_focus = val;     end
  def self.spell_block=(val);           @@spell_block = val;            end
  def self.steady_shield=(val);         @@steady_shield = val;          end
  def self.steely_resolve=(val);        @@steely_resolve = val;         end
  def self.tortoise_stance=(val);       @@tortoise_stance = val;        end
  def self.tower_shield_focus=(val);    @@tower_shield_focus = val;     end

  @@shield_techniques = {
    "adamantine_bulwark" => {
      :cost => 0,
      :regex => /Adamantine Bulwark does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "block_the_elements" => {
      :cost => 0,
      :regex => /Block the Elements does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "deflect_magic" => {
      :cost => 0,
      :regex => /Deflect Magic does not need to be activated once you have learned it.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization./i,
      :usage => nil,
    },
    "deflect_missiles" => {
      :cost => 0,
      :regex => /Deflect Missiles does not need to be activated once you have learned it.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization./i,
      :usage => nil,
    },
    "deflect_the_elements" => {
      :cost => 0,
      :regex => /Deflect the Elements does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "disarming_presence" => {
      :cost => 20,
      :regex => /You assume the Disarming Presence Stance, adjusting your footing and grip to allow for the proper pivot and thrust technique to disarm attacking foes.|You re-settle into the Disarming Presence Stance, re-ensuring your footing and grip are properly positioned./i,
      :usage => "dpresence",
    },
    "guard_mastery" => {
      :cost => 0,
      :regex => /Guard Mastery does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "large_shield_focus" => {
      :cost => 0,
      :regex => /Large Shield Focus does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "medium_shield_focus" => {
      :cost => 0,
      :regex => /Medium Shield Focus does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "phalanx" => {
      :cost => 0,
      :regex => /Phalanx does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "prop_up" => {
      :cost => 0,
      :regex => /Prop Up does not need to be activated once you have learned it.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization./i,
      :usage => nil,
    },
    "protective_wall" => {
      :cost => 0,
      :regex => /Protective Wall does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "shield_bash" => {
      :cost => 9,
      :regex => /Shield Bash what?|You lunge forward at (.*) with your (.*) and attempt a shield bash\!/i,
      :usage => "bash",
    },
    "shield_charge" => {
      :cost => 14,
      :regex => /You charge forward at (.*) with your (.*) and attempt a shield charge!/i,
      :usage => "charge",
    },
    "shield_forward" => {
      :cost => 0,
      :regex => /Shield Forward does not need to be activated once you have learned it.  It will automatically activate upon the use of a shield attack./i,
      :usage => "forward",
    },
    "shield_mind" => {
      :cost => 10,
      :regex => /You must be wielding an ensorcelled or anti-magical shield to be able to properly shield your mind and soul.|/i,
      :usage => "mind",
    },
    "shield_pin" => {
      :cost => 15,
      :regex => /You attempt to expose a vulnerability with a diversionary shield bash on (.*)\!/i,
      :usage => "pin",
    },
    "shield_push" => {
      :cost => 7,
      :regex => /You raise your (.*) before you and attempt to push (.*) away!/i,
      :usage => "push",
    },
    "shield_riposte" => {
      :cost => 20,
      :regex => /You assume the Shield Riposte Stance, preparing yourself to lash out at a moment's notice.|You re\-settle into the Shield Riposte Stance, preparing yourself to lash out at a moment's notice./i,
      :usage => "riposte",
    },
    "shield_spike_mastery" => {
      :cost => 0,
      :regex => /Shield Spike Mastery does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "shield_strike" => {
      :cost => 15,
      :regex => /You launch a quick bash with your (.*) at (.*)\!/i,
      :usage => "strike",
    },
    "shield_strike_mastery" => {
      :cost => 0,
      :regex => /Shield Strike Mastery does not need to be activated once you have learned it.  It will automatically apply to all relevant focused multi-attacks, provided that you maintain the prerequisite ranks of Shield Bash./i,
      :usage => nil,
    },
    "shield_swiftness" => {
      :cost => 0,
      :regex => /Shield Swiftness does not need to be activated once you have learned it.  It will automatically apply to all relevant attacks, provided that you are wielding a small or medium shield and have at least 3 ranks of the relevant Shield Focus specialization./i,
      :usage => nil,
    },
    "shield_throw" => {
      :cost => 20,
      :regex => /You snap your arm forward, hurling your (.*) at (.*) with all your might\!/i,
      :usage => "throw",
    },
    "shield_trample" => {
      :cost => 14,
      :regex => /You raise your (.*) before you and charge headlong towards (.*)\!/i,
      :usage => "trample",
    },
    "shielded_brawler" => {
      :cost => 0,
      :regex => /Shielded Brawler does not need to be activated once you have learned it.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization./i,
      :usage => nil,
    },
    "small_shield_focus" => {
      :cost => 0,
      :regex => /Small Shield Focus does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
    "spell_block" => {
      :cost => 0,
      :regex => /Spell Block does not need to be activated once you have learned it.  It will automatically apply to all relevant attacks, provided that you are wielding a shield and possess 3 ranks of the relevant Shield Focus specialization./i,
      :usage => nil,
    },
    "steady_shield" => {
      :cost => 0,
      :regex => /Steady Shield does not need to be activated once you have learned it.  It will automatically apply to all relevant attacks against you, provided that you maintain the prerequisite ranks of Stun Maneuvers./i,
      :usage => nil,
    },
    "steely_resolve" => {
      :cost => 30,
      :regex => /You focus your mind in a steely resolve to block all attacks against you.|You are still mentally fatigued from your last invocation of your Steely Resolve./i,
      :usage => "resolve",
    },
    "tortoise_stance" => {
      :cost => 20,
      :regex => /You assume the Stance of the Tortoise, holding back some of your offensive power in order to maximize your defense.|You re\-settle into the Stance of the Tortoise, holding back your offensive power in order to maximize your defense./i,
      :usage => "tortoise",
    },
    "tower_shield_focus" => {
      :cost => 0,
      :regex => /Tower Shield Focus does not need to be activated.  If you are wielding the appropriate type of shield, it will always be active./i,
      :usage => nil,
    },
  }

  def self.method_missing(arg1, arg2 = nil)
    echo "#{arg1} is not a defined Shield type.  Is it another Ability type?"
  end

  def self.[](name)
    Shield.send(name.to_s.gsub(/[\s\-]/, '_').gsub("'", "").downcase)
  end

  def self.[]=(name, val)
    Shield.send("#{name.to_s.gsub(/[\s\-]/, '_').gsub("'", "").downcase}=", val.to_i)
  end

  def self.known?(name)
    Shield.send(name.to_s.gsub(/[\s\-]/, '_').gsub("'", "").downcase) > 0
  end

  def self.affordable?(name)
    @@shield_techniques.fetch(name.to_s.gsub(/[\s\-]/, '_').gsub("'", "").downcase)[:cost] < XMLData.stamina
  end

  def self.available?(name)
    Shield.known?(name) and Shield.affordable?(name) and
      !Lich::Util.normalize_lookup('Cooldowns', name) and !Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
  end

  def self.use(name, target = "")
    return unless Shield.available?(name)

    usage = @@shield_techniques.fetch(name.to_s.gsub(/[\s\-]/, '_').gsub("'", "").downcase)[:usage]
    return if usage.nil?

    results_regex = Regexp.union(
      @@shield_techniques.fetch(name.to_s.gsub(/[\s\-]/, '_').gsub("'", "").downcase)[:regex],
      /^#{name} what\?$/i,
      /^Roundtime: [0-9]+ sec\.$/,
      /^And give yourself away!  Never!$/,
      /^You are unable to do that right now\.$/,
      /^You don't seem to be able to move to do that\.$/,
      /^Provoking a GameMaster is not such a good idea\.$/,
      /^You do not currently have a target\.$/,
    )
    usage_cmd = "shield #{usage}"
    if target.class == GameObj
      usage_cmd += " ##{target.id}"
    elsif target.class == Integer
      usage_cmd += " ##{target}"
    elsif target != ""
      usage_cmd += " #{target}"
    end
    usage_result = nil
    loop {
      waitrt?
      waitcastrt?
      usage_result = dothistimeout usage_cmd, 5, results_regex
      if usage_result == "You don't seem to be able to move to do that."
        100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep 0.1 }
        usage_result = dothistimeout usage_cmd, 5, results_regex
      end
      break
    }
    usage_result
  end
end
