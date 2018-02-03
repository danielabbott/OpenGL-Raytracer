#version 100

#define MSAA
//#define HIGHLIGHT_EDGES
#define FSAA

#ifdef HIGHLIGHT_EDGES
#ifndef MSAA
#define MSAA
#endif
#endif

#ifdef FSAA
#ifndef MSAA
#define MSAA
#endif
#endif

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 windowDimensions;

struct Object {
	/* 0=None, 1=Sphere, 2=light, 3=infinite plane / disc */
	int type;

	vec3 position;
	float radius; // for spheres and discs (0 for infinite plane)
	vec3 colour;
	float attenuation; // for lights
	vec3 normal; // for planes/discs
};

uniform Object objects[10];

/* Window coordinates (in pixels) */
varying vec2 pass_position;

/* Returns distance to the sphere if there was an intersection, 0 otherwise */
/* edge = true for pixels on or near the edge of the sphere */
float ray_sphere_intersection(vec3 rayDirection, vec3 relativePosition, float radius, out bool edge)
{
	// Quadratic for ray-sphere intersection when sphere is at origin:
	// a = D^2
	// b = 2OD
	// c = O^2 - R^2
	// where D = ray direction, O = ray origin and R = sphere radius

	vec3 D = rayDirection;
	vec3 O = -relativePosition; // move camera ray to put sphere at origin
	float R = radius;

	float a = dot(D, D);
	float b = 2.0 * dot(O, D);
	float c = dot(O, O) - R*R;

	// discriminant = b^2 - 4ac

	float discr = b*b - 4.0*a*c;

	if (discr < 0.0) {
		// No solutions to quadratic
		return 0.0;
	}

	/* Quadratic has a solution, solve it */

	float negB = -b;
	float aDouble = 2.0*a;
	float root = sqrt(discr);

	if(root == 0.0) {
		// Both solutions are equal.
		edge = true;
		return (negB + root) / aDouble;
	}


	float x1 = (negB + root) / aDouble;
	float x2 = (negB - root) / aDouble;

	/* Pick the smallest positive solution */

	float x;

	if(x1 < 0.0) {
		edge = true;
		return x2;
	}
	else if(x2 < 0.0) {
		edge = true;
		return x1;
	}
	else if(x1 < x2) {
		edge = x2-x1 <= 0.07*x2;
		return x1;
	}
	else {
		edge = x1-x2 <= 0.07*x1;
		return x2;
	}
}

/* Returns distance to the plane/disc if there was an intersection, 0 otherwise */
float ray_infinite_plane_intersection(vec3 rayDirection, vec3 relativePosition, vec3 planeNormal, float radius, out bool edge)
{
	// t = ((p0) * n) / (l * n)
	// where p0 = relative position of plane
	// 		 n = plane normal
	//		 l = ray direction

	float denominator = dot(rayDirection, planeNormal);

	if(denominator == 0.0)
		return 0.0;

	float t = dot(relativePosition, planeNormal) / denominator;

	if(t > 0.0) {
		if(radius > 0.0) {
			// This is a disc, not a plane. 
			// The solution is only valid if it is close enough to the cenre of the disc.

			float distFromCentre = length(rayDirection * t - relativePosition);
			if(distFromCentre <= radius) {
				if(distFromCentre >= radius-0.1) {
					edge = true;
				}
				return t;
			}
			return 0.0;
		}

		edge = false;
		return t;
	}

	return 0.0;
}

bool get_first_intersection(vec3 rayOrigin, vec3 rayDirection, out Object nearestObject, out float nearestObjectDistance, Object ignoreObject, out bool nearestObjectEdge)
{
	nearestObjectDistance = 10000.0;

	bool hit = false;

	for(int i = 0; i < 10; i++) {
		// Check each non-light object for an intersection

		if(objects[i] != ignoreObject && objects[i].type != 2) {

			float dist;
			bool edge;
			if(objects[i].type == 1) {
				dist = ray_sphere_intersection(rayDirection, objects[i].position - rayOrigin, objects[i].radius, edge);
			}
			else if(objects[i].type == 3) {
				dist = ray_infinite_plane_intersection(rayDirection, objects[i].position - rayOrigin, objects[i].normal, objects[i].radius, edge);
			} else {
				dist = 10000.0;
			}

			if(dist > 0.0 && dist < nearestObjectDistance) {
				// This is the new nearest intersection.
				// Overwrite the previous intersection (if there was one)
				nearestObject = objects[i];
				nearestObjectDistance = dist;
				nearestObjectEdge = edge;
				hit = true;
			}
		}
	}

	return hit;
}

