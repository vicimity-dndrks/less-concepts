-- less concepts:
-- cellular automata sequencer
-- v2.1.2 (crow) @dan_derks (v.2.1.3b (w/syn + clock + mutes) @linusschrab)
-- llllllll.co/t/less-concepts/
--
-- hold key 1: switch between
-- less concepts +
-- ~ r e f r a i n
--
-- enc 1: navigate
-- enc 2: change left side //
-- enc 3: // change right side
--
-- key 3: randomize selected
-- key 2: take snapshot (*)
-- when * selected...
-- key 2: recall snapshot
-- hold key 2 then key 3 (NEW):
-- delete selected snapshot
-- params: midi, +/- st, timbre,
-- probabilities, delay settings,
-- save snapshots to set (NEW)
--
-- plug in grid
-- (1,1) to (8,2): bits
-- (1, 9) and (2, 9) : mutes bits
-- (10,1) to (16,2): octaves
-- (1,3) to (16,3): randomize
-- (1,4) to (16,5): low
-- (1,6) to (16,7): high
-- (16,8): take snapshot
-- (15,8): clear all snapshots
-- (14,8): clear selected
-- (1,8) to (8,8): snapshots
-- (9,8) to (13,8): clock divisions
-- (9,8): lower two steps of division (1/4 - 1/2)
-- (10,8): lower one step of division (1/4 - 1/4T)
-- (11,8): reeturn to default division (1/4)
-- (12,8): raise one step of division (1/4 - 1/8T)
-- (9,8): raise two steps of division (1/4 - 1/8)
--
-- seek.
-- think.
-- discover.

local seed = 0
local rule = 0
local next_seed = nil
local new_low = 1
local new_high = 14
local coll = 1
local new_seed = seed
local new_rule = rule
local screen_focus = 1
local selected_preset = 0
local KEY2 = false
local KEY3 = false
local voice = {}
for i = 1,2 do
  voice[i] = {}
  voice[i].bit = 0
  voice[i].octave = 0
  voice[i].active_notes = {}
  voice[i].ch = 1
end
--local v1_bit = 1
--local v2_bit = 5
--local v1_octave = 0
--local v2_octave = 0
--local ch_1 = 1
--local ch_2 = 1
local semi = 0
local preset_count = 0
local active_notes_v1 = {}
local active_notes_v2 = {}
names = {"ionian","aeolian", "dorian", "phrygian", "lydian", "mixolydian", "major_pent", "minor_pent", "shang", "jiao", "zhi", "todi", "purvi", "marva", "bhairav", "ahirbhairav", "chromatic"}
edit_foci = {"seed/rule",
  "lc_gate_probs",
  "low/high",
  "rand_prob",
  "octaves",
  "lc_bits",
  "clock",
  "presets"
}
local edit = "seed/rule"
local dd = 0
random_gate = {}
for i = 1,4 do
  random_gate[i] = {}
  random_gate[i].comparator = 99
  random_gate[i].probability = 100
end
random_note = {}
for i = 1,2 do
  random_note[i] = {}
  random_note[i].tran = 0
  random_note[i].down = 0
  random_note[i].comparator = 99
  random_note[i].probability = 100
  random_note[i].add = 0
end
new_preset_pool = {}
for i = 1,9 do
  new_preset_pool[i] = {}
  new_preset_pool[i].seed = {}
  new_preset_pool[i].rule = {}
  new_preset_pool[i].v1_bit = {}
  new_preset_pool[i].v2_bit = {}
  new_preset_pool[i].new_low = {}
  new_preset_pool[i].new_high = {}
  new_preset_pool[i].v1_octave = {}
  new_preset_pool[i].v2_octave = {}
  new_preset_pool[i].sel_ppqn_div = {}
end

local sel_ppqn_div = 5
local ppqn_divisions = {1/4  , 1/3   , 1/2  , 1/1.5 , 1/1  , 1.5/1 , 2/1  ,  3/1   , 4/1   , 6/1    , 8/1}
local ppqn_names     = {'1/1', '1/2T', '1/2', '1/4T', '1/4', '1/8T', '1/8', '1/16T', '1/16', '1/32T', '1/32'}
ppqn_counter = 1

engine.name = "Passersby"
passersby = include "passersby/lib/passersby_engine"

local options = {}
options.OUTPUT = {"audio + midi", "crow cv (1x v/8)", "crow cv (2x v/8)", "crow ii JF", "crow cv + JF", "audio+cv+JF", "crow w/syn"}


-- this section is all maths + computational events

-- maths: translate the seed integer to binary
local function seed_to_binary()
  seed_as_binary = {}
  for i = 0,7 do
    table.insert(seed_as_binary, (seed & (2 ^ i)) >> i)
  end
end

-- maths: translate the rule integer to binary
local function rule_to_binary()
  rule_as_binary = {}
  for i = 0,7 do
    table.insert(rule_as_binary, (rule & (2 ^ i)) >> i)
  end
end

-- maths: basic compare function, used in bang()
local function compare (s, n)
  if type(s) == type(n) then
        if type(s) == "table" then
                  for loop=1, 3 do
                    if compare (s[loop], n[loop]) == false then
                        return false
                    end
                  end

                return true
        else
            return s == n
        end
    end
    return false
