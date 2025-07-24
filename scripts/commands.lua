local TMGui = require 'scripts.team_manager_gui'
local Functions = require 'scripts.functions'
local player_with_color = Functions.player_with_color

-- /chain Joe
commands.add_command(
  'chain',
  '/chain <player_name>, restricts player from freely change teams [ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    if not event.parameter then
      player.print('/chain <player_name> missing 1st argument: <player_name> :: string')
      return
    end
    local target = game.get_player(event.parameter)
    if target and target.valid and not storage.restrict_player_from_changing_team[target.index] then
      game.print({'info.info_chain', player_with_color(player), player_with_color(target)})
      storage.restrict_player_from_changing_team[target.index] = true
      TMGui.toggle_main_button(target)
      TMGui.toggle_main_button(target)
    end
  end
)

-- /unchain Joe
commands.add_command(
  'unchain',
  '/unchain <player_name>, allows player to freely change teams [ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    if not event.parameter then
      player.print('/unchain <player_name> missing 1st argument: <player_name> :: string')
      return
    end
    local target = game.get_player(event.parameter)
    if target and target.valid and storage.restrict_player_from_changing_team[target.index] then
      game.print({'info.info_unchain', player_with_color(player), player_with_color(target)})
      storage.restrict_player_from_changing_team[target.index] = nil
      TMGui.toggle_main_button(target)
      TMGui.toggle_main_button(target)
    end
  end
)

-- /remove Joe
commands.add_command(
  'remove',
  '/remove <player_name>, remove a player from their current team and restricts the to "Player" force[ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    if not event.parameter then
      player.print('/remove <player_name> missing 1st argument: <player_name> :: string')
      return
    end
    local target = game.get_player(event.parameter)
    if target and target.valid then
      Functions.switch_force(player, game.forces.player)
      game.print({'info.info_chain', player_with_color(player), player_with_color(target)})
      storage.restrict_player_from_changing_team[target.index] = true
      TMGui.toggle_main_button(target)
      TMGui.toggle_main_button(target)
    end
  end
)

-- /rename 6 The best team ever
commands.add_command(
  'rename',
  '/rename <id> <name>, change the name of a team [ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    if not event.parameter then
      player.print('/rename  <id> <name>, wrong arguments <id> :: number | <name> :: string')
      return
    end
    local text = event.parameter
    local id = string.match(text, '^%d+') -- first number
    local name = string.match(text, ' (.*)') -- everything after space
    if not id or not name then
      return
    end
    id, name = tonumber(id), tostring(name)
    if not id or not type(id) == 'number' or not name or not type(name) == 'string' or name == '' then
      return
    end
    local force = game.forces['player_'..id]
    if not force or not force.valid or force.name == 'player' then
      return
    end
    local old = storage.team_names[force.name]
    storage.team_names[force.name] = name
    game.print({'info.rename_team', old, name})
  end
)

-- /set-team-status 6 true
commands.add_command(
  'set-team-status',
  '/set-team-status <id> <status>, sets a team status to open/close (true/false) [ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    if not event.parameter then
      player.print('/set-team-status  <id> <status>, wrong arguments <id> :: number | <status> :: boolean')
      return
    end
    local text = event.parameter
    local id = string.match(text, '^%d+') -- first number
    local status = string.match(text, ' (.*)') -- everything after space
    if not id or status == nil then
      return
    end
    id, status = tonumber(id), (string.lower(status) == 'true') and true or false
    if not id or not type(id) == 'number' or status == nil or not type(status) == 'boolean' then
      return
    end
    local force = game.forces['player_'..id]
    if not force or not force.valid or force.name == 'player' then
      return
    end
    storage.is_team_locked[force.name] = not status
    game.print({'info.team_status', player_with_color(player), Functions.get_team_name(force), status and 'open' or 'closed'})
  end
)

