# MAGI sound policy

MAGI sound is opt-in and synthesized locally. The shipped policy is globally
disabled, every category starts disabled, and lock/login cues therefore remain
silent until the operator explicitly enables both the global channel and the
relevant category. Visual notifications and overlays continue regardless of
audio state.

The preserved `~/.config/omarchy/sound.json` policy provides `session`
(lock/unlock), `system` (power), `workflow` (completion), and `critical`
(alerts). Each has a 0–100% stream-volume ceiling. Quiet hours default to
22:00–07:00 and suppress every non-preview cue.

```bash
magi-sound status --json
magi-sound enable                    # global authority only
magi-sound category critical enable
magi-sound volume critical 20
magi-sound quiet-hours 22 7
magi-sound quiet-hours off
magi-sound preview critical          # explicit preview bypasses policy
magi-sound kill                      # immediate persistent global silence
```

Precedence is global kill switch → category/scene permission → quiet hours →
provider availability → cue rate limit. The active affinity scene can override a
category without changing its baseline preference:

```bash
magi-sound scene unit-02 workflow enabled
magi-sound scene unit-02 workflow inherit
```

Scene overrides never bypass the global switch or quiet hours. Missing PipeWire
support is silent and non-blocking. `preview` is the only policy-bypassing path;
it is always an explicit user action and still observes the category ceiling.