end

-- maths: scale seeds to the note pool + range selected
local function scale(lo, hi, received)
  scaled = math.floor(((((received-1) / (256-1)) * (hi - lo) + lo)))
  pass_to_refrain = received
end

-- pack the seeds into clusters, compare these against neighborhoods to determine gates in iterate()
local function bang()
  redraw()
  seed_to_binary()
  rule_to_binary()
  seed_pack1 = {seed_as_binary[1], seed_as_binary[8], seed_as_binary[7]}
  seed_pack2 = {seed_as_binary[8], seed_as_binary[7], seed_as_binary[6]}
  seed_pack3 = {seed_as_binary[7], seed_as_binary[6], seed_as_binary[5]}
  seed_pack4 = {seed_as_binary[6], seed_as_binary[5], seed_as_binary[4]}
  seed_pack5 = {seed_as_binary[5], seed_as_binary[4], seed_as_binary[3]}
  seed_pack6 = {seed_as_binary[4], seed_as_binary[3], seed_as_binary[2]}
  seed_pack7 = {seed_as_binary[3], seed_as_binary[2], seed_as_binary[1]}
  seed_pack8 = {seed_as_binary[2], seed_as_binary[1], seed_as_binary[8]}
  
  neighborhoods1 = {1,1,1}
  neighborhoods2 = {1,1,0}
  neighborhoods3 = {1,0,1}
  neighborhoods4 = {1,0,0}
  neighborhoods5 = {0,1,1}
  neighborhoods6 = {0,1,0}
  neighborhoods7 = {0,0,1}
  neighborhoods8 = {0,0,0}
  
  local function com (seed_packN, lshift, mask)
    if compare (seed_packN,neighborhoods1) then
      return (rule_as_binary[8] << lshift) & mask
    elseif compare (seed_packN, neighborhoods2) then
      return (rule_as_binary[7] << lshift) & mask
    elseif compare (seed_packN, neighborhoods3) then
      return (rule_as_binary[6] << lshift) & mask
    elseif compare (seed_packN, neighborhoods4) then
      return (rule_as_binary[5] << lshift) & mask
    elseif compare (seed_packN, neighborhoods5) then
      return (rule_as_binary[4] << lshift) & mask
    elseif compare (seed_packN, neighborhoods6) then
      return (rule_as_binary[3] << lshift) & mask
    elseif compare (seed_packN, neighborhoods7) then
      return (rule_as_binary[2] << lshift) & mask
    elseif compare (seed_packN, neighborhoods8) then
      return (rule_as_binary[1] << lshift) & mask
    else return (0 << lshift) & mask
    end
  end
  
  out1 = com(seed_pack1, 7, 128)
  out2 = com(seed_pack2, 6, 64)
  out3 = com(seed_pack3, 5, 32)
  out4 = com(seed_pack4, 4, 16)
  out5 = com(seed_pack5, 3, 8)
  out6 = com(seed_pack6, 2, 4)
  out7 = com(seed_pack7, 1, 2)
  out8 = com(seed_pack8, 0, 1)
  
  next_seed = out1+out2+out3+out4+out5+out6+out7+out8
end

local function notes_off(n)
  for i=1,#voice[n].active_notes do
    m:note_off(voice[n].active_notes[i],0,voice[n].ch)
  end
  voice[n].active_notes = {}
end

local function notes_off_v1()
  for i=1,#voice[1].active_notes do
    m:note_off(voice[1].active_notes[i],0,voice[1].ch)
  end
  voice[1].active_notes = {}
end

local function notes_off_v2()
  for i=1,#voice[2].active_notes do
    m:note_off(voice[2].active_notes[i],0,voice[2].ch)
  end
  voice[2].active_notes = {}
end

-- if user-defined bit in the binary version of a seed equals 1, then note event [aka, bit-wise gating]

