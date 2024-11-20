# Use a slim Python 3.10 runtime as the base image
FROM python:3.10-slim

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the current directory's contents into the container
COPY . .

# Install dependencies listed in requirements.txt, disabling caching
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 5000 to make the application accessible from outside the container
EXPOSE 5000

# Set environment variables for Flask
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

# Run the Flask application when the container starts
CMD ["flask", "run"]
