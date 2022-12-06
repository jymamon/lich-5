## breakout for CMan released with PSM3
## modifed code for 5.0.16
## includes new functions .known? and .affordable?

class CMan
  @@acrobats_leap          ||= 0
  @@bearhug                ||= 0
  @@berserk                ||= 0
  @@block_specialization   ||= 0
  @@bull_rush              ||= 0
  @@burst_of_swiftness     ||= 0
  @@cheapshots             ||= 0
  @@combat_focus           ||= 0
  @@combat_mobility        ||= 0
  @@combat_movement        ||= 0
  @@combat_toughness       ||= 0
  @@coup_de_grace          ||= 0
  @@crowd_press            ||= 0
  @@cunning_defense        ||= 0
  @@cutthroat              ||= 0
  @@dirtkick               ||= 0
  @@disarm_weapon          ||= 0
  @@dislodge               ||= 0
  @@divert                 ||= 0
  @@duck_and_weave         ||= 0
  @@dust_shroud            ||= 0
  @@evade_specialization   ||= 0
  @@eviscerate             ||= 0
  @@executioners_stance    ||= 0
  @@exsanguinate           ||= 0
  @@eyepoke                ||= 0
  @@feint                  ||= 0
  @@flurry_of_blows        ||= 0
  @@footstomp              ||= 0
  @@garrote                ||= 0
  @@grappel_specialization ||= 0
  @@griffins_voice         ||= 0
  @@groin_kick             ||= 0
  @@hamstring              ||= 0
  @@haymaker               ||= 0
  @@headbutt               ||= 0
  @@inner_harmony          ||= 0
  @@internal_power         ||= 0
  @@ki_focus               ||= 0
  @@kick_specialization    ||= 0
  @@kneebash               ||= 0
  @@leap_attack            ||= 0
  @@mighty_blow            ||= 0
  @@mug                    ||= 0
  @@nosetweak              ||= 0
  @@parry_specialization   ||= 0
  @@precision              ||= 0
  @@predators_eye          ||= 0
  @@punch_specialization   ||= 0
  @@retreat                ||= 0
  @@rolling_krynch_stance  ||= 0
  @@shield_bash            ||= 0
  @@side_by_side           ||= 0
  @@slippery_mind          ||= 0
  @@spell_cleave           ||= 0
  @@spell_parry            ||= 0
  @@spell_thieve           ||= 0
  @@spike_focus            ||= 0
  @@spin_attack            ||= 0
  @@staggering_blow        ||= 0
  @@stance_perfection      ||= 0
  @@stance_of_the_mongoose ||= 0
  @@striking_asp           ||= 0
  @@stun_maneuvers         ||= 0
  @@subdue                 ||= 0
  @@sucker_punch           ||= 0
  @@sunder_shield          ||= 0
  @@surge_of_strength      ||= 0
  @@sweep                  ||= 0
  @@swiftkick              ||= 0
  @@tackle                 ||= 0
  @@tainted_bond           ||= 0
  @@templeshot             ||= 0
  @@throatchop             ||= 0
  @@trip                   ||= 0
  @@true_strike            ||= 0
  @@unarmed_specialist     ||= 0
  @@vault_kick             ||= 0
  @@weapon_specialization  ||= 0
  @@whirling_dervish       ||= 0

  def self.acrobats_leap;                @@acrobats_leap;              end
  def self.bearhug;                      @@bearhug;                    end
  def self.berserk;                      @@berserk;                    end
  def self.block_specialization;         @@block_specialization;       end
  def self.bull_rush;                    @@bull_rush;                  end
  def self.burst_of_swiftness;           @@burst_of_swiftness;         end
  def self.cheapshots;                   @@cheapshots;                 end
  def self.combat_focus;                 @@combat_focus;               end
  def self.combat_mobility;              @@combat_mobility;            end
  def self.combat_movement;              @@combat_movement;            end
  def self.combat_toughness;             @@combat_toughness;           end
  def self.coup_de_grace;                @@coup_de_grace;              end
  def self.crowd_press;                  @@crowd_press;                end
  def self.cunning_defense;              @@cunning_defense;            end
  def self.cutthroat;                    @@cutthroat;                  end
  def self.dirtkick;                     @@dirtkick;                   end
  def self.disarm_weapon;                @@disarm_weapon;              end
  def self.dislodge;                     @@dislodge;                   end
  def self.divert;                       @@divert;                     end
  def self.duck_and_weave;               @@duck_and_weave;             end
  def self.dust_shroud;                  @@dust_shroud;                end
  def self.evade_specialization;         @@evade_specialization;       end
  def self.eviscerate;                   @@eviscerate;                 end
  def self.executioners_stance;          @@executioners_stance;        end
  def self.exsanguinate;                 @@exsanguinate;               end
  def self.eyepoke;                      @@eyepoke;                    end
  def self.feint;                        @@feint;                      end
  def self.flurry_of_blows;              @@flurry_of_blows;            end
  def self.footstomp;                    @@footstomp;                  end
  def self.garrote;                      @@garrote;                    end
  def self.grapple_specialization;       @@grapple_specialization;     end
  def self.griffins_voice;               @@griffins_voice;             end
  def self.groin_kick;                   @@groin_kick;                 end
  def self.hamstring;                    @@hamstring;                  end
  def self.haymaker;                     @@haymaker;                   end
  def self.headbutt;                     @@headbutt;                   end
  def self.inner_harmony;                @@inner_harmony;              end
  def self.internal_power;               @@internal_power;             end
  def self.ki_focus;                     @@ki_focus;                   end
  def self.kick_specialization;          @@kick_specialization;        end
  def self.kneebash;                     @@kneebash;                   end
  def self.leap_attack;                  @@leap_attack;                end
  def self.mighty_blow;                  @@mighty_blow;                end
  def self.mug;                          @@mug;                        end
  def self.nosetweak;                    @@nosetweak;                  end
  def self.parry_specialization;         @@parry_specialization;       end
  def self.precision;                    @@precision;                  end
  def self.predators_eye;                @@predators_eye;              end
  def self.punch_specialization;         @@punch_specialization;       end
  def self.retreat;                      @@retreat;                    end
  def self.rolling_krynch_stance;        @@rolling_krynch_stance;      end
  def self.shield_bash;                  @@shield_bash;                end
  def self.side_by_side;                 @@side_by_side;               end
  def self.slippery_mind;                @@slippery_mind;              end
  def self.spell_cleave;                 @@spell_cleave;               end
  def self.spell_parry;                  @@spell_parry;                end
  def self.spell_thieve;                 @@spell_thieve;               end
  def self.spike_focus;                  @@spike_focus;                end
  def self.spin_attack;                  @@spin_attack;                end
  def self.staggering_blow;              @@staggering_blow;            end
  def self.stance_perfection;            @@stance_perfection;          end
  def self.stance_of_the_mongoose;       @@stance_of_the_mongoose;     end
  def self.striking_asp;                 @@striking_asp;               end
  def self.stun_maneuvers;               @@stun_maneuvers;             end
  def self.subdue;                       @@subdue;                     end
  def self.sucker_punch;                 @@sucker_punch;               end
  def self.sunder_shield;                @@sunder_shield;              end
  def self.surge_of_strength;            @@surge_of_strength;          end
  def self.sweep;                        @@sweep;                      end
  def self.swiftkick;                    @@swiftkick;                  end
  def self.tackle;                       @@tackle;                     end
  def self.tainted_bond;                 @@tainted_bond;               end
  def self.templeshot;                   @@templeshot;                 end
  def self.throatchop;                   @@throatchop;                 end
  def self.trip;                         @@trip;                       end
  def self.true_strike;                  @@true_strike;                end
  def self.unarmed_specialist;           @@unarmed_specialist;         end
  def self.vault_kick;                   @@vault_kick;                 end
  def self.weapon_specialization;        @@weapon_specialization;      end
  def self.whirling_dervish;             @@whirling_dervish;           end

  def self.acrobats_leap=(val);          @@acrobats_leap = val;              end
  def self.bearhug=(val);                @@bearhug = val;                    end
  def self.berserk=(val);                @@berserk = val;                    end
  def self.block_specialization=(val);   @@block_specialization = val;       end
  def self.bull_rush=(val);              @@bull_rush = val;                  end
  def self.burst_of_swiftness=(val);     @@burst_of_swiftness = val;         end
  def self.cheapshots=(val);             @@cheapshots = val;                 end
  def self.combat_focus=(val);           @@combat_focus = val;               end
  def self.combat_mobility=(val);        @@combat_mobility = val;            end
  def self.combat_movement=(val);        @@combat_movement = val;            end
  def self.combat_toughness=(val);       @@combat_toughness = val;           end
  def self.coup_de_grace=(val);          @@coup_de_grace = val;              end
  def self.crowd_press=(val);            @@crowd_press = val;                end
  def self.cunning_defense=(val);        @@cunning_defense = val;            end
  def self.cutthroat=(val);              @@cutthroat = val;                  end
  def self.dirtkick=(val);               @@dirtkick = val;                   end
  def self.disarm_weapon=(val);          @@disarm_weapon = val;              end
  def self.dislodge=(val);               @@dislodge = val;                   end
  def self.divert=(val);                 @@divert = val;                     end
  def self.duck_and_weave=(val);         @@duck_and_weave = val;             end
  def self.dust_shroud=(val);            @@dust_shroud = val;                end
  def self.evade_specialization=(val);   @@evade_specialization = val;       end
  def self.eviscerate=(val);             @@eviscerate = val;                 end
  def self.executioners_stance=(val);    @@executioners_stance = val;        end
  def self.exsanguinate=(val);           @@exsanguinate = val;               end
  def self.eyepoke=(val);                @@eyepoke = val;                    end
  def self.feint=(val);                  @@feint = val;                      end
  def self.flurry_of_blows=(val);        @@flurry_of_blows = val;            end
  def self.footstomp=(val);              @@footstomp = val;                  end
  def self.garrote=(val);                @@garrote = val;                    end
  def self.grapple_specialization=(val); @@grapple_specialization = val;     end
  def self.griffins_voice=(val);         @@griffins_voice = val;             end
  def self.groin_kick=(val);             @@groin_kick = val;                 end
  def self.hamstring=(val);              @@hamstring = val;                  end
  def self.haymaker=(val);               @@haymaker = val;                   end
  def self.headbutt=(val);               @@headbutt = val;                   end
  def self.inner_harmony=(val);          @@inner_harmony = val;              end
  def self.internal_power=(val);         @@internal_power = val;             end
  def self.ki_focus=(val);               @@ki_focus = val;                   end
  def self.kick_specialization=(val);    @@kick_specialization = val;        end
  def self.kneebash=(val);               @@kneebash = val;                   end
  def self.leap_attack=(val);            @@leap_attack = val;                end
  def self.mighty_blow=(val);            @@mighty_blow = val;                end
  def self.mug=(val);                    @@mug = val;                        end
  def self.nosetweak=(val);              @@nosetweak = val;                  end
  def self.parry_specialization=(val);   @@parry_specialization = val;       end
  def self.precision=(val);              @@precision = val;                  end
  def self.predators_eye=(val);          @@predators_eye = val;              end
  def self.punch_specialization=(val);   @@punch_specialization = val;       end
  def self.retreat=(val);                @@retreat = val;                    end
  def self.rolling_krynch_stance=(val);  @@rolling_krynch_stance = val;      end
  def self.shield_bash=(val);            @@shield_bash = val;                end
  def self.side_by_side=(val);           @@side_by_side = val;               end
  def self.slippery_mind=(val);          @@slippery_mind = val;              end
  def self.spell_cleave=(val);           @@spell_cleave = val;               end
  def self.spell_parry=(val);            @@spell_parry = val;                end
  def self.spell_thieve=(val);           @@spell_thieve = val;               end
  def self.spike_focus=(val);            @@spike_focus = val;                end
  def self.spin_attack=(val);            @@spin_attack = val;                end
  def self.staggering_blow=(val);        @@staggering_blow = val;            end
  def self.stance_perfection=(val);      @@stance_perfection = val;          end
  def self.stance_of_the_mongoose=(val); @@stance_of_the_mongoose = val;     end
  def self.striking_asp=(val);           @@striking_asp = val;               end
  def self.stun_maneuvers=(val);         @@stun_maneuvers = val;             end
  def self.subdue=(val);                 @@subdue = val;                     end
  def self.sucker_punch=(val);           @@sucker_punch = val;               end
  def self.sunder_shield=(val);          @@sunder_shield = val;              end
  def self.surge_of_strength=(val);      @@surge_of_strength = val;          end
  def self.sweep=(val);                  @@sweep = val;                      end
  def self.swiftkick=(val);              @@swiftkick = val;                  end
  def self.tackle=(val);                 @@tackle = val;                     end
  def self.tainted_bond=(val);           @@tainted_bond = val;               end
  def self.templeshot=(val);             @@templeshot = val;                 end
  def self.throatchop=(val);             @@throatchop = val;                 end
  def self.trip=(val);                   @@trip = val;                       end
  def self.true_strike=(val);            @@true_strike = val;                end
  def self.unarmed_specialist=(val);     @@unarmed_specialist = val;         end
  def self.vault_kick=(val);             @@vault_kick = val;                 end
  def self.weapon_specialization=(val);  @@weapon_specialization = val;      end
  def self.whirling_dervish=(val);       @@whirling_dervish = val;           end

  @@cost_hash = { 'acrobats_leap' => 0, 'bearhug' => 10, 'berserk' => 30, 'block_specialization' => 0, 'bull_rush' => 14, 'burst_of_swiftness' => 30, 'cheapshots' => 7, 'combat_focus' => 0, 'combat_mobility' => 0, 'combat_movement' => 0, 'combat_toughness' => 0, 'coup_de_grace' => 20, 'crowd_press' => 9, 'cunning_defense' => 0, 'cutthroat' => 14, 'dirtkick' => 7, 'disarm_weapon' => 7, 'dislodge' => 9, 'divert' => 7, 'duck_and_weave' => 20, 'dust_shroud' => 10, 'evade_specialization' => 0, 'eviscerate' => 14, 'executioners_stance' => 20, 'exsanguinate' => 15, 'eyepoke' => 7, 'feint' => 9, 'flurry_of_blows' => 20, 'footstomp' => 7, 'garrote' => 10, 'grapple_specialization' => 0, 'griffins_voice' => 20, 'groin_kick' => 7, 'hamstring' => 9, 'haymaker' => 9, 'headbutt' => 9, 'inner_harmony' => 20, 'internal_power' => 20, 'ki_focus' => 20, 'kick_specialization' => 0, 'kneebash' => 7, 'leap_attack' => 15, 'mighty_blow' => 15, 'mug' => 15, 'nosetweak' => 7, 'parry_specialization' => 0, 'precision' => 0, 'predators_eye' => 20, 'punch_specialization' => 0, 'retreat' => 30, 'rolling_krynch_stance' => 20, 'shield_bash' => 9, 'side_by_side' => 0, 'slippery_mind' => 20, 'spell_cleave' => 7, 'spell_parry' => 0, 'spell_thieve' => 7, 'spike_focus' => 0, 'spin_attack' => 15, 'staggering_blow' => 15, 'stance_perfection' => 0, 'stance_of_the_mongoose' => 20, 'striking_asp' => 20, 'stun_maneuvers' => 10, 'subdue' => 9, 'sucker_punch' => 7, 'sunder_shield' => 7, 'surge_of_strength' => 30, 'sweep' => 7, 'swiftkick' => 7, 'tackle' => 7, 'tainted_bond' => 0, 'templeshot' => 7, 'throatchop' => 7, 'trip' => 7, 'true_strike' => 15, 'unarmed_specialist' => 0, 'vault_kick' => 30, 'weapon_specialization' => 0, 'whirling_dervish' => 20 }

  def self.method_missing(arg1, arg2 = nil)
    echo "#{arg1} is not a defined CMan.  Was it moved to another Ability?"
  end

  def self.[](name)
    CMan.send(name.to_s.gsub(/[\s\-]/, '_').gsub("'", '').downcase)
  end

  def self.[]=(name, val)
    CMan.send("#{name.to_s.gsub(/[\s\-]/, '_').gsub("'", '').downcase}=", val.to_i)
  end

  def self.known?(name)
    CMan.send(name.to_s.gsub(/[\s\-]/, '_').gsub("'", '').downcase) > 0
  end

  def self.affordable?(name)
    @@cost_hash.fetch(name.to_s.gsub(/[\s\-]/, '_').gsub("'", '').downcase) < XMLData.stamina
  end

  def self.available?(name)
    CMan.known?(name) and CMan.affordable?(name) and
      !Lich::Util.normalize_lookup('Cooldowns', name) and !Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
  end
end
