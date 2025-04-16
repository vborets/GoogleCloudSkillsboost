FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY chef.py .

CMD ["streamlit", "run", "chef.py", "--server.port=8080", "--server.enableCORS=false", "--server.enableXsrfProtection=false"]
