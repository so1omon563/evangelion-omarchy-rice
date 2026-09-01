-- Keep only personal keybinding overrides here.

-- Preserve Omarchy's stock capture keys while adding NERV telemetry.
hl.unbind("PRINT")
hl.unbind("ALT + PRINT")
o.bind("PRINT", "Screenshot with NERV confirmation", "magi-capture screenshot")
o.bind("ALT + PRINT", "Screenrecording with NERV telemetry", "magi-capture recording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")

-- Use Right Ctrl as the dictation push-to-talk key instead of F9.
hl.unbind("F9")
hl.unbind("code:105")
hl.unbind("CTRL + Control_R")
o.bind("code:105", "Start dictation (push-to-talk)", "voxtype record start")
o.bind("CTRL + Control_R", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })

-- Assemble or dismiss the Tokyo-3 showcase on workspace 05.
o.bind("SUPER + SHIFT + F12", "Toggle MAGI presentation", "magi-presentation")

-- Engage or release the distraction-free AT Field focus envelope.
o.bind("SUPER + ALT + A", "Toggle AT Field focus mode", "magi-focus toggle")
o.bind("SUPER + ALT + V", "Inspect NERV privacy activity", "omarchy-shell magi-privacy toggle")
o.bind("SUPER + ALT + T", "Open MAGI mission timer", "omarchy-shell magi-mission toggle")
o.bind("SUPER + ALT + H", "Open NERV system health", "omarchy-shell magi-health toggle")
o.bind("SUPER + ALT + C", "Open MAGI world clock", "omarchy-shell magi-clock toggle")
o.bind("SUPER + ALT + G", "Open MAGI context inspector", "omarchy-shell magi-context-inspector toggle")
o.bind("SUPER + ALT + F", "Toggle MAGI developer performance overlay", "magi-performance toggle")

-- Open the unified MAGI command interface. SUPER + SPACE remains Omarchy's
-- standard root menu, so both launch paths stay available.
o.bind("SUPER + M", "MAGI command interface", "omarchy-menu toggle magi")

-- Recovery remains CLI/TTY-first; this chord is the convenient live path.
o.bind("SUPER + ALT + R", "Toggle static MAGI recovery", "magi-recovery toggle")

-- Preserve Omarchy's system/power menu keys while adding a restrained cue.
hl.unbind("SUPER + ESCAPE")
hl.unbind("XF86PowerOff")
o.bind("SUPER + ESCAPE", "NERV session control", "setsid -f magi-sound power; omarchy-menu toggle system")
o.bind("XF86PowerOff", "NERV session control", "setsid -f magi-sound power; omarchy-menu toggle system", { locked = true })

-- Secondary media controls; the laptop's standard XF86 media keys remain
-- available through Omarchy's built-in bindings.
o.bind("SUPER + ALT + P", "Media play/pause", "magi-media play-pause", { locked = true })
o.bind("SUPER + ALT + N", "Media next track", "magi-media next", { locked = true })
o.bind("SUPER + ALT + B", "Media previous track", "magi-media previous", { locked = true })
o.bind("SUPER + ALT + X", "Media stop", "magi-media stop", { locked = true })

-- Assemble or recover the deterministic EVA development mission on workspace 04.
o.bind("SUPER + ALT + D", "Toggle EVA deployment workspace", "magi-deployment toggle")

-- This simulation is manual-only; the same chord is always the safe exit.
o.bind("SUPER + ALT + I", "Toggle Angel intrusion simulation", "magi-intrusion toggle")

-- Inspect recent downloads through the classified intake before opening them.
o.bind("SUPER + ALT + L", "NERV classified downloads", "omarchy-launch-terminal -- magi-downloads open")
