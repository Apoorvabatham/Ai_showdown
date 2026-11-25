AI Showdown  -  v0.10.3  (macOS)
==================================

Parody. Not affiliated with or endorsed by any real person or company.

A one-on-one 3D parody fighting game where tech founders, AI researchers,
leaders and AGI itself settle their differences in best-of-three bouts across
four stages. One-button Power specials, cinematic Supers, and no motion
inputs required.


HOW TO RUN
----------
1. Open the zip in Finder (if macOS didn't already extract it).
2. Drag AIShowdown.app into Applications, or double-click it right here.

Note: If macOS says the app cannot be opened or is from an unidentified
developer, Control-click AIShowdown.app -> Open -> Open (only needed once),
or allow it in System Settings -> Privacy & Security.

Includes an offline Player's Manual (manual.html).


FIGHTERS (11)
-------------
- Ram Altman       (Super: Scaling Law)
- tesla man        (Super: Rocket Launch)
- Dario Amoday     (Super: Constitutional Shield)
- Mark Zuckerbot   (Super: Metaverse Trap)
- Jensen Wong      (Super: Leather Jacket Tornado)
- Yann LeCant      (Super: It's Just Autocomplete)
- Geoff Hintoff    (Super: I Regret Nothing... Wait)
- Sundar Pickai    (Super: 404 Not Found)
- Donald Tarrif    (Super: Shower of Tariffs)
- Xi Winping       (Super: Open-Source Squad)
- AGI              (Final Boss; Super: Engagement Loop)


STAGES (4)
----------
- Server Farm
- Mensa
- Senate Hearing Room
- GPU Foundry


MODES
-----
- Story             - Fighter campaign with dialogue, rival bout and AGI boss
- Vs CPU            - Best-of-3 match against the AI on a chosen stage
- 1v1 Quick Match   - One round against a random CPU on a random stage
- Versus            - Two players on one computer (keyboard or gamepads)
- Arcade            - Ladder ending with AGI as the final boss in the Senate
- Training          - Practice room with frame data and dummy controls
- Demo              - Two CPU fighters until you press a button
- Options / Best Scores / Replays / Credits

Note: The Online menu is hidden in this build (online/servers.json still
points at the original 3D Fighter lobby server).


CONTROLS
--------
Action                  Keyboard (P1)      Gamepad
----------------------  -----------------  ----------------------
Move / jump / crouch    W A S D            Left stick / D-pad
Light / Heavy Punch     U / I              X / Y
Light / Heavy Kick      J / K              A / B
Power special           O                  LB
Super                   P                  RT
Sidestep                L                  RB
Pause & move list       Esc                Start

Power specials: Press Power (O / LB) for your fighter's signature special, or
hold a direction (forward, back or down) with Power for their other specials.
Press Super (P / RT) once the SUPER meter is full. No motion inputs are
needed; open the pause menu during a fight to see your fighter's move list.

Player 2: Arrow keys with Numpad 4/5 (punches), 1/2 (kicks), 7/8
(Power/Super) and 6 (sidestep), or a second gamepad. On keyboards without a
numpad, the fallback keys are [ ] (punches), ; ' (kicks), \ (Power),
= (Super) and / (sidestep).

Remapping: Every key and gamepad button can be changed per player in
Options -> Controls.


SETTINGS
--------
Saved to:
  ~/Library/Application Support/Godot/app_userdata/AI Showdown/


REQUIREMENTS
------------
- macOS on Apple Silicon or Intel, with Metal support.
- If the game runs slowly on a high-DPI Retina display, lower Resolution or
  Graphics in Options.


CREDITS & LICENSE
-----------------
Based on 3D Fighter by Clint Christopher Canada (MIT / CC BY 4.0).

Source code is licensed under the MIT License; original assets created for
the project are licensed under CC BY 4.0 unless noted otherwise in
assets/CREDITS.md. Third-party assets (including Quaternius base characters
and animations, Kenney sound packs and stage kits, Poly Haven textures and
HDRIs, and OpenGameArt music/voices) are CC0 1.0, except:
- "Aelia Character Preview" by Abinady10 (CC BY)
- Inter / Inter Display fonts by Rasmus Andersson (SIL Open Font License 1.1)
- Permanent Marker font (Apache 2.0)

Built with Godot Engine (https://godotengine.org, MIT License).

------------------------------------------------------------------------
MIT License

Copyright (c) 2026 Clint Christopher Canada

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
