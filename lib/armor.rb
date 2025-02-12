## breakout for Armor released with PSM3
## new code for 5.0.16
## includes new functions .known? and .affordable?

class Armor
  @@armor_blessing                ||= 0
  @@armor_reinforcement           ||= 0
  @@armor_spike_mastery           ||= 0
  @@armor_support                 ||= 0
  @@armored_casting               ||= 0
  @@armored_evasion               ||= 0
  @@armored_fluidity              ||= 0
  @@armored_stealth               ||= 0
  @@crush_protection              ||= 0
  @@puncture_protection           ||= 0
  @@slash_protection              ||= 0

  def self.armor_blessing;              @@armor_blessing;             end
  def self.armor_reinforcement;         @@armor_reinforcement;        end
  def self.armor_spike_mastery;         @@armor_spike_mastery;        end
  def self.armor_support;               @@armor_support;              end
  def self.armored_casting;             @@armored_casting;            end
  def self.armored_evasion;             @@armored_evasion;            end
  def self.armored_fluidity;            @@armored_fluidity;           end
  def self.armored_stealth;             @@armored_stealth;            end
  def self.crush_protection;            @@crush_protection;           end
  def self.puncture_protection;         @@puncture_protection;        end
  def self.slash_protection;            @@slash_protection;           end

  def self.armor_blessing=(val);        @@armor_blessing = val;         end
  def self.armor_reinforcement=(val);   @@armor_reinforcement = val;    end
  def self.armor_spike_mastery=(val);   @@armor_spike_mastery = val;    end
  def self.armor_support=(val);         @@armor_support = val;          end
  def self.armored_casting=(val);       @@armored_casting = val;        end
  def self.armored_evasion=(val);       @@armored_evasion = val;        end
  def self.armored_fluidity=(val);      @@armored_fluidity = val;       end
  def self.armored_stealth=(val);       @@armored_stealth = val;        end
  def self.crush_protection=(val);      @@crush_protection = val;       end
  def self.puncture_protection=(val);   @@puncture_protection = val;    end
  def self.slash_protection=(val);      @@slash_protection = val;       end

  # rubocop:disable Style/MissingRespondToMissing Trying to be helpful to manual callers in the client
  def self.method_missing(arg1, arg2 = nil)
    echo "#{arg1} is not a defined Armor type.  Is it another Ability type?"
  end
  # rubocop:enable Style/MissingRespondToMissing

  def self.[](name)
    Armor.send(name.to_s.gsub(/[\s-]/, '_').gsub("'", '').downcase)
  end

  def self.[]=(name, val)
    Armor.send("#{name.to_s.gsub(/[\s-]/, '_').gsub("'", '').downcase}=", val.to_i)
  end

  def self.known?(name)
    Armor.send(name.to_s.gsub(/[\s-]/, '_').gsub("'", '').downcase) > 0
  end

  ## Armor does not require stamina so costs are zero across the board
  ## the following method is in place simply to make consistent with other
  ## PSM class definitions.

  def self.affordable?(name)
    return true
  end
end
