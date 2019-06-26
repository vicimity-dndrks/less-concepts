local refrain = {}

math.randomseed(os.time())      -- Seeds the pseudo-random number generator

function refrain.init()
  print("r e f r a i n")
  track = {}
  state = {"rec", "rec"}
  refrain.scaled = {"none","panning", "rate", "pan+rate", "feedback"}
  note_to_param = 0
  speedlist = {-2.0, -1.0, -0.5, -0.25, -0.125, 0.125, 0.25, 0.5, 1.0, 2.0}
  refrain.edit_foci = {
  "ref_feedback",
  "ref_offset",
  "ref_rate",
  "ref_pan",
  "ref_bits",
  "ref_rec",
  "ref_presets"}
  refrain.edit = "ref_feedback"
  refrain.dd = 0
  
  params:add_separator()
  params:add_control("engine_input", "engine -> ~ r e f r a i n", controlspec.new(0, 3, "lin", 0, 0, ""))
  params:set_action("engine_input", function(x) audio.level_eng_cut(x) end)
--[[  params:add_control("rec_level", "rec level", controlspec.new(0, 1, "lin", 0, 1, ""))
  params:set_action("rec_level", function(x) softcut.rec_level(1, x) end)]]--
  params:add_option("note -> param", "note -> param", refrain.scaled, 1)
  params:set_action("note -> param", function(x) note_to_param = refrain.scaled[x] end)
  params:add_separator()
  
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_eng_cut(0)
  softcut.pan(1, 0.7)
  softcut.pan(2, 0.3)
  
  for i = 1, 2 do
    track[i] = {}
    track[i].start_point = 1
    track[i].end_point = 9
    track[i].rate = 9
    track[i].bit = 1
    track[i].offset = 0
    track[i].pan = 0.5
    audio.level_eng_cut(1)
    softcut.level_input_cut(1, i, 1.0)
    softcut.level_input_cut(2, i, 1.0)
    softcut.buffer(1,1)
    softcut.buffer(2,2)

    softcut.play(i, 1)
    softcut.rate(i, 1)
    softcut.loop_start(i, 1)
    softcut.loop_end(i, 9)
    softcut.loop(i, 1)
    softcut.fade_time(i, 0.2) --or 0.8 idk?
    softcut.rec(i, 1)
    softcut.rec_level(i, 1)
    softcut.position(i, 1)
    softcut.rec_offset(i, -0.0003)
    softcut.enable(i, 1)
    softcut.filter_dry(i, 0.125)
	  softcut.filter_fc(i, 1200)
	  softcut.filter_lp(i, 0)
	  softcut.filter_bp(i, 1.0)
	  softcut.filter_rq(i, 2.0)
  end
  
  --[[params:add_control("voice_2_buffer","voice 2 buffer reference",controlspec.new(1,2,'lin',1,2,''))
  params:set_action("voice_2_buffer", function(x) softcut.buffer(2,x) end)]]--
  
  for i = 1,2 do
    params:add_control(i .. "feedback", i .. " feedback", controlspec.new(0, 1, "lin", 0, .2, ""))
    params:set_action(i .. "feedback", function(x)
      if state[i] == "rec" then
        softcut.pre_level(i, x)
      end
    end)
    params:add_control(i .. "gate prob ~refrain", i .. " gate prob ~refrain", controlspec.new(0,100,'lin',1,100,'%'))
    params:set_action(i .. "gate prob ~refrain", function(x) random_gate[i+2].probability = x end)
    params:add_control(i .. "filter_fc", i .. " filter cutoff", controlspec.new(10, 1200, "exp", 1, 1200, "hz"))
    params:set_action(i .. "filter_fc", function(x) softcut.filter_fc(i, x) end)
    params:add_control(i .. "speed_slew", i .. " speed slew", controlspec.new(0, 1, "lin", 0, 0.0, ""))
    params:set_action(i .. "speed_slew", function(x) softcut.rate_slew_time(i, x) end)
    params:add_control(i .. "volume", i .. " volume", controlspec.new(0,3,"lin",0,1,""))
    params:set_action(i .. "volume", function(x) softcut.level(i,x)end)
  end
  
  params:add_separator()
  
  track[1].pan = 0.7
  track[2].pan = 0.3

end

