# Fake IBM 5150

This is a tribute to the IBM PC 5150, the first computer I ever used. It
accompanies this YouTube video:

https://youtu.be/JMWnAJXnrW4

### Usage

Put an AGI sierra game of your choice in `project/game`. Anything should
work.

### Controls

Rotate around the 5150 by holding the middle mouse button and dragging.

Left click on the switch on the side to turn it on.

Once the Sierra game has started you can control it with the keyboard
as you'd expect.

### Compiling

Run `scons` to compile sarien in GDNative. For example on a Mac you can
do this:

`$ scons platform=macos`

Then open the project in Godot and hit Play. It should just work (tm).

