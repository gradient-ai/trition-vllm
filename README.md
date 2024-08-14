# Triton with vllm Backend
- This tutorial demonstrated inferencing solution utilizing Triton with vllm Backend
- This tutorial uses A6000x4 machines. The instructions are also portable to other Multi-GPU machines such as A100x8 and H100x8 with very minor adjustments which will also be stated in this tutorial.

# Prerequisites
- A CORE Paperspace Account that has permission to create A6000X4.
- A local environment where you can run Terraform.
- A HuggingFace Token obtained from https://huggingface.co/settings/tokens 

# Tutorial
The tutorial begins now. Please follow each steps sequentially.

## Obtain API Keys for your Paperspace Account
Obtain your API Keys for your CORE Paperspace Account by following the instructions at https://docs.digitalocean.com/reference/paperspace/api-keys/.

## Edit the main.tf file
- Edit line 12 of the main.tf file with the API keys you just obtained.
- Edit line 20 with the email address of a user on your paperspace team
- Edit line 21 with the team ID of your Private workspace. You may find the team ID under the Priate workspace located at the top left hand corner as per https://docs.digitalocean.com/screenshots/paperspace/security-api-key.1ddd0cf5792ee166808e1b64e8725b78d6dbe3148d45b92fc8a0470bc06c099e.png under the Team Settings of the profile icon.

## Install Terraform
- Following the official instruction from Terraform website to install Terraform: https://developer.hashicorp.com/terraform/install

## Create a working directory for A6000x4 and run Terraform
If you already have a working machine, you may skip this step and just use a working machine. However, note that the steps listed in the following sections may need to be adjusted if it's not running on A6000x4 machines.
- Go to your home directory (e.g. cd /home/<username>)
- `mkdir A6000x4`
- `cd A6000x4`
- Place the main.tf file that you just edited above in this directory.
- `terraform init`
- `terraform plan`, to double check and ensure that it passes with the values configured in the main.tf (it should be 2 to add, 0 to change, 0 to destroy)
- `terraform apply`, then enter "yes"
- Wait for a few minutes until it finishes, then go to the Paperspace Console to double check that A6000x4 machine is created.


