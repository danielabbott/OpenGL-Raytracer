#include <assert.h>
#include <glad/glad.h>
#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdlib.h>

SDL_Window * window;
SDL_GLContext glContext;

// A handle for every variable in every struct in the uniform array
GLint uniformHandles[10 * 6];
GLint windowDimensionsUniformHandle;

void create_window();
void load_shaders();
void create_gl_state();
void render();
void window_loop();
void cleanup();

#undef main

int main(int argc, char ** argv)
{
	create_window();
	load_shaders();
	create_gl_state();
	render();
	window_loop();
	cleanup();
	return 0;
}

void create_window()
{
	assert (!SDL_Init(SDL_INIT_VIDEO));

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

	window = SDL_CreateWindow("OpenGL Ray Tracer", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_OPENGL);
	assert (window);

	glContext = SDL_GL_CreateContext(window);

	SDL_GL_SetSwapInterval(0);

	gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress);

}

void load_shaders()
{
	GLuint vsid, fsid;

	{
		FILE * f = fopen("vs.glsl", "r");
		assert(f);

		fseek(f, 0, SEEK_END);
		long sz = ftell(f);
		assert(sz > 0);
		fseek(f, 0, SEEK_SET);

		char * data = malloc(sz+1);
		assert(data);
		fread(data, sz, 1, f);
		data[sz] = 0;
		fclose(f);

		vsid = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vsid, 1, (const char **)&data, NULL);
		glCompileShader(vsid);
		free(data);

		GLint status;
		glGetShaderiv(vsid, GL_COMPILE_STATUS, &status);
		if (status == GL_FALSE) {
			printf("Error compiling vertex shader\n");

			GLint logSize = 0;
			glGetShaderiv(vsid, GL_INFO_LOG_LENGTH, &logSize);

			if (logSize > 0) {
				char * log = malloc(logSize + 1);
				glGetShaderInfoLog(vsid, logSize, NULL, log);
				log[logSize] = 0;

				printf("%s\n", log);
			}

			assert(0);
		}
	}

	{
		FILE * f = fopen("fs.glsl", "r");
		assert(f);

		fseek(f, 0, SEEK_END);
		long sz = ftell(f);
		assert(sz > 0);
		fseek(f, 0, SEEK_SET);

		char * data = malloc(sz+1);
		assert(data);
		fread(data, sz, 1, f);
		data[sz] = 0;
		fclose(f);

		fsid = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(fsid, 1, (const char **)&data, NULL);
		glCompileShader(fsid);
		free(data);

		GLint status;
		glGetShaderiv(fsid, GL_COMPILE_STATUS, &status);
		if (status == GL_FALSE) {
			printf("Error compiling fragment shader\n");

			GLint logSize = 0;
			glGetShaderiv(fsid, GL_INFO_LOG_LENGTH, &logSize);

			if (logSize > 0) {
				char * log = malloc(logSize + 1);
				glGetShaderInfoLog(fsid, logSize, NULL, log);
				log[logSize] = 0;

				printf("%s\n", log);
			}

			assert(0);
		}
	}

	GLuint id = glCreateProgram();
	glAttachShader(id, vsid);
	glAttachShader(id, fsid);

	glBindAttribLocation(id, 0, "in_position");

	glLinkProgram(id);

	GLint status;
	glGetProgramiv(id, GL_LINK_STATUS, &status);
	if (status == GL_FALSE) {
		printf("Error linking shaders\n");

		GLint logSize = 0;
		glGetProgramiv(id, GL_INFO_LOG_LENGTH, &logSize);

		if (logSize) {
			char * log = malloc(logSize + 1);
			glGetProgramInfoLog(id, logSize, NULL, log);
			log[logSize] = 0;

			printf("%s\n", log);
		}


		assert(0);
	}

	glUseProgram(id);

	char * s[6];

	for(int i = 0; i < 6; i++) {
		s[i] = malloc(23);
		assert(s[i]);
	}

	strcpy(s[0], "objects[x].type");
	strcpy(s[1], "objects[x].position");
	strcpy(s[2], "objects[x].radius");
	strcpy(s[3], "objects[x].colour");
	strcpy(s[4], "objects[x].attenuation");
	strcpy(s[5], "objects[x].normal");

	int j = 0;
	for(int i = 0; i < 10; i++) {
		for(int k = 0; k < 6; k++) {
			s[k][8] = i + '0';
			GLint uniformHandle = glGetUniformLocation(id, s[k]);
			assert(uniformHandle != -1);
			uniformHandles[j++] = uniformHandle;
		}
	}

	for(int i = 0; i < 6; i++) {
		free(s[i]);
	}

	windowDimensionsUniformHandle = glGetUniformLocation(id, "windowDimensions");
	assert(windowDimensionsUniformHandle != -1);

}

