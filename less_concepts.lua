-- less concepts:
-- cellular automata sequencer
-- v2.0.1 @dan_derks
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
-- (10,1) to (16,2): octaves
-- (1,3) to (16,3): randomize
-- (1,4) to (16,5): low
-- (1,6) to (16,7): high
-- (16,8): take snapshot
-- (15,8): clear all snapshots
-- (14,8): clear selected
-- (1,8) to (8,8): snapshots
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
screen_focus = 1
selected_preset = 0
local KEY2 = false
local KEY3 = false
local v1_bit = 0
local v2_bit = 0
local v1_octave = 0
local v2_octave = 0
local ch_1 = 1
local ch_2 = 1
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
  "presets"}
local edit = "seed/rule"
dd = 0
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
end
selected_set = 0

local beatclock = require 'beatclock'
local clk = beatclock.new()
clk_midi = midi.connect()
clk_midi.event = clk.process_midi

clk.on_select_external = function() clk:reset() end --from nattog

engine.name = "Passersby"
passersby = include "passersby/lib/passersby_engine"

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

local function notes_off_v1()
  for i=1,#active_notes_v1 do
    m:note_off(active_notes_v1[i],0,ch_1)
  end
  active_notes_v1 = {}
end

local function notes_off_v2()
  for i=1,#active_notes_v2 do
    m:note_off(active_notes_v2[i],0,ch_2)
  end
  active_notes_v2 = {}
end

-- if user-defined bit in the binary version of a seed equals 1, then note event [aka, bit-wise gating]
local function iterate()
  notes_off_v1()
  notes_off_v2()
  seed = next_seed
  bang()
  scale(new_low,new_high,seed)
  if seed_as_binary[v1_bit] == 1 then
    random_gate[1].comparator = math.random(0,100)
    if random_gate[1].comparator < random_gate[1].probability then
      random_note[1].comparator = math.random(0,100)
      if random_note[1].comparator < random_note[1].probability then
        random_note[1].add = random_note[1].tran
      else
        random_note[1].add = 0
      end
      engine.noteOn(1,midi_to_hz((notes[coll][scaled])+(48+(v1_octave * 12)+semi+random_note[1].add)),127)
      m:note_on((notes[coll][scaled])+(36+(v1_octave*12)+semi+random_note[1].add),127,ch_1)
      table.insert(active_notes_v1,(notes[coll][scaled])+(36+(v1_octave*12)+semi+random_note[1].add))
    end
  end
  if seed_as_binary[v2_bit] == 1 then
    random_gate[2].comparator = math.random(0,100)
    if random_gate[2].comparator < random_gate[2].probability then
      random_note[2].comparator = math.random(0,100)
      if random_note[2].comparator < random_note[2].probability then
        random_note[2].add = random_note[2].tran
      else
        random_note[2].add = 0
      end
      engine.noteOn(2,midi_to_hz((notes[coll][scaled])+(48+(v2_octave * 12)+semi+random_note[2].add)),127)
      m:note_on((notes[coll][scaled])+(36+(v2_octave*12)+semi+random_note[2].add),127,ch_2)
      table.insert(active_notes_v2,(notes[coll][scaled])+(36+(v2_octave*12)+semi+random_note[2].add))
    end
  end
  -- EVENTS FOR R E F R A I N
  if seed_as_binary[track[1].bit] == 1 then
    random_gate[3].comparator = math.random(0,100)
    if random_gate[3].comparator < random_gate[3].probability then
      refrain.reset(1,pass_to_refrain)
    end
  end
  if seed_as_binary[track[2].bit] == 1 then
    random_gate[4].comparator = math.random(0,100)
    if random_gate[4].comparator < random_gate[4].probability then
      refrain.reset(2,pass_to_refrain)
    end
  end
  redraw()
  grid_redraw()
end

-- convert midi note to hz for Passersby engine
function midi_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end

-- allow user to define the MIDI channel voice 1 sends on
local function midi_vox_1(channel)
  ch_1 = channel
end

-- allow user to define the MIDI channel voice 2 sends on
local function midi_vox_2(channel)
  ch_2 = channel
end

-- allow user to define the transposition of voice 1 and voice 2, simultaneous changes to MIDI and Passersby engine
local function transpose(semitone)
  semi = semitone
end

refrain = include "lib/refrain"

