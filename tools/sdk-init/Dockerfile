# Dockerfile for test
FROM python:3.11-slim

# Install necessary dependencies for the example Python app
RUN pip install flask

# Set the working directory
WORKDIR /app

# Copy the binary from the builder stage
COPY ./bin/sdk-init /usr/local/bin/sdk-init

# Add the example Python app
COPY ./example-app/app.py /app
COPY ./example-app/protos /protos

# Expose the Flask application port
EXPOSE 5000

# Entrypoint runs the main binary first
ENTRYPOINT ["sdk-init"]

# CMD runs the Flask application
CMD ["python", "app.py"]
