# Transcreve algumas falas geradas com o Whisper para confirmar que se percebem depois do rádio.
import json, sys, sherpa_onnx, soundfile as sf, numpy as np
from scipy.signal import resample_poly
D = "vozes/sherpa-onnx-whisper-small/"
rec = sherpa_onnx.OfflineRecognizer.from_whisper(encoder=D + "small-encoder.int8.onnx", decoder=D + "small-decoder.int8.onnx", tokens=D + "small-tokens.txt", language="pt", task="transcribe", num_threads=4)
idx = json.load(open("godot/arbitro44/assets/voz/voz.json"))
keys = sys.argv[1:] or list(idx)[::6]
for k in keys:
    x, sr = sf.read("godot/arbitro44/assets/voz/" + idx[k]["f"])
    x = resample_poly(x, 16000, sr)
    s = rec.create_stream(); s.accept_waveform(16000, x.astype(np.float32)); rec.decode_stream(s)
    print(f"[{idx[k]['who']}] {k}\n    -> {s.result.text}")