-- everything that happens when the script is first loaded
function init()
  math.randomseed(os.time())
  math.random(); math.random(); math.random()
  seed_to_binary()
  rule_to_binary()
  g = grid.connect()
  g:led(new_low,4,15)
  g:led(new_high,6,15)
  g:led(v1_octave+13,1,15)
  g:led(v2_octave+13,2,15)
  grid_redraw()
  g:refresh()
  params:add_number("set", "set", 1,100,1)
  params:set_action("set", function (x) selected_set = x end)
  params:add{type = "trigger", id = "load", name = "load", action = loadstate}
  params:add{type = "trigger", id = "save", name = "save", action = savestate}
  params:add_separator()
  m = midi.connect()
  --clk.on_step = function() iterate() refrain.iterate() end
  clk.on_step = function() iterate() end
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = function() print("external") end
  clk:add_clock_params()
  params:add_number("midi ch vox 1", "midi ch vox 1", 1,16,1)
  params:set_action("midi ch vox 1", function (x) midi_vox_1(x) end)
  params:add_number("midi ch vox 2", "midi ch vox 2", 1,16,1)
  params:set_action("midi ch vox 2", function (x) midi_vox_2(x) end)
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
  passersby.add_params()
  bang()

notes = { {0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48},
          {0,2,3,5,7,8,10,12,14,15,17,19,20,22,24,26,27,29,31,32,34,36,38,39,41,43,44,46,48},
          {0,2,3,5,7,9,10,12,14,15,17,19,21,22,24,26,27,29,31,33,34,36,38,39,41,43,45,46,48},
          {0,1,3,5,7,8,10,12,13,15,17,19,20,22,24,25,27,29,31,32,34,36,37,39,41,43,44,46,48},
          {0,2,4,6,7,9,11,12,14,16,18,19,21,23,24,26,28,30,31,33,35,36,38,40,42,43,45,47,48},
          {0,2,4,5,7,9,10,12,14,16,17,19,21,22,24,26,28,29,31,33,34,36,38,40,41,43,45,46,48},
          {0,3,5,7,10,12,15,17,19,22,24,27,29,31,34,36,39,41,43,46,48,51,53,55,58,60,63,65,67},
          {0,2,4,7,9,12,14,16,19,21,24,26,28,31,33,36,38,40,43,45,48,50,52,55,57,60,62,64,67},
          {0,2,5,7,10,12,14,17,19,22,24,26,29,31,34,36,38,41,43,46,48,50,53,55,58,60,62,65,67},
          {0,3,5,8,10,12,15,17,20,22,24,27,29,32,34,36,39,41,44,46,48,51,53,56,58,60,63,65,68},
          {0,2,5,7,9,12,14,17,19,21,24,26,29,31,33,36,38,41,43,45,48,50,53,55,57,60,62,65,67},
          {0,1,3,6,7,8,11,12,13,15,18,19,20,23,24,25,27,30,31,32,35,36,37,39,42,43,44,47,48},
          {0,1,4,6,7,8,11,12,13,16,18,19,20,23,24,25,28,30,31,32,35,36,37,40,42,43,44,47,48},
          {0,1,4,6,7,9,11,12,13,16,18,19,21,23,24,25,28,30,31,33,35,36,37,40,42,43,45,47,48},
          {0,1,4,5,7,8,11,12,13,16,17,19,20,23,24,25,28,29,31,32,35,36,37,40,41,43,44,47,48},
          {0,1,4,5,7,9,10,12,13,16,17,19,21,22,24,25,28,29,31,33,35,36,37,40,41,43,45,47,48},
          {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28} }

names = {"ionian","aeolian", "dorian", "phrygian", "lydian", "mixolydian", "major_pent", "minor_pent", "shang", "jiao", "zhi", "todi", "purvi", "marva", "bhairav", "ahirbhairav", "chromatic"}

