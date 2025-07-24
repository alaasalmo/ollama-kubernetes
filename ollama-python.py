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