function refrain.reset(voice,passed)
  -- follow this format: math.floor(((((passed-1) / (256-1)) * (HI - LO) + LO)))
  if speedlist[track[voice].rate] < 0 then
    softcut.position(voice,1.5 + track[voice].offset)
  else
    softcut.position(voice,1+track[voice].offset)
  end
  if note_to_param == "panning" then
    if voice == 1 then
      track[voice].pan = math.floor(((((passed-1) / (256-1)) * (100 - 0) + 0)))/100
    else
      track[voice].pan = 1-(math.floor(((((passed-1) / (256-1)) * (100 - 0) + 0)))/100)
    end
    softcut.pan(voice,track[voice].pan)
  elseif note_to_param == "rate" then
    track[voice].rate = math.floor(((((passed-1) / (256-1)) * (#speedlist - 1) + 1)))
    softcut.rate(voice,speedlist[track[voice].rate])
  elseif note_to_param == "pan+rate" then
    track[voice].rate = math.floor(((((passed-1) / (256-1)) * (#speedlist - 1) + 1)))
    softcut.rate(voice,speedlist[track[voice].rate])
      if voice == 1 then
        track[voice].pan = math.floor(((((passed-1) / (256-1)) * (100 - 0) + 0)))/100
      else
        track[voice].pan = 1-(math.floor(((((passed-1) / (256-1)) * (100 - 0) + 0)))/100)
      end
    softcut.pan(voice,track[voice].pan)
  elseif note_to_param == "feedback" then
    params:set(voice.."feedback", math.floor(((((passed-1) / (256-1)) * (100 - 10) + 10)))/100)
  end
end

function refrain.redraw()
  screen.clear()
  screen.move(0,8)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(2)
  screen.text("~ r e f r a i n")
  
  screen.move(0,20)
  screen.level(refrain.edit=="ref_feedback" and 15 or 2)
  screen.text("fb1: "..params:string("1feedback").." // fb2: "..params:string("2feedback"))
  screen.move(0,30)
  screen.level(refrain.edit=="ref_offset" and 15 or 2)
  screen.text("off1: "..track[1].offset.." sec // off2: "..track[2].offset.." sec")
  screen.move(0,40)
  screen.level(refrain.edit=="ref_rate" and 15 or 2)
  screen.text("rate1: "..speedlist[track[1].rate].." // rate2: "..speedlist[track[2].rate])
  screen.move(0,50)
  screen.level(refrain.edit=="ref_pan" and 15 or 2)
  screen.text("pan1: "..track[1].pan.." // pan2: "..track[2].pan)
	screen.move(0,62)
	screen.level(refrain.edit=="ref_bits" and 15 or 2)
	for i = 1,8 do
    screen.text(seed_as_binary[9-i])
    screen.move((5*i),62)
  end
  screen.font_size(10)
  screen.move(40 - (5*track[1].bit),59)
  screen.text("-")
  screen.move(40 - (5*track[2].bit),67)
  screen.text("-")
  screen.font_size(8)
  screen.move(85,62)
  screen.level(refrain.edit=="ref_rec" and 15 or 2)
	screen.text(state[1].." | "..state[2])
	screen.update()
end

function refrain.rec(i)
  softcut.rec_level(i,1)
  softcut.pre_level(i,params:get(i.."feedback"))
  state[i] = "rec"
end

function refrain.play(i)
  softcut.rec_level(i,0)
  softcut.pre_level(i,1)
  state[i] = "play"
end

function refrain.key(n,z)
  if refrain.edit == "ref_rec" then
    local i=n-1
    if n>1 and z==1 and state[i]~="rec" then
      refrain.rec(i)
    elseif n>1 and z==1 and state[i]=="rec" then
      refrain.play(i)
    end
    refrain.redraw()
  else
    if n == 3 and z == 1 then
      refrain.randomize()
    end
  end
end

function refrain.enc(n,d)
  if n == 1 then
    refrain.dd = util.clamp(refrain.dd+d,1,6)
    refrain.edit = refrain.edit_foci[refrain.dd]
    --refrain.edit = util.clamp(refrain.edit+d,1,5)
  end
  if n == 2 or n == 3 then
    if refrain.edit == "ref_feedback" then
      params:set((n-1).."feedback", util.clamp(params:get((n-1).."feedback")+d/100,0,1))
    elseif refrain.edit == "ref_offset" then
      track[n-1].offset = util.clamp(track[n-1].offset+d/10,0,8)
    elseif refrain.edit == "ref_rate" then
      track[n-1].rate = util.clamp(track[n-1].rate+d,1,#speedlist)
      softcut.rate(n-1,speedlist[track[n-1].rate])
    elseif refrain.edit == "ref_bits" then
      track[n-1].bit = util.clamp(track[n-1].bit-d,0,8)
    elseif refrain.edit == "ref_pan" then
      track[n-1].pan = util.clamp(track[n-1].pan-d/10,0,1)
      softcut.pan(n-1, track[n-1].pan)
    end
  end
  refrain.redraw()
end

function refrain.randomize()
  if refrain.edit == "ref_feedback" then
    for i = 1,2 do
      params:set(i.."feedback", math.random(0,100)/100)
    end
  elseif refrain.edit == "ref_offset" then
    for i = 1,2 do
      track[i].offset = math.random(0,80)/10
    end
  elseif refrain.edit == "ref_rate" then
    for i = 1,2 do
      track[i].rate = math.random(1,#speedlist)
      softcut.rate(i,speedlist[track[i].rate])
    end
  elseif refrain.edit == "ref_pan" then
    for i = 1,2 do
      track[i].pan = math.random(0,10)/10
      softcut.pan(i, track[i].pan)
    end
  elseif refrain.edit == "ref_bits" then
    for i = 1,2 do
      track[i].bit = math.random(1,8)
    end
  end
end

return refrain