var gl;
var canvas;
var shaderProgramId;
var vboId;
var windowDimensionsUniformId;

var uniformHandles = [];

function init() {
	canvas = document.getElementById("c");
	gl = WebGLUtils.setupWebGL(canvas);
	if (!gl) {
		alert('Error initialising WebGL')
		return;
	}
	
	gl.viewport(0, 0, canvas.width, canvas.height);


	gl.disable(gl.BLEND);
	gl.disable(gl.CULL_FACE);

	createShaderPrograms();
	createVBO();
	getUniformHandles();
	createScene();

	if(gl.getError() != gl.NO_ERROR) {
		logError('OpenGL error');
	}
	
	lastTime = new Date().getTime();	
	render();
}

function logError(s) {
	console.log(s);
	document.write(s + '<br>');
}


function createShaderPrograms() {
	var vshader = gl.createShader(gl.VERTEX_SHADER);
    if(vshader == 0)
		return 0;

	var request = new XMLHttpRequest();
	request.responseType = ""; 
	request.open('GET', 'vs.glsl', false);
	request.send();
	var vertexShaderSrc = request.responseText;

	gl.shaderSource(vshader, vertexShaderSrc);

    gl.compileShader(vshader);

    var compiled = gl.getShaderParameter(vshader, gl.COMPILE_STATUS);
    if(!compiled)
	{
		var error = gl.getShaderInfoLog(vshader);
       	logError("Error compiling vertex shader: " + error);
		throw new Error('Error compiling vertex shader');
	}

	var fshader = gl.createShader(gl.FRAGMENT_SHADER);
    if(fshader == 0)
		return 0;

	var request = new XMLHttpRequest();
	request.responseType = ""; 
	request.open('GET', 'fs.glsl', false);
	request.send();
	var fragmentShaderSrc = request.responseText;

	gl.shaderSource(fshader, fragmentShaderSrc);

    gl.compileShader(fshader);

    var compiled = gl.getShaderParameter(fshader, gl.COMPILE_STATUS);
    if(!compiled)
	{
		var error = gl.getShaderInfoLog(fshader);
       	logError("Error compiling fragment shader: " + error);
		throw new Error('Error compiling fragment shader');
	}

	shaderProgramId = gl.createProgram();
	gl.attachShader(shaderProgramId, vshader);
	gl.attachShader(shaderProgramId, fshader);

	gl.bindAttribLocation(shaderProgramId, 0, 'in_position'); 

	gl.linkProgram(shaderProgramId);

	if(!gl.getProgramParameter(shaderProgramId, gl.LINK_STATUS)) {
		var error = gl.getProgramInfoLog(shaderProgramId);
       	logError("Error linking shader program: " + error);
		throw new Error('Error linking shader program');
	}

	gl.detachShader(shaderProgramId, vshader);
	gl.detachShader(shaderProgramId, fshader);

	gl.validateProgram(shaderProgramId);
	gl.useProgram(shaderProgramId);
}

var vbo_data = new Float32Array([
	-1,-1, 1,-1, 1,1, 1,1, -1,1, -1,-1,
]);

function createVBO() {
	vboId = gl.createBuffer();
	gl.bindBuffer(gl.ARRAY_BUFFER, vboId);
	gl.bufferData(gl.ARRAY_BUFFER, vbo_data, gl.STATIC_DRAW);
}

function getUniformHandles() {
	windowDimensionsUniformId = gl.getUniformLocation(shaderProgramId, 'windowDimensions');

	for(var i = 0; i < 10; i++) {
		uniformHandles.push(gl.getUniformLocation(shaderProgramId, "objects[" + i + "].type"));
		uniformHandles.push(gl.getUniformLocation(shaderProgramId, "objects[" + i + "].position"));
		uniformHandles.push(gl.getUniformLocation(shaderProgramId, "objects[" + i + "].radius"));
		uniformHandles.push(gl.getUniformLocation(shaderProgramId, "objects[" + i + "].colour"));
		uniformHandles.push(gl.getUniformLocation(shaderProgramId, "objects[" + i + "].attenuation"));
		uniformHandles.push(gl.getUniformLocation(shaderProgramId, "objects[" + i + "].normal"));
	}
}

function createScene() {
	var i = 0;

	gl.uniform1i(uniformHandles[i*6+0], 1);
	gl.uniform3f(uniformHandles[i*6+1], 0, 0, -10);
	gl.uniform1f(uniformHandles[i*6+2], 3.0);
	gl.uniform3f(uniformHandles[i*6+3], 0, 1, 1);

	i = 1;

	gl.uniform1i(uniformHandles[i*6+0], 2);
	gl.uniform3f(uniformHandles[i*6+1], 0, 3, 0);
	gl.uniform1f(uniformHandles[i*6+2], 4);
	gl.uniform3f(uniformHandles[i*6+3], 10, 10, 10);
	gl.uniform1f(uniformHandles[i*6+4], 1);


	i = 2;

	gl.uniform1i(uniformHandles[i*6+0], 3);
	gl.uniform3f(uniformHandles[i*6+1], 0, -3, 0);
	gl.uniform1f(uniformHandles[i*6+2], 20);
	gl.uniform3f(uniformHandles[i*6+3], 0.5, 0.5, 0.5);
	gl.uniform3f(uniformHandles[i*6+5], 0, 1, 0);

	i = 3;
	gl.uniform1i(uniformHandles[i*6+0], 1);
	gl.uniform3f(uniformHandles[i*6+1], 0, 1.3, -5);
	gl.uniform1f(uniformHandles[i*6+2], 0.1);
	gl.uniform3f(uniformHandles[i*6+3], 1, 0, 0);

	i = 4;
	gl.uniform1i(uniformHandles[i*6+0], 1);
	gl.uniform3f(uniformHandles[i*6+1], 0.5, -0.5, -2);
	gl.uniform1f(uniformHandles[i*6+2], 0.5);
	gl.uniform3f(uniformHandles[i*6+3], 1, 1, 0);

	i = 5;
	gl.uniform1i(uniformHandles[i*6+0], 1);
	gl.uniform3f(uniformHandles[i*6+1], -1, -0.5, -5);
	gl.uniform1f(uniformHandles[i*6+2], 0.05);
	gl.uniform3f(uniformHandles[i*6+3], 1, 1, 0);

	i = 6;
	gl.uniform1i(uniformHandles[i*6+0], 1);
	gl.uniform3f(uniformHandles[i*6+1], 0, -0.13, -0.11);
	gl.uniform1f(uniformHandles[i*6+2], 0.1);
	gl.uniform3f(uniformHandles[i*6+3], 1, 1, 1);

	i = 7;
	gl.uniform1i(uniformHandles[i*6+0], 1);
	gl.uniform3f(uniformHandles[i*6+1], 10, 5, -30);
	gl.uniform1f(uniformHandles[i*6+2], 1);
	gl.uniform3f(uniformHandles[i*6+3], 1, 1, 1);
}

function render() {

	gl.clearColor(1,0,0,1);
	gl.clear(gl.COLOR_BUFFER_BIT);

	gl.uniform2f(windowDimensionsUniformId, 800, 600);

	gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
	gl.enableVertexAttribArray(0);
	gl.bindBuffer(gl.ARRAY_BUFFER, vboId);

	gl.drawArrays(gl.TRIANGLES, 0, 6);
}

window.onload = init;