void create_gl_state()
{
	glDisable(GL_MULTISAMPLE);
	glDisable(GL_BLEND);
	glDisable(GL_CULL_FACE);

	glUniform2f(windowDimensionsUniformHandle, 800, 600);

	/* Create scene */

	int i = 0;

	glUniform1i(uniformHandles[i*6+0], 1);
	glUniform3f(uniformHandles[i*6+1], 0, 0, -10);
	glUniform1f(uniformHandles[i*6+2], 3.0f);
	glUniform3f(uniformHandles[i*6+3], 0, 1, 1);

	i = 1;

	glUniform1i(uniformHandles[i*6+0], 2);
	glUniform3f(uniformHandles[i*6+1], 0, 3, 0);
	glUniform1f(uniformHandles[i*6+2], 4);
	glUniform3f(uniformHandles[i*6+3], 10, 10, 10);
	glUniform1f(uniformHandles[i*6+4], 1);


	i = 2;

	glUniform1i(uniformHandles[i*6+0], 3);
	glUniform3f(uniformHandles[i*6+1], 0, -3, 0);
	glUniform1f(uniformHandles[i*6+2], 20);
	glUniform3f(uniformHandles[i*6+3], 0.5f, 0.5f, 0.5f);
	glUniform3f(uniformHandles[i*6+5], 0, 1, 0);

	i = 3;
	glUniform1i(uniformHandles[i*6+0], 1);
	glUniform3f(uniformHandles[i*6+1], 0, 1.3f, -5);
	glUniform1f(uniformHandles[i*6+2], 0.1f);
	glUniform3f(uniformHandles[i*6+3], 1, 0, 0);

	i = 4;
	glUniform1i(uniformHandles[i*6+0], 1);
	glUniform3f(uniformHandles[i*6+1], 0.5f, -0.5f, -2);
	glUniform1f(uniformHandles[i*6+2], 0.5f);
	glUniform3f(uniformHandles[i*6+3], 1, 1, 0);

	i = 5;
	glUniform1i(uniformHandles[i*6+0], 1);
	glUniform3f(uniformHandles[i*6+1], -1, -0.5f, -5);
	glUniform1f(uniformHandles[i*6+2], 0.05f);
	glUniform3f(uniformHandles[i*6+3], 1, 1, 0);

	i = 6;
	glUniform1i(uniformHandles[i*6+0], 1);
	glUniform3f(uniformHandles[i*6+1], 0, -0.13f, -0.11f);
	glUniform1f(uniformHandles[i*6+2], 0.1f);
	glUniform3f(uniformHandles[i*6+3], 1, 1, 1);

	i = 7;
	glUniform1i(uniformHandles[i*6+0], 1);
	glUniform3f(uniformHandles[i*6+1], 10, 5, -30);
	glUniform1f(uniformHandles[i*6+2], 1);
	glUniform3f(uniformHandles[i*6+3], 1, 1, 1);


	assert(!glGetError());
}

void render()
{
	GLfloat vertices[] = {-1,-1, 1,-1, 1,1, -1,1};
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, vertices);

	glDrawArrays(GL_QUADS, 0, 4);

	assert(!glGetError());


	SDL_GL_SwapWindow(window);
}

void window_loop()
{
	SDL_Event e;

    while(1) {
        while( SDL_PollEvent( &e ) != 0 ) {
            if( e.type == SDL_QUIT ) {
                return;
            }
        }

        SDL_WaitEvent(NULL);
    }
}

void cleanup()
{
	SDL_GL_DeleteContext(glContext);
	SDL_DestroyWindow(window);
	SDL_Quit();
}

