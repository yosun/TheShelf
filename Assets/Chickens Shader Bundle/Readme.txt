Chickens Shader Bundle V1.59

This is a shader package to help you make reailistic and good looking effects for your game.
Right now it contains:

- Parallax Specular Mapping with approximate self shadows.
- Cook-Torrance Bumped Specular lighting (with reflective, parallax and self shadowed parallax versions).
- Self Shadowed relief Mapping.
- Different faked subsurface scattering multilayer skinshaders. Version 1.3 supports translucency.
- Toonshading.
- Forcefield shaders.
- Translucency shader.
- A simple image based lighting shader.
- Various detail shaders
- Screenspace Subsurface Scattering (Only working with Pro)
- Outline Glow Postprocessing effect.
- Various mobile shaders


Note!!!:	The screenspace subsurface scattering effect might have some bugs and/or issues with different settings, so please contact me on the Unity forums if you are having trouble using it.
			In Addition to that, this effect is quite expensive, so be careful to use the correct settings.

Important! - Outline Glow Effect

Don't change the topdraw objects when in playmode in the editor. This might cause a massive crash!

Tips:

- Ramp textures for the ramplit cartoon shaders need to be set to "clamp" instead of "repeat".

- If you don't want to use prebaked ambient occlusion, use the white texture from the skinshader example.

- A quick way for a good looking depth/translucency map:
 -> Open the model in your favourite modeling tool.
 -> Invert the normals.
 -> Bake ambient occlusion (try different distances and falloffs)
 -> Invert the colors of the resulting ao map.
 -> Use it as alpha in your translucency map.

All shaders are SM3.0 and are always drawn in forward rendering mode, because they use a cutom lighting function.

Have a look at the few examples, just play around with the different shaders or have a look at the "Chickens Shader Bundle" thread on the Unity forums for more information.

If you have any question, feedback, bugs or wishes go to the Chickens Shader Bundle thread or send me (Chickenlord) a pm on the unity forums.


The Chickenlord