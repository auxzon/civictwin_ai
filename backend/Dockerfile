# Use the official minimal Python 3.12 image
FROM python:3.12-slim

# Prevent Python from writing .pyc files to disc and enable stdout/stderr buffering
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080

# Set working directory inside the container
WORKDIR /app

# Copy requirements file first to leverage Docker caching
COPY requirements.txt /app/

# Install dependencies without local pip caching to minimize image layers
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code into the image (excluding patterns in .dockerignore)
COPY . /app/

# Expose the port (Cloud Run defaults to 8080, but can be overridden)
EXPOSE 8080

# Run uvicorn server, resolving the PORT variable dynamically at runtime
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