local function iterate()
  if ppqn_counter >= 96 / ppqn_divisions[sel_ppqn_div] then
    ppqn_counter = 0
    for i = 1,2 do notes_off(i) end
    seed = next_seed
    bang()
    scale(new_low,new_high,seed)
    for i = 1,2 do
      if seed_as_binary[voice[i].bit] == 1 then
        random_gate[i].comparator = math.random(0,100)
        if random_gate[i].comparator < random_gate[i].probability then
          random_note[i].comparator = math.random(0,100)
          if random_note[i].comparator < random_note[i].probability then
            random_note[i].add = random_note[i].tran
          else
            random_note[i].add = 0
          end
          if params:get("output") == 1 then
            engine.noteOn(i,midi_to_hz((notes[coll][scaled])+(48+(voice[i].octave * 12)+semi+random_note[i].add)),127)
            m:note_on((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add),127,voice[i].ch)
          elseif params:get("output") == 2 then
            if i == 1 then
              crow.output[1].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[2].execute()
            elseif i == 2 then
              crow.output[1].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[2].execute()
            end
          elseif params:get("output") == 3 then
            if i == 1 then
              crow.output[i].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[i+1].execute()
            elseif i == 2 then
              crow.output[i+1].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[i+2].execute()
            end
          elseif params:get("output") == 4 then
            if i == 1 then
              crow.ii.jf.play_note(((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12,5)
            elseif i == 2 then
              crow.ii.jf.play_note(((notes[coll][scaled])+(36+(voice[2].octave*12)+semi+random_note[2].add)-48)/12,5)
            end
           elseif params:get("output") == 5 then
            if i == 1 then
              crow.ii.jf.play_note(((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12,5)
              crow.output[i].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[i+1].execute()
            elseif i == 2 then
              crow.ii.jf.play_note(((notes[coll][scaled])+(36+(voice[2].octave*12)+semi+random_note[2].add)-48)/12,5)
              crow.output[i+1].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[i+2].execute()
            end
          elseif params:get("output") == 6 then
            engine.noteOn(i,midi_to_hz((notes[coll][scaled])+(48+(voice[i].octave * 12)+semi+random_note[i].add)),127)
            if i == 1 then
              crow.ii.jf.play_note(((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12,5)
              crow.output[i].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[i+1].execute()
            elseif i == 2 then
              crow.ii.jf.play_note(((notes[coll][scaled])+(36+(voice[2].octave*12)+semi+random_note[2].add)-48)/12,5)
              crow.output[i+1].volts = (((notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add)-48)/12)
              crow.output[i+2].execute()
            end
            elseif params:get("output") == 7 then
              if i == 1 then
                crow.send("ii.wsyn.play_note(".. ((notes[coll][scaled])+(36+(voice[1].octave*12)+semi+random_note[1].add)-48)/12 ..", " .. 5 .. ")")
              elseif i == 2 then
                crow.send("ii.wsyn.play_note(".. ((notes[coll][scaled])+(36+(voice[2].octave*12)+semi+random_note[2].add)-48)/12 ..", " .. 5 .. ")")
            end
          end
          table.insert(voice[i].active_notes,(notes[coll][scaled])+(36+(voice[i].octave*12)+semi+random_note[i].add))
        end
    end

    -- EVENTS FOR R E F R A I N
      if seed_as_binary[track[i].bit] == 1 then
        random_gate[i+2].comparator = math.random(0,100)
        if random_gate[i+2].comparator < random_gate[i+2].probability then
          refrain.reset(i,pass_to_refrain)
        end
      end
    end
    redraw()
    grid_dirty = true
  end
end

function change(s)
  if s == 1 then
    iterate()
  end
end

-- convert midi note to hz for Passersby engine
function midi_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end

-- allow user to define the MIDI channel voice 1 sends on
local function midi_vox_1(channel)
  voice[1].ch = channel
end

-- allow user to define the MIDI channel voice 2 sends on
local function midi_vox_2(channel)
  voice[2].ch = channel
end

-- allow user to define the transposition of voice 1 and voice 2, simultaneous changes to MIDI and Passersby engine
local function transpose(semitone)
  semi = semitone
end

refrain = include "lib/refrain"

function wsyn_add_params()
  params:add_separator("W/Syn")
  params:add {
    type = "option",
    id = "wsyn_ar_mode",
    name = "AR mode",
    options = {"off", "on"},
    action = function(val) crow.send("ii.wsyn.ar_mode(" .. (val - 1) .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_curve",
    name = "Curve",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) crow.send("ii.wsyn.curve(" .. val .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_ramp",
    name = "Ramp",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) crow.send("ii.wsyn.ramp(" .. val .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_index",
    name = "FM index",
    controlspec = controlspec.new(0, 5, "lin", 0, 0, "v"),
    action = function(val) crow.send("ii.wsyn.fm_index(" .. val .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_env",
    name = "FM env",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) crow.send("ii.wsyn.fm_env(" .. val .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_ratio_num",
    name = "FM ratio numerator",
    controlspec = controlspec.new(1, 20, "lin", 1, 2),
    action = function(val) crow.send("ii.wsyn.fm_ratio(" .. val .. "," .. params:get("wsyn_fm_ratio_den") .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_fm_ratio_den",
    name = "FM ratio denominator",
    controlspec = controlspec.new(1, 20, "lin", 1, 1),
    action = function(val) crow.send("ii.wsyn.fm_ratio(" .. params:get("wsyn_fm_ratio_num") .. "," .. val .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_lpg_time",
    name = "LPG time",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) crow.send("ii.wsyn.lpg_time(" .. val .. ")") end
  }
  params:add {
    type = "control",
    id = "wsyn_lpg_symmetry",
    name = "LPG symmetry",
    controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
    action = function(val) crow.send("ii.wsyn.lpg_symmetry(" .. val .. ")") end
  }
end

function pulse()
  while true do
    clock.sync(1/96)
    ppqn_counter = ppqn_counter + 1
    iterate()
  end
end

-- everything that happens when the script is first loaded
function init()
  -- for testing purposes (REMOVE WHEN DONE)
  voice[1].bit = 1
  voice[2].bit = 8
  seed = 36
  rule = 30
  new_seed = seed
  new_rule = rule
  
  grid_dirty = true
  clock.run(grid_redraw_clock) -- start the grid redraw clock
  math.randomseed(os.time())
  math.random(); math.random(); math.random()
  seed_to_binary()
  rule_to_binary()
  g = grid.connect()
  g:led(new_low,4,15)
  g:led(new_high,6,15)
  g:led(voice[1].octave+13,1,15)
  g:led(voice[2].octave+13,2,15)
  grid_dirty = true
  --g:refresh()
  params:add_number("set", "set", 1,100,1)
  params:set_action("set", function (x) selected_set = x end)
  params:add{type = "trigger", id = "load", name = "load", action = loadstate}
  params:add{type = "trigger", id = "save", name = "save", action = savestate}
  params:add_separator()
  m = midi.connect()

  params:add_number("midi ch vox 1", "midi ch: vox 1", 1,16,1)
  params:set_action("midi ch vox 1", function (x) midi_vox_1(x) end)
  params:add_number("midi ch vox 2", "midi ch: vox 2", 1,16,1)
  params:set_action("midi ch vox 2", function (x) midi_vox_2(x) end)
  params:add_separator()
  params:add{type = "option", id = "output", name = "output",
    options = options.OUTPUT,
    action = function(value)
      if value == 1 then
        crow.ii.jf.mode(0)
      elseif value == 2 then
        crow.ii.jf.mode(0)
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 3 then
        crow.ii.jf.mode(0)
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
        crow.output[4].action = "{to(5,0),to(0,0.25)}"
      elseif value == 4 then
        crow.ii.jf.mode(1)
      elseif value == 5 then
        crow.ii.jf.mode(1)
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
        crow.output[4].action = "{to(5,0),to(0,0.25)}"
      elseif value == 6 then
        crow.ii.jf.mode(1)
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
        crow.output[4].action = "{to(5,0),to(0,0.25)}"
      elseif value == 7 then
        crow.ii.jf.mode(0)
      end
    end}

  params:add_separator()
  params:add_option("scale", "scale", names, 1)
  params:set_action("scale", function(x) coll = x end)
  params:add_number("global transpose", "global transpose", -24,24,0)
  params:set_action("global transpose", function (x) transpose(x) end)
  for i = 1,2 do
    params:add_control("transpose "..i, "transpose "..i, controlspec.new(-24,24,'lin',1,12,'s/t'))
    params:set_action("transpose "..i, function(x) random_note[i].tran = x end)
    params:add_control("tran prob "..i, "tran prob "..i, controlspec.new(0,100,'lin',1,0,'%'))
    params:set_action("tran prob " ..i, function(x) random_note[i].probability = x end)
  end
  for i = 1,2 do
    params:add_control("gate prob "..i, "gate prob "..i, controlspec.new(0,100,'lin',1,100,'%'))
    params:set_action("gate prob "..i, function(x) random_gate[i].probability = x end)
  end
  refrain.init()
  wsyn_add_params()
  passersby.add_params()
  bang()

  notes = { {0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48,50,52,53},
            {0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48,50,51,53},
            {0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48,50,51,53},
            {0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48,49,51,53},
            {0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48,50,52,54},
            {0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48,50,52,53},
            {0,2,4,7,9,12,14,16,19,21,24,26,28,31,33,36,38,40,43,45,48,50,52,55,57,60,62,64,67,69,71,74},
            {0,3,5,7,10,12,15,17,19,22,24,27,29,31,34,36,39,41,43,46,48,51,53,55,58,60,63,65,67,70,72,74},
            {0,2,5,7,10,12,14,17,19,22,24,26,29,31,34,36,38,41,43,46,48,50,53,55,58,60,62,65,67,69,72,74},
            {0,3,5,8,10,12,15,17,20,22,24,27,29,32,34,36,39,41,44,46,48,51,53,56,58,60,63,65,68,71,73,76},
            {0,2,5,7,9,12,14,17,19,21,24,26,29,31,33,36,38,41,43,45,48,50,53,55,57,60,62,65,67,69,72,74},
            {0,1,3,6,7,8,11,12,13,15,18,19,20,23,24,25,27,30,31,32,35,36,37,39,42,43,44,47,48,49,51,54},
            {0,1,4,6,7,8,11,12,13,16,18,19,20,23,24,25,28,30,31,32,35,36,37,40,42,43,44,47,48,49,52,54},
            {0,1,4,6,7,9,11,12,13,16,18,19,21,23,24,25,28,30,31,33,35,36,37,40,42,43,45,47,48,49,52,54},
            {0,1,4,5,7,8,11,12,13,16,17,19,20,23,24,25,28,29,31,32,35,36,37,40,41,43,44,47,48,49,52,53},
            {0,1,4,5,7,9,10,12,13,16,17,19,21,22,24,25,28,29,31,33,35,36,37,40,41,43,45,47,48,49,52,53},
            {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31} }
  
  --names = {"ionian","aeolian", "dorian", "phrygian", "lydian", "mixolydian", "major_pent", "minor_pent", "shang", "jiao", "zhi", "todi", "purvi", "marva", "bhairav", "ahirbhairav", "chromatic"}

  params:set("wsyn_ar_mode", 2)

  clock.run(pulse)

end

-- this section is all hardware stuff

-- hardware: key interaction
function key(n,z)
  if n == 1 and z == 1 then
    screen_focus = screen_focus + 1
  end
  -----
if screen_focus % 2 == 1 then
  if n == 2 and z == 1 then
    KEY2 = true
    bang()
    redraw()
    if preset_count < 8 and edit ~= "presets" then
      preset_count = preset_count + 1
      new_preset_pack(preset_count)
      selected_preset = 1
      grid_dirty = true
    elseif preset_count <= 8 and edit == "presets" then
      new_preset_unpack(selected_preset)
    end
  elseif n == 2 and z == 0 then
    KEY2 = false
    bang()
    redraw()
  end
  if n == 3 and z == 1 then
    KEY3 = true
    if KEY2 == false then
      if edit ~= "presets" then
        randomize_some()
      else
        randomize_all()
      end
    else
      if preset_count == 1 then
        if edit == "presets" then
          edit = "lc_bits"
          dd = 6
        end
      end
      preset_remove(selected_preset)
      for i=1,8 do
        g:led(i,8,0)
      end
      grid_dirty = true
    end
  elseif n == 3 and z == 0 then
    KEY3 = false
    bang()
    redraw()
  end
elseif screen_focus % 2 == 0 then
-- PUT OTHER SCRIPT HARDWARE CONTROLS HERE
refrain.key(n,z)
end
end

-- hardware: encoder interaction
function enc(n,d)
if screen_focus % 2 == 1 then
  if n == 1 then
    if preset_count > 0 then
      dd = util.clamp(dd+d,1,8)
      edit = edit_foci[dd]
    else
      dd = util.clamp(dd+d,1,7)
      edit = edit_foci[dd]
    end
  end
  if KEY3 == false and KEY2 == false then
    if n == 2 then
      if edit == "presets" then
        selected_preset = util.clamp(selected_preset+d,1,preset_count)
      elseif edit == "rand_prob" then
        params:set("tran prob 1", math.min(100,(math.max(params:get("tran prob 1") + d,0))))
      elseif edit == "lc_gate_probs" then
        params:set("gate prob 1", math.min(100,(math.max(params:get("gate prob 1") + d,0))))
      elseif edit == "low/high" then
        new_low = math.min(32,(math.max(new_low + d,1)))
        for i=1,16 do
          g:led(i,4,0)
          g:led(i,5,0)
          if new_low < 17 then
            g:led(new_low,4,15)
          elseif new_low > 16 then
            g:led(new_low-16,5,15)
          end
          grid_dirty = true
        end
      elseif edit == "octaves" then
        voice[1].octave = math.min(3,(math.max(voice[1].octave + d,-3)))
        for i=10,16 do
          g:led(i,1,0)
          g:led(voice[1].octave+13,1,15)
          grid_dirty = true
        end
      elseif edit == "lc_bits" then
        voice[1].bit = math.min(8,(math.max(voice[1].bit - d,0)))
      elseif edit == "seed/rule" then
        new_seed = math.min(255,(math.max(new_seed + d,0)))
        seed = new_seed
        rule = new_rule
        bang()
      elseif edit == "clock" then
        sel_ppqn_div = util.clamp(sel_ppqn_div + d, 1, #ppqn_divisions)
        redraw()
      end
    elseif n == 3 then
      if edit == "lc_gate_probs" then
        params:set("gate prob 2", math.min(100,(math.max(params:get("gate prob 2") + d,0))))
      elseif edit == "rand_prob" then
        params:set("tran prob 2", math.min(100,(math.max(params:get("tran prob 2") + d,0))))
      elseif edit == "low/high" then
        new_high = math.min(32,(math.max(new_high + d,1)))
        for i=1,16 do
          g:led(i,6,0)
          g:led(i,7,0)
          if new_high < 17 then
            g:led(new_high,6,15)
          elseif new_high > 16 then
            g:led(new_high-16,7,15)
          end
          grid_dirty = true --new
        end
      elseif edit == "octaves" then
        voice[2].octave = math.min(3,(math.max(voice[2].octave + d,-3)))
        for i=10,16 do
          g:led(i,2,0)
          g:led(voice[2].octave+13,2,15)
          grid_dirty = true --new
        end
      elseif edit == "lc_bits" then
        voice[2].bit = math.min(8,(math.max(voice[2].bit - d,0)))
      elseif edit == "seed/rule" then
        new_rule = math.min(255,(math.max(new_rule + d,0)))
        rule = new_rule
        seed = new_seed
        bang()
      end
    end
  end
  redraw()
elseif screen_focus % 2 == 0 then
  --PUT OTHER SCRIPT ENC CONTROLS HERE
  refrain.enc(n,d)
end
end

-- hardware: screen redraw
function redraw()
  if screen_focus%2 == 1 then
    screen.font_face(1)
    screen.font_size(8)
    screen.clear()
    screen.level(15)
    screen.move(0,10)
    screen.level(edit == "seed/rule" and 15 or 2)
    screen.text("seed: "..new_seed.." // rule: "..new_rule)
    screen.move(0,20)
    screen.level(edit == "lc_gate_probs" and 15 or 2)
    screen.text("gate prob 1: "..params:get("gate prob 1").."% // 2: "..params:get("gate prob 2").."%")
    screen.move(0,30)
    screen.level(edit == "low/high" and 15 or 2)
    screen.text("low: "..new_low.." // high: "..new_high)
    screen.move(0,40)
    screen.level(edit == "rand_prob" and 15 or 2)
    screen.text("tran prob 1: "..params:get("tran prob 1").."% // 2: "..params:get("tran prob 2").."%")
    screen.move(0,50)
    screen.level(edit == "octaves" and 15 or 2)
    screen.text("vox 1 oct: "..voice[1].octave)
    screen.move(57,50)
    screen.level(edit == "octaves" and 15 or 2)
    screen.text("// vox 2 oct: "..voice[2].octave)
    --ADDED: screen info for clock divider
    screen.move(53,62)
    screen.level(edit == "clock" and 15 or 2)
    screen.text(ppqn_names[sel_ppqn_div])
    screen.move(0,62)
    screen.level(edit == "lc_bits" and 15 or 2)
    for i = 1,8 do
      screen.text(seed_as_binary[9-i])
      screen.move((5*i),62)
    end
    screen.font_size(10)
    screen.move(40-(5*voice[1].bit),59)
    screen.text("-")
    screen.move(40-(5*voice[2].bit),67)
    screen.text("-")
    screen.font_size(8)
    screen.level(15)
    screen.move(30,60)
    for i = 1,8 do
      screen.move(80+(i*5),62)
      if edit == "presets" then
        screen.level(selected_preset == i and 15 or 2)
      else
        screen.level(2)
      end
      if preset_count < (i) then
        screen.text("_")
      else
        screen.text("*")
      end
    end
    screen.update()
  elseif screen_focus%2==0 then
    -- PUT OTHER SCREEN REDRAW HERE
    refrain.redraw()
  end
end

-- hardware: grid connect

g = grid.connect()

-- hardware: grid event (eg 'what happens when a button is pressed')

g.key = function(x,y,z)

  -- ADDED: first steps to alter clock divider for nice interaction
  if y == 8 and x > 8 and x < 14 then
    if y == 8 and x == 11 and z == 1 then
      sel_ppqn_div = math.floor(#ppqn_divisions / 2)
    end

    if y == 8 and x == 10 and z == 1then
      sel_ppqn_div = util.clamp(sel_ppqn_div - 1, 1, #ppqn_divisions) 
    end

    if y == 8 and x == 9 and z == 1then
      sel_ppqn_div = util.clamp(sel_ppqn_div - 2, 1, #ppqn_divisions)
    end

    if y == 8 and x == 12 and z == 1then
      sel_ppqn_div = util.clamp(sel_ppqn_div + 1, 1, #ppqn_divisions)
    end

    if y == 8 and x == 13 and z == 1then
      sel_ppqn_div = util.clamp(sel_ppqn_div + 2, 1, #ppqn_divisions)
    end
    grid_dirty = true
    redraw()
  end
  
  if y == 1 and x <= 9 then -- ADDED: <= makes button 9 mute the track
    g:led(x,y,z*15)
    voice[1].bit = 9-x
    redraw()
    grid_dirty = true
  end
  if y == 1 and x > 9 and z == 1 then
    for i=10,16 do
      g:led(i,1,0)
    end
    g:led(x,y,z*15)
    voice[1].octave = x-13
    redraw()
    grid_dirty = true
  end
  if y == 2 and x <= 9 then -- ADDED: <= makes button 9 mute the track
    g:led(x,y,z*15)
    voice[2].bit = 9-x
    redraw()
    grid_dirty = true
  end
  if y == 2 and x > 9 and z == 1 then
    for i=10,16 do
      g:led(i,2,0)
    end
    g:led(x,y,z*15)
    voice[2].octave = x-13
    redraw()
    grid_dirty = true
  end
  if y == 4 and z == 1 then
    g:led(x,y,z*15)
    new_low = x
    redraw()
    grid_dirty = true --new
  end
  if y == 5 and z == 1 then
    g:led(x,y,z*15)
    new_low = x+16
    redraw()
    grid_dirty = true
  end
  if y == 6 and z == 1 then
    g:led(x,y,z*15)
    new_high = x
    redraw()
    grid_dirty = true
  end
  if y == 7 and z == 1 then
    g:led(x,y,z*15)
    new_high = x+16
    redraw()
    grid_dirty = true
  end
  if y == 3 and z == 1 then
    if x == 1 then
      seed = math.random(0,255)
      new_seed = seed
    elseif x == 2 then
      rule = math.random(0,255)
      new_rule = rule
    elseif x == 4 then
      voice[1].bit = math.random(0,8)
    elseif x == 5 then
      voice[2].bit = math.random(0,8)
    elseif x == 7 or x == 8 or x == 10 or x == 11 then
      if x == 7 then
        new_low = math.random(1,32)
      end
      if x == 8 then
        new_high = math.random(1,32)
      end
      if x == 10 then
        voice[1].octave = math.random(-2,2)
      end
      if x == 11 then
        voice[2].octave = math.random(-2,2)
      end
    elseif x == 10 then
      voice[1].octave = math.random(-2,2)
    elseif x == 11 then
      voice[2].octave = math.random(-2,2)
    elseif x == 13 then
      if sel_ppqn_div ~= 1 then
        sel_ppqn_div = sel_ppqn_div - math.random(1, sel_ppqn_div - 1)
      end
    elseif x == 14 then
      sel_ppqn_div = math.random(sel_ppqn_div, #ppqn_divisions)
    elseif x == 16 then
      randomize_all()
    end
    bang()
    redraw()
    grid_dirty = true
  end
  if y == 8 and z == 1 then
    if x < 9 and x < preset_count+1 then
      new_preset_unpack(x)
      selected_preset = x
      grid_dirty = true
    elseif x == 14 and preset_count > 0 then
      preset_remove(selected_preset)
      grid_dirty = true
    elseif x == 15 then
      preset_count = 0
      for i=1,8 do
        g:led(i,8,0)
      end
      selected_preset = 0
      grid_dirty = true
    elseif x == 16 then
      if preset_count < 8 then
      preset_count = preset_count + 1
      new_preset_pack(preset_count)
      grid_dirty = true
      end
    end
  end
end

-- hardware: grid redraw

function grid_redraw_clock()
  while true do
    clock.sleep(1/30)
    if grid_dirty then
      grid_redraw()
      grid_dirty = false
    end
  end
end

function grid_redraw()
  g:all(0)
  for i=1,8 do
    g:led(i,1,0)
    g:led(i,2,0)
  end
  if seed_as_binary[voice[1].bit] == 1 then
    g:led(9-voice[1].bit,1,15)
  end
  if seed_as_binary[voice[2].bit] == 1 then
    g:led(9-voice[2].bit,2,15)
  end
  g:led(1,3,4)
  g:led(2,3,4)
  g:led(4,3,4)
  g:led(5,3,4)
  g:led(7,3,4)
  g:led(8,3,4)
  g:led(10,3,4)
  g:led(11,3,4)
  g:led(13,3,4)
  g:led(14,3,4)
  g:led(16,3,4)
  for i=1,preset_count do
    g:led(i,8,6)
  end
  g:led(selected_preset,8,15)
  g:led(14,8,2)
  g:led(15,8,4)
  g:led(16,8,6)
  g:led(voice[1].octave+13,1,15)
  g:led(voice[2].octave+13,2,15)
  if new_low < 17 then
    g:led(new_low,4,15)
  elseif new_low > 16 then
    g:led(new_low-16,5,15)
  end
  if new_high < 17 then
    g:led(new_high,6,15)
  elseif new_high > 16 then
    g:led(new_high-16,7,15)
  end
  
  -- ADDED: redraw the led for clockdiv = 1/4
  for i=9, 13 do
    g:led(i, 8, 4)
  end
  g:led(8 + 3, 8, 15) --g:led(8 + new_sel_clockdiv, 8, 15)
  g:refresh()
  grid_dirty = true
end

-- this section is all performative stuff

-- randomize all maths paramaters (does not affect scale or engine, for ease of use)
function randomize_all()
  grid_dirty = true
  seed = math.random(0,255)
  new_seed = seed
  rule = math.random(0,255)
  new_rule = rule
  voice[1].bit = math.random(0,8)
  voice[2].bit = math.random(0,8)
  new_low = math.random(1,32)
  new_high = math.random(1,32)
  voice[1].octave = math.random(-2,2)
  voice[2].octave = math.random(-2,2)
  bang()
  redraw()
  grid_dirty = true
end

function randomize_some()
  if edit == "seed/rule" then
    seed = math.random(0,255)
    new_seed = seed
    rule = math.random(0,255)
    new_rule = rule
  elseif edit == "lc_gate_probs" then
    for i = 1,2 do
      params:set("gate prob "..i, math.random(0,100))
    end
  elseif edit == "low/high" then
    new_low = math.random(1,32)
    new_high = math.random(1,32)
  elseif edit == "rand_prob" then
    for i = 1,2 do
      params:set("tran prob "..i, math.random(0,100))
    end
  elseif edit == "octaves" then
    voice[1].octave = math.random(-2,2)
    voice[2].octave = math.random(-2,2)
  elseif edit == "lc_bits" then
    voice[1].bit = math.random(0,8)
    voice[2].bit = math.random(0,8)
  elseif edit == "clock" then
    sel_ppqn_div = math.random(1, #ppqn_divisions)
  elseif edit == "presets" then
    randomize_all()
  end
  bang()
  redraw()
  grid_dirty = true
end

-- pack all maths parameters into a volatile preset

function new_preset_pack(set)
  new_preset_pool[set].seed = new_seed
  new_preset_pool[set].rule = new_rule
  new_preset_pool[set].v1_bit = voice[1].bit
  new_preset_pool[set].v2_bit = voice[2].bit
  new_preset_pool[set].new_low = new_low
  new_preset_pool[set].new_high = new_high
  new_preset_pool[set].v1_octave = voice[1].octave
  new_preset_pool[set].v2_octave = voice[2].octave
  new_preset_pool[set].sel_ppqn_div = sel_ppqn_div
end

function new_preset_unpack(set)
  new_seed = new_preset_pool[set].seed
  seed = new_seed
  new_rule = new_preset_pool[set].rule
  rule = new_rule
  voice[1].bit = new_preset_pool[set].v1_bit
  voice[2].bit = new_preset_pool[set].v2_bit
  new_low = new_preset_pool[set].new_low
  new_high = new_preset_pool[set].new_high
  voice[1].octave = new_preset_pool[set].v1_octave
  voice[2].octave = new_preset_pool[set].v2_octave
  sel_ppqn_div = new_preset_pool[set].sel_ppqn_div
  bang()
  redraw()
  grid_dirty = true
end

function preset_remove(set)
  for i = set,8 do
    new_preset_pool[i].seed = new_preset_pool[i+1].seed
    new_preset_pool[i].rule = new_preset_pool[i+1].rule
    new_preset_pool[i].v1_bit = new_preset_pool[i+1].v1_bit
    new_preset_pool[i].v2_bit = new_preset_pool[i+1].v2_bit
    new_preset_pool[i].new_low = new_preset_pool[i+1].new_low
    new_preset_pool[i].new_high = new_preset_pool[i+1].new_high
    new_preset_pool[i].v1_octave = new_preset_pool[i+1].v1_octave
    new_preset_pool[i].v2_octave = new_preset_pool[i+1].v2_octave
    new_preset_pool[i].sel_ppqn_div = new_preset_pool[i+1].sel_ppqn_div
  end
  if selected_preset > 1 and selected_preset < preset_count then
    selected_preset = selected_preset
  elseif selected_preset == preset_count then
    selected_preset = selected_preset - 1
  end
  preset_count = preset_count - 1
  redraw()
end

-- save snapshots as presets
-- cannibalized from @justmat
-- FIX SAVE params for w/syn and engine?

function savestate() --CHANGE PATH BELOW BEFORE RELEASE!
  local file = io.open(_path.data .. "less_concepts-dev/less_concepts-pattern"..selected_set..".data", "w+")
  io.output(file)
  io.write("permanence".."\n")
  io.write(preset_count.."\n")
  for i = 1,preset_count do
    io.write(new_preset_pool[i].seed .. "\n")
    io.write(new_preset_pool[i].rule .. "\n")
    io.write(new_preset_pool[i].v1_bit .. "\n")
    io.write(new_preset_pool[i].v2_bit .. "\n")
    io.write(new_preset_pool[i].new_low .. "\n")
    io.write(new_preset_pool[i].new_high .. "\n")
    io.write(new_preset_pool[i].v1_octave .. "\n")
    io.write(new_preset_pool[i].v2_octave .. "\n")
    io.write(new_preset_pool[i].sel_ppqn_div .. "\n")
  end
  io.write(params:get("clock_tempo") .. "\n")
  io.write(params:get("clock_midi_out") .. "\n")
  io.write(params:get("midi ch vox 1") .. "\n")
  io.write(params:get("midi ch vox 2") .. "\n")
  io.write(params:get("scale") .. "\n")
  io.write(params:get("global transpose") .. "\n")
  for i=1,2 do
    io.write(params:get("transpose "..i) .. "\n")
    io.write(params:get("tran prob "..i) .. "\n")
  end
  io.close(file)
end

function loadstate() --CHANGE PATH BELOW BEFORE RELEASE!
  local file = io.open(_path.data .. "less_concepts-dev/less_concepts-pattern"..selected_set..".data", "r")
  if file then
    io.input(file)
    if io.read() == "permanence" then
      preset_count = tonumber(io.read())
      if preset_count > 0 then
        selected_preset = 1
      end
      for i = 1,preset_count do
        new_preset_pool[i].seed = tonumber(io.read())
        new_preset_pool[i].rule = tonumber(io.read())
        new_preset_pool[i].v1_bit = tonumber(io.read())
        new_preset_pool[i].v2_bit = tonumber(io.read())
        new_preset_pool[i].new_low = tonumber(io.read())
        new_preset_pool[i].new_high = tonumber(io.read())
        new_preset_pool[i].v1_octave = tonumber(io.read())
        new_preset_pool[i].v2_octave = tonumber(io.read())
        new_preset_pool[i].sel_ppqn_div = tonumber(io.read())
      end
      load_bpm = tonumber(io.read())
      load_clock = tonumber(io.read())
      load_ch_1 = tonumber(io.read())
      load_ch_2 = tonumber(io.read())
      load_scale = tonumber(io.read())
      load_global_trans = tonumber(io.read())
      load_tran_1 = tonumber(io.read())
      load_tran_prob_1 = tonumber(io.read())
      load_tran_2 = tonumber(io.read())
      load_tran_prob_2 = tonumber(io.read())
      if load_bpm == nil and load_clock == nil and load_ch_1 == nil and
      load_ch_2 == nil and load_scale == nil and load_global_trans == nil then
        params:set("clock_tempo", 110)
        params:set("clock_midi_out", 1)
        params:set("midi ch vox 1", 1)
        params:set("midi ch vox 2", 1)
        params:set("scale", 1)
        params:set("global transpose", 0)
      else
        params:set("clock_tempo", load_bpm)
        params:set("clock_midi_out", load_clock)
        params:set("midi ch vox 1", load_ch_1)
        params:set("midi ch vox 2", load_ch_2)
        params:set("scale", load_scale)
        params:set("global transpose", load_global_trans)
        params:set("transpose 1", load_tran_1)
        params:set("transpose 2", load_tran_2)
        params:set("tran prob 1", load_tran_prob_1)
        params:set("tran prob 2", load_tran_prob_2)
      end
    else
      print("invalid data file")
    end
    io.close(file)
    grid_dirty = true
  end
end

function rerun()
  norns.script.load(norns.state.script)
end