## Setup script on A6000x4 machine
In this step, you will run the setup script to install the required drivers.
**Note**: If you have a baremetal H100x8 machines or have [ML-In-A-Box Ubuntu 22](https://github.com/Paperspace/ml-in-a-box/tree/main/ubuntu-22), **do not** run this script but rather proceed to the last step f starting the tritonserver in this section.
- ssh into your A6000x4 machine
- Download `setup.sh` from GitHub and run the setup script. Note that, the script run expected to take roughly 20-30 minutes. The script may prompt you to restart process through a purple screen, hit "Enter" and continue or else it will stuck. Note: If you're running baremetal machines from Paperspace, do not run the setup.sh as it will cause a mismatch of driver between the host and the container. 
- After the script run is completed, it will automatically restart the machine. Wait for a few minutes and you can then ssh again into the machine.
- Run `nvidia-smi` to ensure that the nvidia drivers are installed. You should see "CUDA Version: 12.5" on the top right.
- Run `sudo chmod 666 /var/run/docker.sock`
- Run the following command to start the tritonserver vllm container. Note that this command will download and extract 10+GB of docker image and may take a few minutes:
```
docker run -ti \
  -d \
  --privileged \
  --gpus all \
  --network=host \
  --shm-size=10.24g --ulimit memlock=-1 \
  -v ${HOME}/models:/root/models \
  -v ${HOME}/.cache/huggingface:/root/.cache/huggingface \
  nvcr.io/nvidia/tritonserver:24.05-vllm-python-py3
```

## Setup within vllm+triton container
In this step, you will install triton CLI, GenAI-Perf, and the relevant tools and versions that are required for the Inference Server.
- Run `docker exec -it $(docker ps -q) sh` to shell into the container.
- Download the install script `install_triton_docker.sh` from GitHub.
- Edit line 4 of the script to include your huggingface token as described in the comment.
- Run the script `install_triton_docker.sh`

## Run Triton Inference Server with Llama3-70B-Instruct
- To Run Inference with Llama3-70B-Instruct, please ensure that your HuggingFace token has access to the model. You can apply for access from https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct.
- Download the llama3-70b.zip from GitHub and unzip it under the `/root/models` directory.  You can use `wget` command to download and `unzip` command to unzip.
- Once unzipped, ensure to remove the original zip file from the `/root/models` directory.
- Run `cat /root/models/llama3-70b/1/model.json` and take a look at the vllm backend configuration options:
    - It uses the model meta-llama/Meta-Llama-3-70B-Instruct
    - The gpu_memory_utilization is set to 85% of the GPU Memory. You can actually tune this to a lower number if you wish. However, note that Llama3-70B requires a significant amount of memory to run (160+GB), tuning it downwards might give you an Cache error. 
    - The tensor_parallel_size is set to 4, which is the number of GPU on this machine. If you are running a 8 GPU machine, the number should be set to 8.
    - There are many other configuration options you can explore in https://github.com/vllm-project/vllm/blob/main/vllm/engine/arg_utils.py. Please consult the code for more details.
- Run `cat /root/models/llama3-70b/config.pbtxt` and take a look at the Triton server configuration options:
    - The instance_group is only set during Multi-GPU mode. If you are running on single GPU, please remove that block.
    - The backend here is vllm.
    - Refer to triton model configuration docs https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/user_guide/model_configuration.html for more details for the different options.
- Run `triton start`. The starting process can take 10-15 minutes depending on the model size.
- If the triton server starts successfully, You should see something similar to the following lines at the end:
```
#I0603 11:11:10.717657 779 grpc_server.cc:2463] "Started GRPCInferenceService at 0.0.0.0:8001"
#I0603 11:11:10.717897 779 http_server.cc:4692] "Started HTTPService at 0.0.0.0:8000"
#I0603 11:11:10.782444 779 http_server.cc:362] "Started Metrics Service at 0.0.0.0:8002"
```

## Inferencing and Profiling the Llama3-70B-Instruct
- Open a separate session tab, and ssh into the machine.
- Run `docker exec -it $(docker ps -q) sh` to shell into the container.
- Run `triton infer -m llama3-70b --prompt "machine learning is"` to view the inference results. You should see text_output "machine learning is a complex....."
- Run `genai-perf -m llama3-70b --num-of-output-prompts 10 --random-seed 123 --input-tokens-mean 128 --expected-output-tokens 128  --concurrency 1 -u localhost:8001` for a profile.
- The options for GenAI-Perf profiling are described in https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/client/src/c%2B%2B/perf_analyzer/genai-perf/README.html. Note that, the first profile result may not be accurate. Run the 
same profiling commands for a few times just to make sure you get a consistent result before recording the values.

## Run Triton Inference Server with Mixtral-8x7B-4bit-Quantized
- The quantized 4-bit model we are running today is https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GPTQ
- First, stop the previous triton session by running `Ctrl + C`
- Run `triton remove -m all` to remove the existing models in the model directory
- Download the Mixtral-8x7B-4bit.zip from GitHub and unzip it under the `/root/models` directory.  You can use `wget` command to download and `unzip` command to unzip.
- Once unzipped, ensure to remove the original zip file from the `/root/models` directory.
- Run `cat /root/models/Mixtral-8x7B-4bit/1/model.json` and take a look at the vllm backend configuration options:
    - It uses the model TheBloke/Mixtral-8x7B-Instruct-v0.1-GPTQ
    - The gpu_memory_utilization is set to 85% of the GPU Memory. You can actually tune this to a lower number but can run into cache errors if the number is too low.
    - The tensor_parallel_size is set to 4, which is the number of GPU on this machine. If you are running a 8 GPU machine, the number should be set to 8.
    - The dtype is set to float16, which is a requirement to run this 4-bit quantized model.
    - There are many other configuration options you can explore in https://github.com/vllm-project/vllm/blob/main/vllm/engine/arg_utils.py. Please consult the code for more details.
- Run `triton start`. The starting process can take 10-15 minutes depending on the model size.
- If the triton server starts successfully, You should see something similar to the following lines at the end:
```
#I0603 11:11:10.717657 779 grpc_server.cc:2463] "Started GRPCInferenceService at 0.0.0.0:8001"
#I0603 11:11:10.717897 779 http_server.cc:4692] "Started HTTPService at 0.0.0.0:8000"
#I0603 11:11:10.782444 779 http_server.cc:362] "Started Metrics Service at 0.0.0.0:8002"
```

## Inferencing and Profiling the Mixtral-8x7B-4bit-Quantized
- Open a separate session tab, and ssh into the machine.
- Run `docker exec -it $(docker ps -q) sh` to shell into the container.
- Run `triton infer -m Mixtral-8x7B-4bit --prompt "machine learning is"` to view the inference results. You should see text_output "machine learning is a complex....."
- Run `genai-perf -m Mixtral-8x7B-4bit --num-of-output-prompts 10 --random-seed 123 --input-tokens-mean 128 --expected-output-tokens 128  --concurrency 1 -u localhost:8001` for a profile.
- The options for GenAI-Perf profiling are described in https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/client/src/c%2B%2B/perf_analyzer/genai-perf/README.html. Note that, the first profile result may not be accurate. Run the 
same profiling commands for a few times just to make sure you get a consistent result before recording the values.


## Inferencing with Batch Size
- The default maximum batch size is [256 in vllm] (https://github.com/vllm-project/vllm/issues/1576).
- To adjust the default max batch size, edit `/root/models/Mixtral-8x7B-4bit/1/model.json` inside the docker container, and add `"max_num_seqs": 900`, where 900 is the maximum batch size now.
- The Triton CLI can be used to profile interencing with batch size. For example `triton -v profile -m llama3-70b --input-length 2048  --output-length 2048 --backend vllm -b 16` testes Batch size 16 with Input length and Output length of 2048.


## Delete everything
- Go to your home directory (e.g. cd /home/<username>)
- `cd A6000x4`
- `terraform destroy`

## Disclaimer
- This tutorial is stricitly used for demo purposes only. For production environments, further refinements are required and please refer to the official documentation of Trition, vllm, and each models for further reference.
- If you have discovered any issues or have any comments with this tutorial, please raise a Github Issue.
