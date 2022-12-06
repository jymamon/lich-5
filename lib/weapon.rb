## breakout for Weapon released with PSM3
## new code for 5.0.16
## includes new functions .known? and .affordable?

class Weapon
  @@barrage ||= 0
  @@charge ||= 0
  @@clash ||= 0
  @@clobber ||= 0
  @@cripple ||= 0
  @@cyclone ||= 0
  @@dizzying_swing ||= 0
  @@flurry ||= 0
  @@fury ||= 0
  @@guardant_thrusts ||= 0
  @@overpower ||= 0
  @@pin_down ||= 0
  @@pulverize ||= 0
  @@pummel ||= 0
  @@radial_sweep ||= 0
  @@reactive_shot ||= 0
  @@reverse_strike ||= 0
  @@riposte ||= 0
  @@spin_kick ||= 0
  @@thrash ||= 0
  @@twin_hammerfists ||= 0
  @@volley ||= 0
  @@whirling_blade ||= 0
  @@whirlwind ||= 0

  def self.barrage;           @@barrage;              end
  def self.charge;            @@charge;               end
  def self.clash;             @@clash;                end
  def self.clobber;           @@clobber;              end
  def self.cripple;           @@cripple;              end
  def self.cyclone;           @@cyclone;              end
  def self.dizzying_swing;    @@dizzying_swing;       end
  def self.flurry;            @@flurry;               end
  def self.fury;              @@fury;                 end
  def self.guardant_thrusts;  @@guardant_thrusts;     end
  def self.overpower;         @@overpower;            end
  def self.pin_down;          @@pin_down;             end
  def self.pulverize;         @@pulverize;            end
  def self.pummel;            @@pummel;               end
  def self.radial_sweep;      @@radial_sweep;         end
  def self.reactive_shot;     @@reactive_shot;        end
  def self.reverse_strike;    @@reverse_strike;       end
  def self.riposte;           @@riposte;              end
  def self.spin_kick;         @@spin_kick;            end
  def self.thrash;            @@thrash;               end
  def self.twin_hammerfists;  @@twin_hammerfists;     end
  def self.volley;            @@volley;               end
  def self.whirling_blade;    @@whirling_blade;       end
  def self.whirlwind;         @@whirlwind;            end

  def self.barrage=(val);             @@barrage = val;              end
  def self.charge=(val);              @@charge = val;               end
  def self.clash=(val);               @@clash = val;                end
  def self.clobber=(val);             @@clobber = val;              end
  def self.cripple=(val);             @@cripple = val;              end
  def self.cyclone=(val);             @@cyclone = val;              end
  def self.dizzying_swing=(val);      @@dizzying_swing = val;       end
  def self.flurry=(val);              @@flurry = val;               end
  def self.fury=(val);                @@fury = val;                 end
  def self.guardant_thrusts=(val);    @@guardant_thrusts = val;     end
  def self.overpower=(val);           @@overpower = val;            end
  def self.pin_down=(val);            @@pin_down = val;             end
  def self.pulverize=(val);           @@pulverize = val;            end
  def self.pummel=(val);              @@pummel = val;               end
  def self.radial_sweep=(val);        @@radial_sweep = val;         end
  def self.reactive_shot=(val);       @@reactive_shot = val;        end
  def self.reverse_strike=(val);      @@reverse_strike = val;       end
  def self.riposte=(val);             @@riposte = val;              end
  def self.spin_kick=(val);           @@spin_kick = val;            end
  def self.thrash=(val);              @@thrash = val;               end
  def self.twin_hammerfists=(val);    @@twin_hammerfists = val;     end
  def self.volley=(val);              @@volley = val;               end
  def self.whirling_blade=(val);      @@whirling_blade = val;       end
  def self.whirlwind=(val);           @@whirlwind = val;            end

  @@cost_hash = { 'barrage' => 15, 'charge' => 14, 'clash' => 20, 'clobber' => 0, 'cripple' => 7, 'cyclone' => 20, 'dizzying_swing' => 7, 'flurry' => 15, 'fury' => 15, 'guardant_thrusts' => 15, 'overpower' => 0, 'pin_down' => 14, 'pulverize' => 20, 'pummel' => 15, 'radial_sweep' => 0, 'reactive_shot' => 0, 'reverse_strike' => 0, 'riposte' => 0, 'spin_kick' => 0, 'thrash' => 15, 'twin_hammerfists' => 7, 'volley' => 20, 'whirling_blade' => 20, 'whirlwind' => 20 }

  def self.method_missing(arg1, arg2 = nil)
    echo "#{arg1} is not a defined Weapon type.  Is it another Ability type?"
  end

  def self.[](name)
    Weapon.send(name.to_s.gsub(/[\s-]/, '_').gsub("'", '').downcase)
  end

  def self.[]=(name, val)
    Weapon.send("#{name.to_s.gsub(/[\s-]/, '_').gsub("'", '').downcase}=", val.to_i)
  end

  def self.known?(name)
    Weapon.send(name.to_s.gsub(/[\s-]/, '_').gsub("'", '').downcase) > 0
  end

  def self.affordable?(name)
    @@cost_hash.fetch(name.to_s.gsub(/[\s-]/, '_').gsub("'", '').downcase) < XMLData.stamina
  end

  def self.available?(name)
    Weapon.known?(name) and Weapon.affordable?(name) and
      !Lich::Util.normalize_lookup('Cooldowns', name) and !Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
  end
end
