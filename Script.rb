#===============================================================================
# * Select Music in Options - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It adds new settings in options screen
# to change wild battle, trainer battle, bicycle and surf musics.  
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main OR convert into a plugin.
#
#== NOTES ======================================================================
#
# Wild battle and trainer battle options are only for the ones without a
# specific music defined.
#
#===============================================================================

if defined?(PluginManager) && !PluginManager.installed?("Music Options")
  PluginManager.register({                                                 
    :name    => "Music Options",                                        
    :version => "1.0b",                                                     
    :link    => "https://www.pokecommunity.com/threads/526983/",             
    :credits => "FL"
  })
end

module MusicOption
  module_function

  # Marking as false disables the music option.
  WILD_BATTLE_ENABLED = true
  TRAINER_BATTLE_ENABLED = true
  BICYCLE_ENABLED = true
  SURF_ENABLED = true

  # When true, show all labels at same time at Options Screen.
  SHOW_ALL_LABELS = false

  RANDOM = -1
  OFF = nil
  SPECIAL_CASES_ARRAY = [RANDOM, OFF] # To won't be drawed in random.

  # Music label and filename. Change filenames to match yours.
  def wild_battle_name_bgm_array
    return [
      #["Music label here", "Filename here"],
      ["Standard","Battle wild"],
      ["Roaming","Battle roaming"],
      ["Random",RANDOM],
      ["Off",OFF],
    ]
  end

  def trainer_battle_name_bgm_array
    return [
      ["Standard","Battle trainer"],
      ["Gym Leader","Battle Gym Leader"],
      ["Random",RANDOM],
      ["Off",OFF],
    ]
  end

  def bicycle_name_bgm_array
    return [
      ["Standard","Bicycle"],
      ["Route","Route 1"],
      ["Random",RANDOM],
      ["Off",OFF],
    ]
  end

  def surf_name_bgm_array
    return [
      ["Standard","Surfing"],
      ["Route","Route 2"],
      ["Random",RANDOM],
      ["Off",OFF],
    ]
  end

  def on_bgm_call(original_value, setting, system_value, name_bgm_array)
    return original_value if !setting
    return MusicOption.format_bgm_to_play(
      name_bgm_array[system_value || 0][1], to_valid_bgm_array(name_bgm_array)
    )
  end
  
  # Handle exceptions, like random option
  def format_bgm_to_play(bgm_filename, valid_bgm_array)
    return valid_bgm_array[rand(valid_bgm_array.size)] if bgm_filename==RANDOM
    return bgm_filename
  end

  # Remove special cases (like Random and Off) and returns a bgm-only array
  def to_valid_bgm_array(name_bgm_array)
    return name_bgm_array.transpose[1].find_all{|filename|
      next !SPECIAL_CASES_ARRAY.include?(filename)
    }
  end
  
  def refresh_bgm(bgm_filename)
    bgm_filename ? pbBGMPlay(bgm_filename) : $game_map.autoplay
  end

  def enum_type
    return SHOW_ALL_LABELS ? EnumOption : MultiEnumOption
  end
end

class PokemonSystem
  attr_accessor :wild_battle_bgm
  attr_accessor :trainer_battle_bgm
  attr_accessor :bicycle_bgm
  attr_accessor :surf_bgm
end

module GameData
  class Metadata
    def wild_battle_BGM
      return MusicOption.on_bgm_call(
        @wild_battle_BGM, MusicOption::WILD_BATTLE_ENABLED, 
        $PokemonSystem.wild_battle_bgm, MusicOption.wild_battle_name_bgm_array
      )
    end

    def trainer_battle_BGM
      return MusicOption.on_bgm_call(
        @trainer_battle_BGM, MusicOption::TRAINER_BATTLE_ENABLED, 
        $PokemonSystem.trainer_battle_bgm,
        MusicOption.trainer_battle_name_bgm_array
      )
    end

    def bicycle_BGM
      return MusicOption.on_bgm_call(
        @bicycle_BGM, MusicOption::BICYCLE_ENABLED, 
        $PokemonSystem.bicycle_bgm, MusicOption.bicycle_name_bgm_array
      )
    end

    def surf_BGM
      return MusicOption.on_bgm_call(
        @surf_BGM, MusicOption::SURF_ENABLED, 
        $PokemonSystem.surf_bgm, MusicOption.surf_name_bgm_array
      )
    end
  end
end

# To support multiple bgm names at once. So won't fill the screen
# A Ctrl+C and Ctrl+V from EnumOption, to won't be called in options check.
class MultiEnumOption
  include PropertyMixin
  attr_reader :values

  def initialize(name, values, get_proc, set_proc)
    @name = name
    @values   = values.map { |val| _INTL(val) }
    @get_proc = get_proc
    @set_proc = set_proc
  end

  def next(current)
    index = current + 1
    index = @values.length - 1 if index > @values.length - 1
    return index
  end

  def prev(current)
    index = current - 1
    index = 0 if index < 0
    return index
  end
end

MenuHandlers.add(:options_menu, :wild_battle_bgm, {
  "name"        => _INTL("Wild Music"),
  "order"       => 150,
  "type"        => MusicOption.enum_type,
  "parameters"  => MusicOption.wild_battle_name_bgm_array.transpose[0],
  "description" => _INTL("Music playing in wild battles."),
  "get_proc"    => proc { next $PokemonSystem.wild_battle_bgm },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.wild_battle_bgm=value }
}) if MusicOption::WILD_BATTLE_ENABLED

MenuHandlers.add(:options_menu, :trainer_battle_bgm, {
  "name"        => _INTL("Trainer Music"),
  "order"       => 151,
  "type"        => MusicOption.enum_type,
  "parameters"  => MusicOption.trainer_battle_name_bgm_array.transpose[0],
  "description" => _INTL("Music playing in standard trainer battles."),
  "get_proc"    => proc { next $PokemonSystem.trainer_battle_bgm },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.trainer_battle_bgm = value }
}) if MusicOption::TRAINER_BATTLE_ENABLED

MenuHandlers.add(:options_menu, :bicycle_bgm, {
  "name"        => _INTL("Bicycle Music"),
  "order"       => 152,
  "type"        => MultiEnumOption,
  "parameters"  => MusicOption.bicycle_name_bgm_array.transpose[0],
  "description" => _INTL("Music playing while in bicycle."),
  "get_proc"    => proc { next $PokemonSystem.bicycle_bgm },
  "set_proc"    => proc { |value, _scene| 
    need_refresh= $PokemonSystem.bicycle_bgm != value && $PokemonGlobal&.bicycle
    $PokemonSystem.bicycle_bgm = value 
    MusicOption.refresh_bgm(GameData::Metadata.get.bicycle_BGM) if need_refresh
  }
}) if MusicOption::BICYCLE_ENABLED

MenuHandlers.add(:options_menu, :surf_bgm, {
  "name"        => _INTL("Surf Music"),
  "order"       => 153,
  "type"        => MultiEnumOption,
  "parameters"  => MusicOption.surf_name_bgm_array.transpose[0],
  "description" => _INTL("Music playing while surfing."),
  "get_proc"    => proc { next $PokemonSystem.surf_bgm },
  "set_proc"    => proc { |value, _scene| 
    need_refresh= $PokemonSystem.surf_bgm != value && $PokemonGlobal&.surfing
    $PokemonSystem.surf_bgm = value 
    MusicOption.refresh_bgm(GameData::Metadata.get.surf_BGM) if need_refresh
  }
}) if MusicOption::SURF_ENABLED