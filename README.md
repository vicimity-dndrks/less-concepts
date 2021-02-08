
# less concepts 3.0
1. uninstall old less concepts
2. install with ```;install https://github.com/linusschrab/less_concepts``` (post norns 210114)

![enter image description here](https://github.com/linusschrab/less_concepts/blob/master/img/less_concepts_grid.png?raw=true)

*less concepts is rooted in the idea that complexity is just a shit-ton of simplicity, chained together. at its core, less concepts holds 65,536 possible combinations of notes which can be gated, offset, and manipulated to create minimal sequences for improvisation. small changes to a single parameter can bring sweeping or subtle changes.*

*seek. think. discover.*

**less concepts 3.0**

![enter image description here](https://github.com/linusschrab/less_concepts/blob/master/img/1.png?raw=true)

at first you are met by a constructive concept built from the seed 36 and rule 30. root note is C and the scale is major. the sequence is fed through the built in sound engine "passersby" and midi device 1 / channel 1.

- the combination of seeds and rules feed the sequencer with 8-bit numbers. this number is visualized by the eight squares top left on the screen / grid, a new number is seeded with every beat of the selected time signature. the two voices are individually triggered when they cross paths with the true value 1. the current 8-bit number translates into a note by passing it through the limits for high / low and then transposed within the selected scale.

- navigate the main performance screen by scrolling with E1, changing values with E2 and E3. adding snapshots with K2 and randomizing selected values with K3.

- K3 takes on a different role when snapshots are selected (bottom left) or cycling sequencer direction / duration (bottom right). while snapshots are selected K3 will randomize all values (except time and duration). while direction / duration is selected K3 activates a ´destructive´mode, indicated by '*'. all changes to snapshots will be saved while in destructive mode. if you wish to delete a snapshot hold K2 and press K3, this results in the snapshot still playing but no snapshot is selected. you scroll through and select the snapshots with E2.


NEWS

- time: change time signature for the sequencer. 1/4 - 1/32 (more options available in params).
- a cycling sequencer that steps through saved snapshots and move when the indicated duration has passed. the cycling sequencer can move up '>', down '<' or random '~'.

/ / / / / / / /

**\~ r e f r a i n**

![enter image description here](https://github.com/linusschrab/less_concepts/blob/master/img/2.png?raw=true)

hold K1 to find the built in pitch, delay, micro looper.

NEWS

- buffers are now visible (top right)
- input mix (engine and adc) is editable on screen (prev. in params / adc is new)
- K2 toggles state for both buffers 'rec | play'

/ / / / / / / /

**params -> edit**

![enter image description here](https://github.com/linusschrab/less_concepts/blob/master/img/3.png?raw=true)

'load & save' 
- all values including params are now saved with a set. old saves still work.

'time, midi & outputs'
- select time range('legacy 1/8 - 1/32', 'slow 1/1 - 1/16' and 'full 2/1 - 1/32' (locked with snapshots)
- default length (cycle) 1x - 32x (cycle duration for new snapshots)
- midi (choose midi device and channels) turn midi/link transport on / off
- outputs, choose outputs for voice 1 & 2.

'scaling & randomization'
- choose scale and global transpose
- set transpose randomization
- clamp the values for randomization with 'randomization limits'

\+ params for ~refrain, passersby and w/syn