clk:start()

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
      grid_redraw()
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
      grid_redraw()
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
      dd = util.clamp(dd+d,1,7)
      edit = edit_foci[dd]
    else
      dd = util.clamp(dd+d,1,6)
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
        new_low = math.min(29,(math.max(new_low + d,1)))
        for i=1,16 do
          g:led(i,4,0)
          g:led(i,5,0)
          if new_low < 17 then
            g:led(new_low,4,15)
          elseif new_low > 16 then
            g:led(new_low-16,5,15)
          end
          g:refresh()
        end
      elseif edit == "octaves" then
        v1_octave = math.min(3,(math.max(v1_octave + d,-3)))
        for i=10,16 do
          g:led(i,1,0)
          g:led(v1_octave+13,1,15)
          g:refresh()
        end
      elseif edit == "lc_bits" then
        v1_bit = math.min(8,(math.max(v1_bit - d,0)))
      elseif edit == "seed/rule" then
        new_seed = math.min(255,(math.max(new_seed + d,0)))
        seed = new_seed
        rule = new_rule
        bang()
      end
    elseif n == 3 then
      if edit == "lc_gate_probs" then
        params:set("gate prob 2", math.min(100,(math.max(params:get("gate prob 2") + d,0))))
      elseif edit == "rand_prob" then
        params:set("tran prob 2", math.min(100,(math.max(params:get("tran prob 2") + d,0))))
      elseif edit == "low/high" then
        new_high = math.min(29,(math.max(new_high + d,1)))
        for i=1,16 do
          g:led(i,6,0)
          g:led(i,7,0)
          if new_high < 17 then
            g:led(new_high,6,15)
          elseif new_high > 16 then
            g:led(new_high-16,7,15)
          end
          g:refresh()
        end
      elseif edit == "octaves" then
        v2_octave = math.min(3,(math.max(v2_octave + d,-3)))
        for i=10,16 do
          g:led(i,2,0)
          g:led(v2_octave+13,2,15)
          g:refresh()
        end
      elseif edit == "lc_bits" then
        v2_bit = math.min(8,(math.max(v2_bit - d,0)))
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
  --screen.clear()
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
  screen.text("vox 1 oct: "..v1_octave)
  screen.move(57,50)
  screen.level(edit == "octaves" and 15 or 2)
  screen.text("// vox 2 oct: "..v2_octave)
  screen.move(0,62)
  screen.level(edit == "lc_bits" and 15 or 2)
  for i = 1,8 do
    screen.text(seed_as_binary[9-i])
    screen.move((5*i),62)
  end
  screen.font_size(10)
  screen.move(40-(5*v1_bit),59)
  screen.text("-")
  screen.move(40-(5*v2_bit),67)
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
  if y == 1 and x < 9 then
    g:led(x,y,z*15)
    g:refresh()
    v1_bit = 9-x
    bang()
    redraw()
  end
  if y == 1 and x > 9 and z == 1 then
    for i=10,16 do
      g:led(i,1,0)
    end
    g:led(x,y,z*15)
    v1_octave = x-13
    redraw()
    g:refresh()
  end
  if y == 2 and x < 9 then
    g:led(x,y,z*15)
    g:refresh()
    v2_bit = 9-x
    bang()
    redraw()
  end
  if y == 2 and x > 9 and z == 1 then
    for i=10,16 do
      g:led(i,2,0)
    end
    g:led(x,y,z*15)
    v2_octave = x-13
    redraw()
    g:refresh()
  end
  if y == 4 and z == 1 then
    for i=1,16 do
      g:led(i,4,0)
      g:led(i,5,0)
    end
    g:led(x,y,z*15)
    new_low = x
    redraw()
    g:refresh()
  end
  if y == 5 and z == 1 then
    for i=1,16 do
      g:led(i,4,0)
      g:led(i,5,0)
    end
    g:led(x,y,z*15)
    new_low = x+16
    redraw()
    g:refresh()
  end
  if y == 6 and z == 1 then
    for i=1,16 do
      g:led(i,6,0)
      g:led(i,7,0)
    end
    g:led(x,y,z*15)
    new_high = x
    redraw()
    g:refresh()
  end
  if y == 7 and z == 1 then
    for i=1,16 do
      g:led(i,6,0)
      g:led(i,7,0)
    end
    g:led(x,y,z*15)
    new_high = x+16
    redraw()
    g:refresh()
  end
  if y == 3 and z == 1 then
    if x == 1 then
      seed = math.random(0,255)
      new_seed = seed
    elseif x == 2 then
      rule = math.random(0,255)
      new_rule = rule
    elseif x == 4 then
      v1_bit = math.random(0,8)
    elseif x == 5 then
      v2_bit = math.random(0,8)
    elseif x == 7 or x == 8 or x == 10 or x == 11 then
      if x == 7 then
        new_low = math.random(1,29)
      end
      if x == 8 then
        new_high = math.random(1,29)
      end
      if x == 10 then
        v1_octave = math.random(-2,2)
      end
      if x == 11 then
        v2_octave = math.random(-2,2)
      end
      g:all(0)
      g:led(v1_octave+13,1,15)
      g:led(v2_octave+13,2,15)
      if new_low < 17 then
        g:led(new_low,4,15)
      else
        g:led(new_low-16,5,15)
      end
      if new_high < 17 then
        g:led(new_high,6,15)
      else
        g:led(new_high-16,7,15)
      end
    elseif x == 10 then
      v1_octave = math.random(-2,2)
    elseif x == 11 then
      v2_octave = math.random(-2,2)
    elseif x == 16 then
      randomize_all()
    end
    bang()
    redraw()
    grid_redraw()
    g:refresh()
  end
  if y == 8 and z == 1 then
    if x < 9 and x < preset_count+1 then
      new_preset_unpack(x)
      selected_preset = x
      grid_redraw()
    elseif x == 14 and preset_count > 0 then
      preset_remove(selected_preset)
      grid_constant()
    elseif x == 15 then
      preset_count = 0
      for i=1,8 do
        g:led(i,8,0)
      end
      selected_preset = 0
      grid_redraw()
    elseif x == 16 then
      if preset_count < 8 then
      preset_count = preset_count + 1
      new_preset_pack(preset_count)
      grid_redraw()
      end
    end
  end
