
# <p width=600 align="center"><b>Building Ollama with Minikube</b></p>

<p align="center">
<img align="center" src="img\main.png-header-2.png" wodth=90%><br>
</p>

<p><b>Ollama</b> is an open-source platform designed for deploying and running large language models (LLMs) locally. It enables developers to integrate AI models into their applications while maintaining privacy, security, and high performance—without relying on external cloud services.</p>

<p>With Ollama, you can run various pre-trained models locally. These models can be downloaded from the Ollama library using simple commands after installing the platform. Once installed and the desired model is selected, integration into applications is possible through Ollama’s API. Additionally, Ollama offers a web-based chat interface for interactive use.
</p>



<p><b>Comparison: ChatGPT vs. Ollama</b>
To better understand Ollama, it’s useful to compare it with ChatGPT. ChatGPT is developed and operated by OpenAI as a proprietary, cloud-based service. It is not open-source and offers only limited customization through OpenAI’s fine-tuning tools. However, ChatGPT supports Retrieval-Augmented Generation (RAG) with minimal configuration, making it easy to integrate into RAG workflows via the OpenAI API.
</p>
<p>In contrast, Ollama is fully open-source and supports both local and cloud deployments. It runs on Windows, macOS, and Linux, making it accessible across major platforms. Developers can fine-tune models using techniques such as LoRA and QLoRA to create custom models tailored to specific tasks. Additionally, Ollama can be used with Retrieval-Augmented Generation (RAG) and a vector database to enhance retrieval capabilities and extend the language model’s knowledge base with external documents.</p>

<p><b>Building Ollama on Kubernetes (Minikube)</b>
In our project, we demonstrate how to deploy the Ollama platform using Kubernetes (Minikube), creating a container-based solution. This approach allows the system to scale vertically (scale-up) or horizontally (scale-out) based on workload demand. It also enables deploying separate Ollama containers for different teams or users, providing better isolation and flexibility. </p>


<p>Our architecture includes two pods:</P>

Ollama Application Pod – responsible for running the core model services.

GUI Pod – providing the user interface for chatting.

The diagram below illustrates how Ollama runs in containers orchestrated by Kubernetes. It shows two pods  ollama and ollama-llm-ui along with three services and a distributed storage setup using Persistent Volumes (PV) and Persistent Volume Claims (PVC).

<p align="center">
<img align="center" src="img\ollama-diagram.jpg" wodth=90%><br>
Omllama components with container base
</p>

We created two custom Docker images from scratch—one for each pod—and pushed them to Docker Hub. These images are then used to deploy the corresponding pods and services on Kubernetes.

In this post, we will focuses on building the Ollama platform within Kubernetes. We do not cover Kubernetes basics or command-line instructions here. </p>

#### Why building Ollama on Kubernentes
Instead of running Ollama on a single virtual machine or physical server shared by multiple users, deploying it on Kubernetes provides greater flexibility, scalability, and isolation. With Kubernetes, we can distribute Ollama containers across multiple nodes (servers), allowing each user to access a dedicated pod or instance. This setup improves performance isolation, ensuring one user's workload doesn't impact another's.

Kubernetes also enables horizontal and vertical scaling. If more resources are needed, we can scale out by adding more pods or scale up by increasing resources for existing pods. Conversely, during low usage, we can scale down to conserve resources. This dynamic resource management helps maintain consistent application. See the diagram below explain how Ollama runs on different nodes with different Ollama pods.

The diagram below illustrates how Ollama with Kubernentes can run on separate nodes (servers), allowing us to assign a dedicated instance of the Ollama application to each user or department. This setup ensures isolation and prevents resource conflicts, such as memory, CPU, or I/O limitations, by avoiding shared usage on a single server.

<p align="center">
<img align="center" src="img\kubernetes-ollama.jpg" wodth=90%><br>
Run Ollama with Kubernetes on different nodes (servers)
</p>

#### Build Ollama with Docker 
We need to the two images from scratch
  * Build Ollama platform image
  * File: <a href="ollama/Dockerfile">ollama/Dockerfile</a>
  * Image in Docker hub: <a href="https://hub.docker.com/repository/docker/alaasalmo/ollama/general">https://hub.docker.com/repository/docker/alaasalmo/ollama/general</a>

  <b>Commands to build the image:</b>
```	 
   cd ollama
   docker build -t ollama:1.0.0.0 .
   docker images
   docker tag <image-id> alaasalmo/ollama:1.0.0.0
   docker tag c82623967cae alaasalmo/ollama:1.0.0.0
   docker push alaasalmo/ollama:1.0.0.0
```

  * Build Ollama UI image
  * File: <a href="ollama-llm-ui/Dockerfile">ollama-llm-ui/Dockerfile</a>
  * Image in Docker hub: <a href="https://hub.docker.com/repository/docker/alaasalmo/ollama-ui/general">https://hub.docker.com/repository/docker/alaasalmo/ollama-ui/general</a>


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
  * Build and run images with Docker to check the images(if you don't want to check the images, you can pass this part)
     
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
We need to start the minikube with:
```
minikube start --memory 9216 --cpus 4
```
We start the minikube with 9 Giga byte memory and 4 CPUs (this will depened on the hosting capacitiy)
##### Build PV and PVC storage
<a href="storage/pv.yaml">storage/pv.yaml</a>
<a href="storage/pvc.yaml">storage/pvc.yaml</a>

Build the folder for PV in minikube
```
minikube ssh
sudo midir -p /mnt/data
sudo chmod 777 -R /mnt/data/ollama
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

Get the services with NodePort

```
kubectl get services | grep NodePort
```

After you see the services. You can start the external service for GUI 
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

* <b>Upload differenct models and check Ollama UI</b>
  We will upload the models to the Ollama pod:
  ```
  kubectl exec -it $(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}') -- ollama pull llama3
  kubectl exec -it $(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}') -- ollama pull llama3.2:1b
  ```
  To check the model list, we run:
  ```
  kubectl exec -it $(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}') -- ollama list
  ```   
 
  We will upload the models to the Ollama pod in air gapped system(off line system):
   
  ```
   kubectl exec -it $(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}') bash
   cd ~/.ollama
   tar czf ollama-models.tar.gz models modelfile-store.json
   kubectl cp $(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}'):/root/.ollama/ollama-models.tar.gz ollama-models.tar.gz
   ```

   After you get the copy of models (compressed file) to the /root/.ollama/ and tar (uncompress file):
   ```
   kubectl cp ollama-models.tar.gz $(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}'):/root/.ollama/ollama-models.tar.gz
   kubectl exec -it $(kubectl get pods -l app=ollama -o jsonpath='{.items[0].metadata.name}') bash
   cd ~/.ollama
   tar xzf ollama-models.tar.gz
   ollama list
  ```
   After you run the curl command, you will see the list of models
  ```
   curl http://127.0.0.1:58850/api/tags
  ```

* <b>Build API python code to access Ollama platform </b>

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
