# Vertex Animation Textures for Godot

This was hacked together on one afternoon. It is not well tested or production ready.
All scripts in the `animation_baking` directory are tool scripts, this way you can
also use them in editor scripts if you want to bake the animations in advance.

A demo that bakes the textures at runtime can be found in `demo.gd`. Please be aware
that running the project can take several seconds before the window even appears
since the backing blocks the main process.
