# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module portaudio is c_linker_option("-lportaudio")

in "C Header" `{
	#include "portaudio.h"
`}

in "C" `{
	int nit_portaudio_callback(
		void *input_buffer, void *output_buffer,
		unsigned long frames_per_buffer,
		PaTimestamp out_time, void *user_data )
	{
		PaCallbackReceiver recv = (PaCallbackReceiver)user_data;
		return PaCallbackReceiver_callback(recv, input_buffer, output_buffer,
			frames_per_buffer, out_time);
	}
`}

abstract class PaCallbackReceiver
	# Returning `true` stops the stream
	fun callback(input_buffer, output_buffer: Pointer,
		frames_per_buffer: Int, out_time: Float): Bool is abstract
	
	private fun callback_pointer: Pointer import callback `{ return (void*)nit_portaudio_callback; `}
end

extern class PaError `{ PaError `}
	fun is_success: Bool `{ return recv == paNoError; `}

    fun is_host_error: Bool `{ return recv == paHostError; `}
    fun is_invalid_channel_count: Bool `{ return recv == paInvalidChannelCount; `}
    fun is_invalid_sample_rate: Bool `{ return recv == paInvalidSampleRate; `}
    fun is_invalid_device_id: Bool `{ return recv == paInvalidDeviceId; `}
    fun is_invalid_flag: Bool `{ return recv == paInvalidFlag; `}
    fun is_sample_format_not_supported: Bool `{ return recv == paSampleFormatNotSupported; `}
    fun is_bad_io_device_combination: Bool `{ return recv == paBadIODeviceCombination; `}
    fun is_insufficient_memory: Bool `{ return recv == paInsufficientMemory; `}
    fun is_buffer_too_big: Bool `{ return recv == paBufferTooBig; `}
    fun is_buffer_too_small: Bool `{ return recv == paBufferTooSmall; `}
    fun is_null_callback: Bool `{ return recv == paNullCallback; `}
    fun is_bad_stream_ptr: Bool `{ return recv == paBadStreamPtr; `}
    fun is_timed_out: Bool `{ return recv == paTimedOut; `}
    fun is_internal_error: Bool `{ return recv == paInternalError; `}
    fun is_device_unavailable: Bool `{ return recv == paDeviceUnavailable; `}

	redef fun to_s
	do
		var msg = native_to_s.to_s
		if is_host_error then return msg + " ({host_error})"
		return msg
	end
	fun native_to_s: NativeString `{ return (char*)Pa_GetErrorText(recv); `}

	# TODO duplicate?
	private fun host_error: Int `{ return Pa_GetHostError(); `}
end

extern class SampleFormat `{ PaSampleFormat `}
	new float32 `{ return paFloat32; `}
	new int16 `{ return paInt16; `}
	new int32 `{ return paInt32; `}
	new int24 `{ return paInt24; `}
	new packed_int24 `{ return paPackedInt24; `}
	new int8 `{ return paInt8; `}
	new uint8 `{ return paUInt8; `}
	new custom `{ return paCustomFormat; `}

	# Pa_GetSampleSize() returns the size in bytes of a single sample in the
	# supplied PaSampleFormat, or paSampleFormatNotSupported if the format is
	# no supported.
	fun size: Int `{ return Pa_GetSampleSize(recv); `}

	private new none `{ return 0; `}
end

extern class DeviceInfo `{ PaDeviceInfo* `}

	private fun struct_version: Int `{ return recv->structVersion; `}

    fun name: NativeString `{ return (char*)recv->name; `}

    fun max_input_channels: Int `{ return recv->maxInputChannels; `}

    fun max_output_channels: Int `{ return recv->maxOutputChannels; `}

    # Number of discrete rates, or -1 if range supported.
    private fun n_sample_rates: Int `{ return recv->numSampleRates; `}

    # Array of supported sample rates, or {min,max} if range supported.
	# TODO return type CFloatArray
    private fun sample_rates: Pointer `{ return (void*)recv->sampleRates; `}

    fun native_sample_format: SampleFormat `{ return recv->nativeSampleFormats; `}
end

