FROM fedora:latest

# Install required tools
RUN dnf install -y curl ca-certificates tar gzip shadow-utils && \
    dnf clean all

# Create non-root user (optional, can run as root)
RUN useradd -m ollama

# Switch to working directory
WORKDIR /home/ollama

# Install ping (iputils package)
RUN dnf install -y iputils && dnf clean all
RUN dnf install -y hostname && dnf clean all

# Install netcat (nc)
RUN dnf install -y nmap-ncat && dnf clean all

RUN dnf install -y net-tools
# Optional: clean up to reduce image size
RUN dnf clean all


# Download and install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Expose default port
EXPOSE 11434

# Volume for model storage
VOLUME ["/root/.ollama"]

# Command to start server
CMD ["ollama", "serve"]