end

-- hardware: grid redraw
function grid_redraw()
  for i=1,8 do
    g:led(i,1,0)
    g:led(i,2,0)
  end
  if seed_as_binary[v1_bit] == 1 then
    g:led(9-v1_bit,1,15)
  end
  if seed_as_binary[v2_bit] == 1 then
    g:led(9-v2_bit,2,15)
  end
  g:led(1,3,4)
  g:led(2,3,4)
  g:led(4,3,4)
  g:led(5,3,4)
  g:led(7,3,4)
  g:led(8,3,4)
  g:led(10,3,4)
  g:led(11,3,4)
  g:led(16,3,4)
  for i=1,preset_count do
    g:led(i,8,6)
  end
  g:led(selected_preset,8,15)
  g:led(14,8,2)
  g:led(15,8,4)
  g:led(16,8,6)
  g:led(v1_octave+13,1,15)
  g:led(v2_octave+13,2,15)
  g:refresh()
end

function grid_constant()
  g:all(0)
  g:led(v1_octave+13,1,15)
  g:led(v2_octave+13,2,15)
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
  grid_redraw()
  g:refresh()
end

-- this section is all performative stuff

-- randomize all maths paramaters (does not affect scale or engine, for ease of use)
function randomize_all()
  seed = math.random(0,255)
  new_seed = seed
  rule = math.random(0,255)
  new_rule = rule
  v1_bit = math.random(0,8)
  v2_bit = math.random(0,8)
  new_low = math.random(1,29)
  new_high = math.random(1,29)
  v1_octave = math.random(-2,2)
  v2_octave = math.random(-2,2)
  bang()
  redraw()
  grid_constant()
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
    new_low = math.random(1,29)
    new_high = math.random(1,29)
  elseif edit == "rand_prob" then
    for i = 1,2 do
      params:set("tran prob "..i, math.random(0,100))
    end
  elseif edit == "octaves" then
    v1_octave = math.random(-2,2)
    v2_octave = math.random(-2,2)
  elseif edit == "lc_bits" then
    v1_bit = math.random(0,8)
    v2_bit = math.random(0,8)
  elseif edit == "presets" then
    randomize_all()
  end
  bang()
  redraw()
  grid_constant()
end

-- pack all maths parameters into a volatile preset

function new_preset_pack(set)
  new_preset_pool[set].seed = new_seed
  new_preset_pool[set].rule = new_rule
  new_preset_pool[set].v1_bit = v1_bit
  new_preset_pool[set].v2_bit = v2_bit
  new_preset_pool[set].new_low = new_low
  new_preset_pool[set].new_high = new_high
  new_preset_pool[set].v1_octave = v1_octave
  new_preset_pool[set].v2_octave = v2_octave
end

function new_preset_unpack(set)
  new_seed = new_preset_pool[set].seed
  seed = new_seed
  new_rule = new_preset_pool[set].rule
  rule = new_rule
  v1_bit = new_preset_pool[set].v1_bit
  v2_bit = new_preset_pool[set].v2_bit
  new_low = new_preset_pool[set].new_low
  new_high = new_preset_pool[set].new_high
  v1_octave = new_preset_pool[set].v1_octave
  v2_octave = new_preset_pool[set].v2_octave
  bang()
  redraw()
  grid_constant()
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

function savestate()
  local file = io.open(_path.data .. "less_concepts/less_concepts-pattern"..selected_set..".data", "w+")
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
  end
  io.close(file)
end

function loadstate()
  local file = io.open(_path.data .. "less_concepts/less_concepts-pattern"..selected_set..".data", "r")
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
      end
    else
      print("invalid data file")
    end
    io.close(file)
  end
end
