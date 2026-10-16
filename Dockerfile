FROM python:3.13-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

# Explicit root makes Hadolint DL3002 reproducible; missing USER alone is not flagged.
USER root
EXPOSE 5000
CMD ["python", "app.py"]
