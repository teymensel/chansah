extends Node

# Cihanşah - Tarihsel & Prosedürel Ses Yöneticisi
# Harici dosya bağımlılığı olmadan temiz 16-bit PCM sesler üretir ve çalar.

var player_pool: Array[AudioStreamPlayer] = []
var pool_size: int = 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(pool_size):
		var p = AudioStreamPlayer.new()
		add_child(p)
		player_pool.append(p)

func _get_available_player() -> AudioStreamPlayer:
	for p in player_pool:
		if not p.playing:
			return p
	return player_pool[0]

func play_gunshot() -> void:
	var stream = _generate_gunshot()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = 0.0
	p.play()

func play_reload() -> void:
	var stream = _generate_reload()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = -2.0
	p.play()

func play_abdest_water() -> void:
	var stream = _generate_water()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = -3.0
	p.play()

func play_horse_gallop() -> void:
	var stream = _generate_gallop()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = -4.0
	p.play()

func play_sword_slash() -> void:
	var stream = _generate_slash()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = -1.0
	p.play()

func play_bullet_drop() -> void:
	var stream = _generate_bullet_drop()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = 2.0
	p.play()

func play_ui_click() -> void:
	var stream = _generate_click()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = -6.0
	p.play()

func play_quest_complete() -> void:
	var stream = _generate_fanfare()
	var p = _get_available_player()
	p.stream = stream
	p.volume_db = 1.0
	p.play()

func play_prayer_ambient() -> void:
	pass

func play_takbir_tone() -> void:
	pass


# ----------------- SES SENTEZLEYİCİLERİ -----------------

func _create_wav(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var byte_array = PackedByteArray()
	byte_array.resize(samples.size() * 2)
	
	for i in range(samples.size()):
		var val = clampf(samples[i], -1.0, 1.0)
		var int16_val = int(val * 32767.0)
		if int16_val < 0:
			int16_val += 65536
		byte_array[i * 2] = int16_val & 0xFF
		byte_array[i * 2 + 1] = (int16_val >> 8) & 0xFF
		
	wav.data = byte_array
	return wav

func _generate_gunshot() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 0.45)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-18.0 * t)
		var noise = randf_range(-1.0, 1.0)
		var boom = sin(TAU * 70.0 * t) * exp(-7.0 * t)
		samples[i] = (noise * 0.65 + boom * 0.75) * env
	return _create_wav(samples, rate)

func _generate_reload() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 0.35)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t = float(i) / rate
		var c1 = sin(TAU * 1600.0 * t) * exp(-80.0 * absf(t - 0.05))
		var c2 = sin(TAU * 2100.0 * t) * exp(-90.0 * absf(t - 0.15))
		var snap = sin(TAU * 1100.0 * t) * exp(-60.0 * absf(t - 0.25))
		samples[i] = (c1 * 0.5 + c2 * 0.6 + snap * 0.9)
	return _create_wav(samples, rate)

func _generate_water() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 0.9)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t = float(i) / rate
		var env = sin(PI * (t / 0.9))
		var w1 = sin(TAU * 380.0 * t + sin(t * 25.0))
		var w2 = sin(TAU * 750.0 * t) * 0.35
		var noise = randf_range(-0.2, 0.2)
		samples[i] = (w1 * 0.4 + w2 + noise) * env * 0.7
	return _create_wav(samples, rate)

func _generate_gallop() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 0.4)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t = float(i) / rate
		var h1 = sin(TAU * 130.0 * t) * exp(-50.0 * absf(t - 0.07))
		var h2 = sin(TAU * 160.0 * t) * exp(-55.0 * absf(t - 0.2))
		var noise = randf_range(-0.1, 0.1)
		samples[i] = (h1 * 0.8 + h2 * 1.0 + noise) * 0.8
	return _create_wav(samples, rate)

func _generate_slash() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 0.25)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t = float(i) / rate
		var freq = 250.0 + 750.0 * (1.0 - t / 0.25)
		var env = sin(PI * (t / 0.25))
		samples[i] = sin(TAU * freq * t) * env * 0.6
	return _create_wav(samples, rate)

func _generate_bullet_drop() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 0.7)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t = float(i) / rate
		var b1 = sin(TAU * 2600.0 * t) * exp(-70.0 * absf(t - 0.05))
		var b2 = sin(TAU * 2900.0 * t) * exp(-80.0 * absf(t - 0.18))
		var b3 = sin(TAU * 3200.0 * t) * exp(-90.0 * absf(t - 0.32))
		var b4 = sin(TAU * 3400.0 * t) * exp(-95.0 * absf(t - 0.45))
		samples[i] = (b1 * 0.7 + b2 * 0.6 + b3 * 0.5 + b4 * 0.4)
	return _create_wav(samples, rate)

func _generate_click() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 0.08)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	for i in range(count):
		var t = float(i) / rate
		samples[i] = sin(TAU * 1200.0 * t) * exp(-80.0 * t) * 0.5
	return _create_wav(samples, rate)

func _generate_fanfare() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 1.2)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	# Osmanlı Mehter/Zafer ezgisi akorları (Neva / Hicaz esintisi)
	var notes = [293.66, 329.63, 349.23, 440.0, 523.25]
	for i in range(count):
		var t = float(i) / rate
		var note_idx = int(t * 4.0) % notes.size()
		var freq = notes[note_idx]
		var env = exp(-3.0 * fmod(t, 0.25))
		samples[i] = (sin(TAU * freq * t) * 0.5 + sin(TAU * freq * 2.0 * t) * 0.25) * env * 0.7
	return _create_wav(samples, rate)

func _generate_ney_ambient() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 3.5)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	# Tasavvufi Ney / Rast Makamı huzurlu tınısı (293.66Hz Re, 370Hz Fa#, 440Hz La)
	for i in range(count):
		var t = float(i) / rate
		var vib = sin(TAU * 5.0 * t) * 4.0
		var freq1 = 293.66 + vib
		var freq2 = 440.0 + vib * 1.5
		var breath = randf_range(-0.06, 0.06)
		var env = sin(PI * clampf(t / 3.5, 0.0, 1.0))
		var tone = (sin(TAU * freq1 * t) * 0.6 + sin(TAU * freq2 * t) * 0.35 + breath) * env * 0.65
		samples[i] = tone
	return _create_wav(samples, rate)

func _generate_takbir_bell() -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * 1.8)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	# Vakur ve derin kandil çınlaması
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-2.2 * t)
		var wave = sin(TAU * 220.0 * t) * 0.6 + sin(TAU * 440.0 * t) * 0.3 + sin(TAU * 660.0 * t) * 0.15
		samples[i] = wave * env * 0.75
	return _create_wav(samples, rate)

