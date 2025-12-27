FROM dbeaver/cloudbeaver:25.3.1

# Copy the custom start script
COPY start-server.sh /opt/cloudbeaver/start-server.sh

# Make the script executable
RUN chmod +x /opt/cloudbeaver/start-server.sh

# Use the custom start script as entrypoint
ENTRYPOINT ["/opt/cloudbeaver/start-server.sh"]
