FROM python:3.13-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip uninstall -y pip \
    && rm -rf /usr/local/lib/python3.13/ensurepip \
    && adduser --uid 10001 --disabled-password --gecos "" appuser
COPY app.py .
USER 10001:10001

EXPOSE 5000
CMD ["python", "app.py"]