vec3 calulate_normal(Object object, vec3 position)
{
	if(object.type == 1) {
		return normalize(position - object.position);
	}
	else if(object.type == 3) {
		return object.normal;
	}
}

vec3 apply_lights(vec3 position, Object object, vec3 normal)
{
	vec3 finalColour = vec3(0);

	for(int i = 0; i < 10; i++) {
		if(objects[i].type == 2) {
			vec3 surfaceToLight = objects[i].position - position;

			/* Check for objects blocking the light (casting a shadow) */

			Object nearestObject;
			float nearestObjectDistance;

			bool edge;
			bool hit = get_first_intersection(position, surfaceToLight, nearestObject, nearestObjectDistance, object, edge);

			if(!hit) {
				// Nothing is casting a shadow

				/* Calculate brightness */

				float intensity = dot(normal, surfaceToLight);
				float distance = max(0.001, length(surfaceToLight));

				/* Apply colour */

				finalColour += ((objects[i].colour * object.colour * intensity) / (distance * distance* objects[i].attenuation));
			}
		}
	}
	return finalColour;
}

/* Returns the colour of the pixel */
/* onEdge is set to true if the pixel is on the edge of the shape (if so, multisampling should be done) */
vec3 castRay(vec2 pixelPosition, out bool onEdge, bool getColour)
{
	float cameraPlaneYHeight = windowDimensions.y / windowDimensions.x;


	/* Define the ray for this pixel (array starts at origin) */
	/* A virtual plane of size 1 x (h/w) units is positioned 1 unit in front of the camera */

	vec3 rayDirection = vec3((pixelPosition / windowDimensions.x) - vec2(0.5, cameraPlaneYHeight / 2.0), -1);
	rayDirection = normalize(rayDirection);

	/* Find intersections between the ray and the objects in the scene */

	Object nullObject;

	Object nearestObject;
	float nearestObjectDistance;
	bool hit = get_first_intersection(vec3(0.0), rayDirection, nearestObject, nearestObjectDistance, nullObject, onEdge);
	
	if(!hit) {
		onEdge = false;
		return vec3(0.0, 0.0, 0.0);
	}
#ifdef HIGHLIGHT_EDGES
	else if(onEdge) {
		onEdge = false; // Don't do MSAA if we are highlighting the edges
		return vec3(0.0, 1.0, 0.0);
	}
#endif
	else {
		if(getColour) {
			vec3 position = rayDirection * nearestObjectDistance;
			vec3 normal = calulate_normal(nearestObject, position);
			return vec3(apply_lights(position, nearestObject, normal));
		}
		else {
			// skip lighting calculations
			return vec3(0.0, 0.0, 0.0);
		}
	}

}

/* main() is called once for every pixel on the screen */
void main()
{
	bool edge;

#ifdef MSAA
#ifndef HIGHLIGHT_EDGES
	castRay(pass_position, edge, false);

	#ifdef FSAA
	edge = true;
	#endif

	if(edge) {
		/* Sample four more times and get the colour values this time */

		vec3 centralColour1 = castRay(vec2(pass_position.x+0.1, pass_position.y-0.4), edge, true);
		vec3 centralColour2 = castRay(vec2(pass_position.x-0.4, pass_position.y-0.1), edge, true);
		vec3 centralColour3 = castRay(vec2(pass_position.x-0.2, pass_position.y+0.4), edge, true);
		vec3 centralColour4 = castRay(vec2(pass_position.x+0.4, pass_position.y+0.1), edge, true);

		/* Average the colours */

		vec3 newColour = (centralColour1 + centralColour2 + centralColour3 + centralColour4) / 4.0;

		gl_FragColor = vec4(newColour, 1.0);
	} else {
#endif
#endif
		/* No MSAA or FSAA, just put the colour on the screen */

		vec3 colour = castRay(pass_position, edge, true);

		gl_FragColor = vec4(colour, 1.0);

#ifdef MSAA
#ifndef HIGHLIGHT_EDGES
	}
#endif
#endif

}