extern class DeviceId `{ PaDeviceID `}

	private new none `{ return 0; `}

	# Pa_GetDeviceInfo() returns a pointer to an immutable PaDeviceInfo structure
	# for the device specified.
	# If the device parameter is out of range the function returns NULL.
	#
	# PortAudio manages the memory referenced by the returned pointer, the client
	# must not manipulate or free the memory. The pointer is only guaranteed to be
	# valid between calls to Pa_Initialize() and Pa_Terminate().
	fun info: DeviceInfo `{ return (PaDeviceInfo*)Pa_GetDeviceInfo(recv); `}

	fun no_device: Bool `{ return recv == paNoDevice; `}
end

# These flags may be supplied (ored together) in the streamFlags argument to
# the Pa_OpenStream() function.
extern class StreamFlags `{ PaStreamFlags `}

	new no_flag `{ return paNoFlag; `}

	# disable default clipping of out of range samples
	new clip_off `{ return paClipOff; `}

	# disable default dithering
	new dither_off `{ return paDitherOff; `}

	new platform_specific_flags `{ return paPlatformSpecificFlags; `}

	fun +(o: StreamFlags): StreamFlags `{ return recv | o; `}
end

extern class StreamCallback `{ PortAudioCallback `}
end

# A single PortAudioStream provides multiple channels of real-time
# input and output audio streaming to a client application.
# Pointers to PortAudioStream objects are passed between PortAudio functions.
extern class PortaudioStream `{ PortAudioStream* `}

	# Pa_OpenStream() opens a stream for either input, output or both.
	# 
	# stream is the address of a PortAudioStream pointer which will receive
	# a pointer to the newly opened stream.
	# 
	# inputDevice is the id of the device used for input (see PaDeviceID above.)
	# inputDevice may be paNoDevice to indicate that an input device is not required.
	# 
	# numInputChannels is the number of channels of sound to be delivered to the
	# callback. It can range from 1 to the value of maxInputChannels in the
	# PaDeviceInfo record for the device specified by the inputDevice parameter.
	# If inputDevice is paNoDevice numInputChannels is ignored.
	# 
	# inputSampleFormat is the sample format of inputBuffer provided to the callback
	# function. inputSampleFormat may be any of the formats described by the
	# PaSampleFormat enumeration (see above). PortAudio guarantees support for
	# the device's native formats (nativeSampleFormats in the device info record)
	# and additionally 16 and 32 bit integer and 32 bit floating point formats.
	# Support for other formats is implementation defined.
	#
	# inputDriverInfo is a pointer to an optional driver specific data structure
	# containing additional information for device setup or stream processing.
	# inputDriverInfo is never required for correct operation. If not used
	# inputDriverInfo should be NULL.
	# 
	# outputDevice is the id of the device used for output (see PaDeviceID above.)
	# outputDevice may be paNoDevice to indicate that an output device is not required.
	# 
	# numOutputChannels is the number of channels of sound to be supplied by the
	# callback. See the definition of numInputChannels above for more details.
	# 
	# outputSampleFormat is the sample format of the outputBuffer filled by the
	# callback function. See the definition of inputSampleFormat above for more
	# details.
	# 
	# outputDriverInfo is a pointer to an optional driver specific data structure
	# containing additional information for device setup or stream processing.
	# outputDriverInfo is never required for correct operation. If not used
	# outputDriverInfo should be NULL.
	# 
	# sampleRate is the desired sampleRate. For full-duplex streams it is the
	# sample rate for both input and output
	# 
	# framesPerBuffer is the length in sample frames of all internal sample buffers
	# used for communication with platform specific audio routines. Wherever
	# possible this corresponds to the framesPerBuffer parameter passed to the
	# callback function.
	# 
	# numberOfBuffers is the number of buffers used for multibuffered communication
	# with the platform specific audio routines. If you pass zero, then an optimum
	# value will be chosen for you internally. This parameter is provided only
	# as a guide - and does not imply that an implementation must use multibuffered
	# i/o when reliable double buffering is available (such as SndPlayDoubleBuffer()
	# on the Macintosh.)
	# 
	# streamFlags may contain a combination of flags ORed together.
	# These flags modify the behaviour of the streaming process. Some flags may only
	# be relevant to certain buffer formats.
	# 
	# callback is a pointer to a client supplied function that is responsible
	# for processing and filling input and output buffers (see above for details.)
	# 
	# userData is a client supplied pointer which is passed to the callback
	# function. It could for example, contain a pointer to instance data necessary
	# for processing the audio buffers.
	# 
	# return value:
	# Upon success Pa_OpenStream() returns PaNoError and places a pointer to a
	# valid PortAudioStream in the stream argument. The stream is inactive (stopped).
	# If a call to Pa_OpenStream() fails a non-zero error code is returned (see
	# PaError above) and the value of stream is invalid.
	new open(input_device: DeviceId, n_input_channels: Int, input_sample_format: SampleFormat, input_driver_info: Pointer,
		output_device: DeviceId, n_output_channels: Int, output_sample_format: SampleFormat, output_driver_info: Pointer,
		sample_rate: Float, frames_per_buffer, n_buffers: Int, stream_flags: StreamFlags, callback: Pointer, user_data: Pointer)
	`{
		PaStream *stream = NULL;
		PaError err = Pa_OpenStream(&stream,
			input_device, n_input_channels, input_sample_format, input_driver_info,
			output_device, n_output_channels, output_sample_format, output_driver_info,
			sample_rate, frames_per_buffer, n_buffers, stream_flags, callback, user_data);
		return stream;
	`}

	# Pa_OpenDefaultStream() is a simplified version of Pa_OpenStream() that opens
	# the default input and/or output devices. Most parameters have identical meaning
	# to their Pa_OpenStream() counterparts, with the following exceptions:
	 
	# If either numInputChannels or numOutputChannels is 0 the respective device
	# is not opened. This has the same effect as passing paNoDevice in the device
	# arguments to Pa_OpenStream().
	 
	# sampleFormat applies to both the input and output buffers.
	new open_default(n_input_channels, n_output_channels: Int, sample_format: SampleFormat,
		sample_rate: Float, frames_per_buffer, n_buffers: Int, callback: StreamCallback, user_data: Pointer)
	`{
		PaStream *stream = NULL;
		PaError err = Pa_OpenDefaultStream(&stream,
			n_input_channels, n_output_channels, sample_format,
			sample_rate, frames_per_buffer, n_buffers, callback, user_data);
		return stream;
	`}

	# Pa_CloseStream() closes an audio stream, flushing any pending buffers.
	fun close: PaError `{ return Pa_CloseStream(recv); `}

	# Pa_StartStream() and Pa_StopStream() begin and terminate audio processing.
	fun start: PaError `{ return Pa_StartStream(recv); `}

	# Pa_StopStream() waits until all pending audio buffers have been played.
	fun stop: PaError `{ return Pa_StopStream(recv); `}

	# Pa_AbortStream() stops playing immediately without waiting for pending
	# buffers to complete.
	fun abort_stream: PaError `{ return Pa_AbortStream(recv); `}

	# Pa_StreamActive() returns one (1) when the stream is active (ie playing
	# or recording audio), zero (0) when not playing, or a negative error number
	# if the stream is invalid.
	# The stream is active between calls to Pa_StartStream() and Pa_StopStream(),
	# but may also become inactive if the callback returns a non-zero value.
	# In the latter case, the stream is considered inactive after the last
	# buffer has finished playing.
	# TODO return BoolOrError
	fun is_active: Bool `{ return Pa_StreamActive(recv); `}

	# Pa_StreamTime() returns the current output time in samples for the stream.
	# This time may be used as a time reference (for example synchronizing audio to
	# MIDI).
	fun time: Float `{ return Pa_StreamTime(recv); `}

	# Pa_GetCPULoad() returns the CPU Load for the stream.
	# The "CPU Load" is a fraction of total CPU time consumed by the stream's
	# audio processing routines including, but not limited to the client supplied
	# callback.
	# A value of 0.5 would imply that PortAudio and the sound generating
	# callback was consuming roughly 50% of the available CPU time.
	# This function may be called from the callback function or the application.
	fun cpu_load: Float `{ return Pa_GetCPULoad(recv); `}
