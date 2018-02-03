#version 100

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 windowDimensions;

attribute vec2 in_position;

varying vec2 pass_position;

void main()
{
	gl_Position = vec4(in_position.xy, 0.0, 1.0);
	pass_position = ((in_position + 1.0) * 0.5) * windowDimensions;
}
