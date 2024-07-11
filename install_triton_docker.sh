# Installation within docker containers

pip install git+https://github.com/triton-inference-server/triton_cli.git@0.0.7
huggingface-cli login --token <token> # replace <token> with your HuggingFace Token obtained from https://huggingface.co/settings/tokens 
pip install setuptools==69.5.1
pip install vllm==0.4.0.post1 flash-attn==2.4.2
pip install "git+https://github.com/triton-inference-server/client.git@r24.03#subdirectory=src/c++/perf_analyzer/genai-perf"

