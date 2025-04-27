FROM mcr.microsoft.com/azure-functions/python:4-python3.11
# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/python:4-python3.11-appservice

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true


# Install unzip, Chrome and apt-utils
ARG CHROME_VERSION="google-chrome-stable"
RUN apt-get update && apt-get install -y apt-utils zip unzip wget gnupg2 \
  && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install ${CHROME_VERSION:-google-chrome-stable} \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install Python dependencies
COPY requirements.txt /
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /requirements.txt

COPY . /home/site/wwwroot