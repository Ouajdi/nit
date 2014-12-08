import glesv2_display

redef class GammitProgram
	var shadow_texture_resolution = 1024

	var shadow_program: ShadowProgram is lazy do
		var shadow = new GLTexture
		shadow.bind

		gl_tex_parameter_mag_filter(new GLTextureTarget.flat, new GLTextureMagFilter.nearest)
		gl_tex_parameter_min_filter(new GLTextureTarget.flat, new GLTextureMinFilter.nearest)
		gl_tex_parameter_wrap_s(new GLTextureTarget.flat, new GLTextureWrap.clamp_to_edge)
		gl_tex_parameter_wrap_t(new GLTextureTarget.flat, new GLTextureWrap.clamp_to_edge)

		#glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE );
		#glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL );

		#glTexImage2D ( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24,
		#shadow_texture_resolution, shadow_texture_resolution
		#0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, NULL );

		#glBindTexture ( GL_TEXTURE_2D, 0 );

		#glGetIntegerv ( GL_FRAMEBUFFER_BINDING, &defaultFramebuffer );

		#glGenFramebuffers ( 1, &userData->shadowMapBufferId );
		#glBindFramebuffer ( GL_FRAMEBUFFER, userData->shadowMapBufferId );

		#glDrawBuffers ( 1, &none );

		#glFramebufferTexture2D ( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, userData->shadowMapTextureId, 0 );

		texture.active 0 # TODO remove receiver?
		shadow.bind

		#if ( GL_FRAMEBUFFER_COMPLETE != glCheckFramebufferStatus ( GL_FRAMEBUFFER ) )
		#{
		#return FALSE;
		#}

		#glBindFramebuffer ( GL_FRAMEBUFFER, defaultFramebuffer );
	end
end

class ShadowProgram
	super GammitProgram

	#
	init
	do
		from_source(vertex_shader_source, fragment_shader_source)
		super
	end

	#
	var vertex_shader_source = """
		#version 300 es

		uniform mat4 u_mvpLight;
		in vec4 a_position;
		out vec4 v_color;

		void main()
		{
			gl_Position = u_mvpLight * a_position;
		}
		""" @ glsl_vertex_shader

	#
	fun mvp_light: UniformFloatMat4 is lazy do return uniforms["u_mvpLight"].as(UniformFloatMat4)

	# Position of each vertex
	fun position: AttributeFloatVec4 is lazy do return attributes["position"].as(AttributeFloatVec4)

	#
	var fragment_shader_source = """
		#version 300 es

		precision lowp float;

		void main() {}
		""" @ glsl_fragment_shader
end

class DrawWithShadeowProgram
	super DefaultGammitProgram

	#
	init
	do
		from_source(vertex_shader_source, fragment_shader_source)
		super
	end

	#
	redef var vertex_shader_source = """
		attribute vec4  position;
		attribute vec4  color;
		attribute vec4  translation;
		attribute float scale;
		attribute vec2  texCoord;

		uniform  mat4 projection;
		uniform mat4 u_mvpLight;

		varying vec4 v_color;
		varying vec2 v_texCoord;
		varying vec2 shadowCoord;

		void main()
		{
		  v_color = color;
		  gl_Position = (vec4(position.xyz * scale, 1.0) + translation) * projection;
		  v_texCoord = texCoord;
		}
		""" @ glsl_vertex_shader

	#
	fun mvp_light: UniformFloatMat4 is lazy do return uniforms["u_mvpLight"].as(UniformFloatMat4)

	#
	redef var fragment_shader_source = """
		precision mediump float;

		varying vec4 v_color;
		varying vec2 v_texCoord;
		varying vec2 shadowCoord;

		uniform sampler2D vTex;
		uniform bool use_texture;

		//out vec4 outColor;

		void main()
		{
			if(use_texture) {
				//outColor = v_color * texture(vTex, v_texCoord);
				gl_FragColor = v_color * texture2D(vTex, v_texCoord);
				if(gl_FragColor.a < 0.1) discard;
			} else {
				//outColor = v_color;
				gl_FragColor = v_color;
			}
			//gl_FragColor = v_color * v_texCoord.x;
		}
		""" @ glsl_fragment_shader
end
