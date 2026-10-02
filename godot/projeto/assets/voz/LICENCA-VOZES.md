# Vozes das falas

As falas em assets/voz/*.ogg foram geradas com as vozes neurais Piper de português de Portugal
"dii" (feminina: assistente, 4.º árbitro) e "miro" (masculina: VAR, árbitro, relato), do projeto
OpenVoiceOS (https://huggingface.co/OpenVoiceOS/pipertts_pt-PT_dii e .../pipertts_pt-PT_miro),
na conversão para ONNX do sherpa-onnx (https://github.com/k2-fsa/sherpa-onnx, release tts-models).
Depois foram misturadas com rádio, público, passos e respiração por tools/vozes/gerar.py.

Licença das vozes e destas falas (obra derivada): Creative Commons
Atribuição-NãoComercial-PartilhaIgual 4.0 Internacional (CC BY-NC-SA 4.0),
https://creativecommons.org/licenses/by-nc-sa/4.0/

Não permite uso comercial. Antes de vender o jogo, as falas têm de ser regeradas com uma voz
de licença comercial (por exemplo a "tugão", dataset CC0, que se percebe pior) ou gravadas por
pessoas, com o mesmo gerar.py.
