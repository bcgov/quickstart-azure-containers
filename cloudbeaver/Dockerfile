FROM dbeaver/cloudbeaver:25.3.1

# Copy the custom start script
COPY start-server.sh /opt/cloudbeaver/start-server.sh

# Fix line endings and make the script executable
RUN sed -i 's/\r$//' /opt/cloudbeaver/start-server.sh && \
    chmod +x /opt/cloudbeaver/start-server.sh

# Use the custom start script as entrypoint
ENTRYPOINT ["/bin/sh", "/opt/cloudbeaver/start-server.sh"]
