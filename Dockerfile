# Use Python 3.7 as base image
FROM python:3.7-slim

# Install packages:
# 1. Build-Essential - contains a C compiler to build uWSGI. 
#                    - Not including this raises "Exception: you need a C compiler to build uWSGI"
#                    - Official documentation: https://uwsgi.readthedocs.io/en/latest/Install.html
#                    - Also useful: https://superuser.com/questions/151557/what-are-build-essential-build-dep
# 2. Nginx - web server, but we use it as a reverse proxy
# 3. Supervisord - monitors and controls processes on a machine, we use it to run nginx and uWSGI servers concurrently
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
            build-essential \
            nginx \
            supervisor

# Set working directory
WORKDIR /container

# Add backend directory to working directory
COPY backend /container/backend

# Grant root privileges to the container
USER root

# Install Python dependencies (which includes uWSGI)
RUN pip3 install -r /container/backend/requirements.txt

# Remove unnecessary files
RUN rm /etc/nginx/sites-enabled/default
RUN rm -r /root/.cache

# Copy deployment files from host fs into image fs
COPY deployment/nginx.conf /etc/nginx/
COPY deployment/backend.conf /etc/nginx/conf.d/
COPY deployment/uwsgi.ini /etc/uwsgi/
COPY deployment/supervisord.conf /etc/

# Expose port 80 to be forwarded
EXPOSE 80

# Command to ensure nginx and uWSGI processes run concurrently
CMD ["/usr/bin/supervisord"]
