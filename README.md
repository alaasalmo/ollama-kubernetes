# <p width=600 align="center"><b>Building Ollama with Minikube</b></p>

<p align="center">
<img align="center" src="img\main-header.jpg" wodth=90%><br>
</p>

<p><b>Ollama</b> is an open-source platform designed for deploying and running large language models (LLMs) locally. It enables developers to integrate AI models into their applications while maintaining privacy, security, and high performance—without relying on external cloud services.</p>

<p>With Ollama, you can run various pre-trained models locally. These models can be downloaded from the Ollama library using simple commands after installing the platform. Once installed and the desired model is selected, integration into applications is possible through Ollama’s API. Additionally, Ollama offers a web-based chat interface for interactive use.
</p>



<p><b>Comparison: ChatGPT vs. Ollama</b>
In this post, we compare ChatGPT—OpenAI’s well-known cloud-based platform—with Ollama. ChatGPT is a proprietary service that runs exclusively in the cloud. It allows limited customization of its models through OpenAI's fine-tuning tools and is not open source.
</p>
<p>In contrast, Ollama is fully open source and supports both local and cloud deployments. It runs on Windows, macOS, and Linux. Developers can use and fine-tune models using techniques such as LoRA and QLoRA to create custom models tailored to specific tasks.</p>

<p><b>Building Ollama on Kubernetes (Minikube)</b>
In our project, we demonstrate how to deploy the Ollama platform using Kubernetes (Minikube), creating a container-based solution. This approach allows the system to scale vertically (scale-up) or horizontally (scale-out) based on workload demand. It also enables deploying separate Ollama containers for different teams or users, providing better isolation and flexibility. </p>


<p>Our architecture includes two pods:</P>

Ollama Application Pod – responsible for running the core model services.

GUI Pod – providing the user interface for chatting.

<p align="center">
<img align="center" src="img\ollama-diagram.jpg" wodth=90%><br>
</p>

We created two custom Docker images from scratch—one for each pod—and pushed them to Docker Hub. These images are then used to deploy the corresponding pods and services on Kubernetes.

In this post, we will focuses on building the Ollama platform within Kubernetes. We do not cover Kubernetes basics or command-line instructions here. </p>

#### Why building Ollama on Kubernentes
Instead of running Ollama on a single virtual machine or physical server shared by multiple users, deploying it on Kubernetes provides greater flexibility, scalability, and isolation. With Kubernetes, we can distribute Ollama containers across multiple nodes (servers), allowing each user to access a dedicated pod or instance. This setup improves performance isolation, ensuring one user's workload doesn't impact another's.

Kubernetes also enables horizontal and vertical scaling. If more resources are needed, we can scale out by adding more pods or scale up by increasing resources for existing pods. Conversely, during low usage, we can scale down to conserve resources. This dynamic resource management helps maintain consistent application. See the diagram below explain how Ollama runs on different nodes with different Ollama pods

<p align="center">
<img align="center" src="img\kubernetes-ollama.jpg" wodth=90%><br>
</p>

#### Build Ollama with Docker 
We need to the two images from scratch
  * Build Ollama platform image
  File: ollama/Dockerfile
  <b>Commands:</b>
```	 
     cd ollama
	 docker build -t ollama:1.0.0.0 .
     docker images
     docker tag <image-id> alaasalmo/ollama:1.0.0.0
	 docker tag c82623967cae alaasalmo/ollama:1.0.0.0
     docker push alaasalmo/ollama:1.0.0.0
```
  * Build Ollama UI image
```
git clone https://github.com/jakobhoeg/nextjs-ollama-llm-ui.git
mv nextjs-ollama-llm-ui ollama-llm-ui
cd ollama-llm-ui
```  
```   
     cd ollama-llm-ui
	 docker build -t ollama-ui .
     docker images
     docker tag <image-id> alaasalmo/ollama-ui:1.0.0.0
     docker tag c82623967cae alaasalmo/ollama-ui:1.0.0.0
     docker push alaasalmo/ollama-ui:1.0.0.0
```     
  * Build and run images with Docker to check the images(if you don't want to check the images, you can pass this part):
     
##### Run the docker images

```
    docker network create --driver bridge llm-net 	
	
    docker run -d -p 8080:3000 \
    --network llm-net \
    --add-host=host.docker.internal:host-gateway \
    -e OLLAMA_URL=http://ollama:11434 \
    --name nextjs-ollama \
    nextjs-ollama-ui

    mkdir ~/.ollama 
    docker run -d --name ollama --network llm-net -v ~/.ollama:/root/.ollama -p 11434:11434 ollama/ollama 
```

##### Check the docker run

```
In the web browser use http://localhost:8080, you have to see the Ollama page
```

#### Build Ollama with Minikube
We need to the minikube with:
```
minikube start --memory 9216 --cpus 5
```

##### Build PV and PVC storage
<a href="storage/pv.yaml">storage/pv.yaml</a>
<a href="storage/pvc.yaml">storage/pvc.yaml</a>

Build the share the folder for PV
```
minikube ssh
sudo mkdir /mnt
sudo midor /mnt/data
sudo chmod 777 -R /mnt/data
exit
```

```
kubectl apply -f storage/pv.yaml
kubectl apply -f storage/pvc.yaml
```
##### Build Ollama Pod and services of Ollama platform
We will deploy Ollama pod and two services. First one 'ollama-service' is for extrnal use (access to Ollama pod from external than Kubernetes)" Second one 'ollama-service-internal' is for internal access (access to Ollama from different pods)
<a href="ollama/ollama-deployment.yaml">ollama/ollama-deployment.yaml</a>

```
kubctl apply -f ollama/ollama-deployment.yaml
```
##### Build Ollama UI pod(ollama-llm-ui) and service(ollama-llm-service)

<a href="ollama-llm-ui/ollama-llm-ui.yaml">ollama-llm-ui/ollama-llm-ui.yaml</a>

```
kubectl apply -f ollama-llm-ui/ollama-llm-ui.yaml
```
##### Run external services for Ollama GUI access

Get the services with No

```
kubectl get services | grep NodePort
```

Start the external service for GUI 
```
minikube service ollama-llm-ui --url
```
Start the external service for API
```
minikube service ollama-service --url
```

###### Check the GUI & Python code

* <b>GUI</b>

Get the out put from running "minikube service ollama-llm-ui --url"

```
http://127.0.0.1:53584
```

<p align="center">
<img align="center" src="img\main-page.png" wodth=90%><br>
</p>

* <b>Python</b>

Get the URL from command : "minikube service ollama-service --url"

```
import requests

# Ollama endpoint
OLLAMA_URL = "http://127.0.0.1:54306"

# The model you want to use
MODEL_NAME = "llama3.2:1b"

# Prompt to send
prompt = "What is the capital of Canada?"

# Request payload
data = {
    "model": MODEL_NAME,
    "prompt": prompt,
    "stream": False
}

# Make POST request to Ollama's generate endpoint
response = requests.post(f"{OLLAMA_URL}/api/generate", json=data)

# Print the result
if response.status_code == 200:
    result = response.json()
    print("🧠 Model response:\n", result["response"])
else:
    print(f"❌ Error {response.status_code}: {response.text}")
```