end

class Portaudio
	init
	do
		var err = native_initialize
		assert err.is_success else print "Portaudio init: {err}"
	end

	private fun native_initialize: PaError `{ return Pa_Initialize(); `}

	fun destroy do assert native_terminate.is_success
	private fun native_terminate: PaError `{ return Pa_Terminate(); `}

	# Returns a host specific error code.
	#
	# This can be called after receiving a PortAudio error code which `is_host_error`.
	private fun host_error: Int `{ return Pa_GetHostError(); `}

	# Returns the default device ids for input, or `is_no_device` if
	# no device is available.
	# The result can be passed to `open_stream`.
	# 
	# On the PC, the user can specify a default device by
	# setting an environment variable. For example, to use device #1.
	# 
	#  set PA_RECOMMENDED_OUTPUT_DEVICE=1
	# 
	# The user should first determine the available device ids by using
	# the supplied application `pa_devs`.
	fun default_input_device: DeviceId `{ return Pa_GetDefaultInputDeviceID(); `}

	# Returns the default device ids for output, or `is_no_device` if
	# no device is available.
	fun default_output_device: DeviceId `{ return Pa_GetDefaultOutputDeviceID(); `}

	# Pa_GetMinNumBuffers() returns the minimum number of buffers required by
	# the current host based on minimum latency.
	# On the PC, for the DirectSound implementation, latency can be optionally set
	# by user by setting an environment variable.
	# For example, to set latency to 200 msec, put:
	# 
	# set PA_MIN_LATENCY_MSEC=200
	# 
	# in the AUTOEXEC.BAT file and reboot.
	# If the environment variable is not set, then the latency will be determined
	# based on the OS. Windows NT has higher latency than Win95.
	fun min_n_buffers(frames_per_buffer: Int, sample_rate: Float): Int
	`{
		return Pa_GetMinNumBuffers(frames_per_buffer, sample_rate);
	`}

	# Pa_Sleep() puts the caller to sleep for at least 'msec' milliseconds.
	# You may sleep longer than the requested time so don't rely on this for
	# accurate musical timing.
	# 
	# Pa_Sleep() is provided as a convenience for authors of portable code (such as
	# the tests and examples in the PortAudio distribution.)
	fun sleep(msec: Int) `{ Pa_Sleep(msec); `}

	fun open_stream(input: nullable StreamConfig, output: nullable StreamConfig,
		sample_rate: Float, frames_per_buffer, n_buffers: Int, stream_flags: StreamFlags,
		callback_receiver: PaCallbackReceiver): nullable PortaudioStream
	do
		var input_device
		var n_input_channels
		var input_sample_format
		if input != null then
			input_device = input.device
			n_input_channels = input.n_channels
			input_sample_format = input.sample_format
		else
			input_device = new DeviceId.none
			n_input_channels = 0
			input_sample_format = new SampleFormat.none
		end

		var output_device
		var n_output_channels
		var output_sample_format
		if output != null then
			output_device = output.device
			n_output_channels = output.n_channels
			output_sample_format = output.sample_format
		else
			output_device = new DeviceId.none
			n_output_channels = 0
			output_sample_format = new SampleFormat.none
		end

		callback_receiver.callback_pointer

		return native_open_stream(input_device, n_input_channels, input_sample_format, new Pointer.nil,
			output_device, n_output_channels, output_sample_format, new Pointer.nil,
			sample_rate, frames_per_buffer, n_buffers, stream_flags, callback_receiver)
	end

	fun native_open_stream(input_device: DeviceId, n_input_channels: Int, input_sample_format: SampleFormat, input_driver_info: Pointer,
		output_device: DeviceId, n_output_channels: Int, output_sample_format: SampleFormat, output_driver_info: Pointer,
		sample_rate: Float, frames_per_buffer, n_buffers: Int, stream_flags: StreamFlags, callback_receiver: PaCallbackReceiver): PortaudioStream
	`{
		PaStream *stream = NULL;
		PaError err = Pa_OpenStream(&stream,
			input_device, n_input_channels, input_sample_format, input_driver_info,
			output_device, n_output_channels, output_sample_format, output_driver_info,
			sample_rate, frames_per_buffer, n_buffers, stream_flags, nit_portaudio_callback, callback_receiver);
		return stream;
	`}

	var error: nullable PaError = null

	fun assert_success do assert error.is_success
end

class StreamConfig
	var device: DeviceId
	var n_channels: Int
	var sample_format: SampleFormat
end

redef extern class Pointer
	new nil `{ return NULL; `}
end