-- /switch_team 6 The best team ever
commands.add_command(
  'switch-team',
  '/switch-team <id> <player_name>, assign player to team number X (use 0 for global Player force) [ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    if not event.parameter then
      player.print('/switch-team  <id> <player_name>, wrong arguments <id> :: number | <player_name> :: string')
      return
    end
    local text = event.parameter
    local id = string.match(text, '^%d+') -- first number
    local name = string.match(text, ' (.*)') -- everything after space
    if not id or not name then
      return
    end
    id, name = tonumber(id), tostring(name)
    if not id or not type(id) == 'number' or not name or not type(name) == 'string' or name == '' then
      return
    end
    local force = game.forces['player_'..id]
    if id == 0 then
      force = game.forces.player
    end
    if not force or not force.valid then
      return
    end
    Functions.switch_force(player, force)
  end
)

commands.add_command(
  'teleport-to',
  '/teleport-to <planet_name> <player_name>, teleports a player to target planet',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    local err = '/teleport-to  <planet_name> <player_name?>, wrong arguments <planet_name> :: number | <player_name?> :: string (optional) or calling player'
    if not event.parameter then
      player.print(err)
      return
    end
    local params = {}
    for word in string.gmatch(event.parameter, '%S+') do
      table.insert(params, word)
    end
    if #params == 0 or #params > 2 then
      player.print(err)
      return
    end
    local surface = game.get_surface(params[1])
    local target = params[2] and game.get_player(params[2]) or player
    if not surface or not target then
      player.print(err)
      return
    end
    Functions.teleport(target.character, nil, surface, true)
  end
)

-- /reinstate-team 17 player_name
commands.add_command(
  'reinstate-team',
  '/reinstate-team <team_id> <player_name>, moves a player back to their original team while preserving research [ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    if not event.parameter then
      player.print('/reinstate-team <team_id> <player_name>, wrong arguments <team_id> :: number | <player_name> :: string')
      return
    end
    local text = event.parameter
    local id = string.match(text, '^%d+') -- first number
    local name = string.match(text, ' (.*)') -- everything after space
    if not id or not name then
      player.print('/reinstate-team <team_id> <player_name>, wrong arguments <team_id> :: number | <player_name> :: string')
      return
    end
    id, name = tonumber(id), tostring(name)
    if not id or not type(id) == 'number' or not name or not type(name) == 'string' or name == '' then
      player.print('/reinstate-team <team_id> <player_name>, wrong arguments <team_id> :: number | <player_name> :: string')
      return
    end
    local force = game.forces['player_'..id]
    if not force or not force.valid then
      player.print('Team '..id..' does not exist')
      return
    end
    local target = game.get_player(name)
    if not target or not target.valid then
      player.print('Player "'..name..'" not found')
      return
    end
    
    -- Additional safety check
    if not target.force or not target.force.valid then
      player.print('Player '..name..' has invalid force')
      return
    end
    
    -- Preserve research by merging current force's tech into destination force
    local source_force = target.force
    if source_force ~= force and source_force.valid and force.valid then
      -- Only merge if forces are different and both valid
      pcall(function()
        Functions.merge_technologies(source_force, force)
        Functions.merge_locations(source_force, force)
        game.print({'info.info_chain', player_with_color(player), string.format('Merged research from %s into %s', Functions.get_team_name(source_force), Functions.get_team_name(force))})
      end)
    end
    
    Functions.switch_force(target, force)
    game.print({'info.info_switch_team', player_with_color(player), player_with_color(target), Functions.get_team_name(force)})
  end
)

-- /make-teams-friendly
commands.add_command(
  'make-teams-friendly',
  '/make-teams-friendly, makes all team forces friendly to each other [ADMIN only]',
  function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) or not player.admin then
      return
    end
    
    -- Get all team forces
    local team_forces = {}
    for _, force in pairs(game.forces) do
      if Functions.starts_with(force.name, 'player_') then
        team_forces[#team_forces + 1] = force
      end
    end
    
    -- Make all team forces friendly to each other
    local count = 0
    for i, force1 in pairs(team_forces) do
      for j, force2 in pairs(team_forces) do
        if i ~= j then
          force1.set_friend(force2, true)
          force2.set_friend(force1, true)
          count = count + 1
        end
      end
      -- Also make them friendly with the global player force
      force1.set_friend(game.forces.player, true)
      game.forces.player.set_friend(force1, true)
    end
    
    game.print({'info.info_chain', player_with_color(player), string.format('Made %d team forces friendly to each other', #team_forces)})
  end
)